#### 概念：
- 闪电贷（Flash Loans）是Uniswap V2引入的一个创新功能，它允许用户在无需提供任何抵押品的情况下即时借入资金。
- 它的关键在于它利用了以太坊交易的原子性，即所有操作必须在一个区块内完成，否则整个交易会被回滚。

　

#### ```swap函数```
- 闪电贷的基本依赖，是UniswapV2(或，类似于的去中心化交易所)它所支持的```swap```机制。
- ```swap```允许用户直接调用它：在```swap```开始的时候，会真的把代币转给用户，在swap中间段回调让用户处理"贷款逻辑"，在swap末尾检查归还逻辑。

　

#### 示例：
- ```UniswapV2的swap源码```
```
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
```

　

- "想使用闪电贷，进行套利"的用户，它所持有的"闪电贷合约"。
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol";
import "https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC20/IERC20.sol";

contract FlashLoanArbitrage {
    address private factory;
    address private tokenA;         //有套利空间的代币A，与代币B组成的交易池
    address private tokenB;         
    address private newDexRouter;  // 新交易所的路由器地址
    uint256 private minProfitThreshold;  // 最小利润阈值

    constructor(address _factory, address _tokenA, address _tokenB, address _newDexRouter, uint256 _minProfitThreshold) {
        factory = _factory;
        tokenA = _tokenA;
        tokenB = _tokenB;
        newDexRouter = _newDexRouter;
        minProfitThreshold = _minProfitThreshold;
    }

    // 这个函数用于发起闪电贷请求
    function startArbitrage(uint256 amountA) external {
        IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(tokenA, tokenB));
        require(address(pair) != address(0), "Pair does not exist");

        // 借入tokenA
        pair.swap(amountA, 0, address(this), bytes("arbitrage"));
    }

    // 回调函数，由Uniswap V2 Pair合约调用
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        require(msg.sender == IUniswapV2Factory(factory).getPair(tokenA, tokenB), "Unauthorized");
        require(sender == address(this), "Unauthorized");

        if (keccak256(data) == keccak256("arbitrage")) {
            performArbitrage(amount0);
        }
    }

    // 执行套利操作
    function performArbitrage(uint256 borrowedAmount) internal {
        // 此时，套利合约，已经持有了"刚刚尝试借入的代币A"

        // 假设NewDEX的价格低于Uniswap V2
        swapTokens(tokenA, tokenB, borrowedAmount, newDexRouter);  // 在NewDEX卖出tokenA买入tokenB

        uint256 tokenBAmount = IERC20(tokenB).balanceOf(address(this));
        swapTokens(tokenB, tokenA, tokenBAmount, routerAddress);  // 在Uniswap V2卖出tokenB买入tokenA

        // 计算需要偿还的数量
        uint256 repayAmount = borrowedAmount + ((borrowedAmount * 3) / 1000); // 0.3%手续费

        // 检查是否有足够的tokenA来偿还贷款
        uint256 availableTokenA = IERC20(tokenA).balanceOf(address(this));
        require(availableTokenA >= repayAmount, "Insufficient funds to repay loan");

        // 计算利润
        uint256 profit = availableTokenA - repayAmount;
        require(profit >= minProfitThreshold, "Profit below threshold");

        // 偿还贷款
        IERC20(tokenA).transfer(msg.sender, repayAmount);

        // 如果还有剩余的tokenA，可以将其发送到合约所有者的地址
        uint256 remainingTokenA = availableTokenA - repayAmount;
        if (remainingTokenA > 0) {
            IERC20(tokenA).transfer(owner(), remainingTokenA);
        }
    }

    // 用于交换代币的辅助函数
    function swapTokens(address fromToken, address toToken, uint256 amount, address router) internal {
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;

        if (router == routerAddress) {
            IUniswapV2Router02(router).swapExactTokensForTokens(
                amount,
                0, // 接受任意数量的输出
                path,
                address(this),
                block.timestamp
            );
        } else if (router == newDexRouter) {
            INewDexRouter02(router).swapExactTokensForTokens(
                amount,
                0, // 接受任意数量的输出
                path,
                address(this),
                block.timestamp
            );
        }
    }

    // 假设有一个路由地址
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // 获取合约所有者的地址
    function owner() public view returns (address) {
        return msg.sender;
    }

    // 设置最小利润阈值
    function setMinProfitThreshold(uint256 _minProfitThreshold) external {
        require(msg.sender == owner(), "Unauthorized");
        minProfitThreshold = _minProfitThreshold;
    }
}
```