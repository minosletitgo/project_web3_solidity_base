#### 概念：
- 在 Uniswap V2 中，价格预言机(Price Oracle)机制主要用于获取特定代币对的市场价格，这对于许多依赖准确价格信息的应用程序来说至关重要，比如借贷协议、保险协议等。
- Uniswap V2 并没有像某些其他协议那样直接集成传统意义上的预言机服务（例如 Chainlink）。
- 相反，它利用了自己独特的机制来提供价格信息，这个机制主要是通过累积价格数据来实现的。

　

#### 累积价格（Cumulative Prices）
- 以下是UniswapV2源码中，关于累积价格的逻辑。
- 在交易池中，每次更新代币储备量的时，会同时更新"代币的累积价格"。
- ```UniswapV2Pair.sol```
```
   // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }
```
//- 小插曲：为什么```UniswapV2Pair.sol```的代码中，_update函数没有修饰器限制(如，管理员层能)

　

#### 时间加权平均价格（TWAP）
- 时间加权平均价格（Time-Weighted Average Price, TWAP）是指在一定时间段内，根据时间对价格进行加权平均的结果。
- 这有助于消除短期价格波动的影响，为用户提供更加稳定的价格参考。

　

#### 示例
- 准备工作：提前部署```UniswapV2Factory```(或，在测试链上使用其他用户部署的工厂合约)，使用该工厂创建自己的代币对(交易对)
- 拿到此交易对后，我们就可以开始部署"自己的监控价格合约"。
```
contract OneHourOracle {
    using UQ112x112 for uint224; // requires importing UQ112x112

    IUniswapV2Pair uniswapV2pair;

    UQ112x112 snapshotPrice0Cumulative;
    uint32 lastSnapshotTime;

    function getTimeElapsed() internal view returns (uint32 t) {
        unchecked {
            t = uint32(block.timestamp % 2**32) - lastSnapshotTime;
        }
    }

    function snapshot() public returns (UQ112x112 twapPrice) {
        require(getTimeElapsed() >= 1 hours, "snapshot is not stale");

        // we don't use the reserves, just need the last timestamp update
        ( , , lastSnapshotTime) = uniswapV2pair.getReserves();
        snapshotPrice0Cumulative = uniswapV2pair.price0CumulativeLast;
    }

    function getOneHourPrice() public view returns (UQ112x112 price) {
        require(getTimeElapsed() >= 1 hours, "snapshot not old enough");
        require(getTimeElapsed() < 3 hours, "price is too stale");

        uint256 recentPriceCumul = uniswapV2pair.price0CumulativeLast;

        unchecked {
            twapPrice = (recentPriceCumul - snapshotPrice0Cumulative) / timeElapsed;
        }
    }
}
```
- ```OneHourOracle```该合约，简称为"每小时的价格预言机"，当然，偷懒了"只是获取了目标交易对的其中之一的累计价格"。