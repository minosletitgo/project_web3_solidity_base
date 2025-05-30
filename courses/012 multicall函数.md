#### 理解概念：
- ```Solidity``` 本身并没有提供一个叫做 ```multicall``` 的天然底层函数。
- ```multicall``` 是一种设计模式或概念，用于在一个交易中执行多个合约调用，并将所有这些调用的结果汇总。
- 通俗的讲，就是将多个函数调用的数据（包括函数选择器和参数编码）封装成一个交易，批量执行。
- 大多数情况下，多重调用的发起都是前端。

　

#### 优点：
- 方便性：MultiCall能让你在一次交易中对不同合约的不同函数进行调用，同时这些调用还可以使用不同的参数。比如你可以一次性查询多个地址的ERC20代币余额。
- 节省gas：MultiCall能将多个交易合并成一次交易中的多个调用，从而节省gas。
- 原子性：MultiCall能让用户在一笔交易中执行所有操作，保证所有操作要么全部成功，要么全部失败，这样就保持了原子性。比如，你可以按照特定的顺序进行一系列的代币交易。

　

##### 示例：
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Multicall {
    // Call结构体，包含目标合约target，是否允许调用失败allowFailure，和call data
    struct Call {
        address target;
        bool allowFailure;
        bytes callData;
    }

    // Result结构体，包含调用是否成功和return data
    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice 将多个调用（支持不同合约/不同方法/不同参数）合并到一次调用
    /// @param calls Call结构体组成的数组
    /// @return returnData Result结构体组成的数组
    function multicall(Call[] calldata calls) public returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        Call calldata calli;
        
        // 在循环中依次调用
        for (uint256 i = 0; i < length; i++) {
            Result memory result = returnData[i];
            calli = calls[i];
            (result.success, result.returnData) = calli.target.call(calli.callData);
            // 如果 calli.allowFailure 和 result.success 均为 false，则 revert
            if (!(calli.allowFailure || result.success)){
                revert("Multicall: call failed");
            }
        }
    }
}
```

　

#### calldata参数说明：
- 以下示例一下，一个名为```doSomething```的函数，它在有参数和无参数的情况下，如何计算出```calldata```

　

##### 在合约上计算：
```
    /////////////////////////////////////////////////////////////

    // 示例：无参函数
    function doSomething() public {}

    // 计算无参函数的函数选择器
    function encode_doSomething_With_Null() public pure returns (bytes memory) {
        bytes4 data = bytes4(keccak256("doSomething()"));
        bytes memory encodedData = abi.encodeWithSelector(data);
        return encodedData;
        // 返回值是：0x82692679
    }    

    /////////////////////////////////////////////////////////////

    // 示例：有参函数，为123
    function doSomething(uint256 value) public {}

    // 计算有参函数的函数选择器
    function encode_doSomething_With_123() public pure returns (bytes memory) {
        bytes4 data = bytes4(keccak256("doSomething(uint256)"));
        bytes memory encodedData = abi.encodeWithSelector(data, 123);
        return encodedData;
        // 返回值是：0xa6b206bf000000000000000000000000000000000000000000000000000000000000007b
    } 

    /////////////////////////////////////////////////////////////
```

　

##### 在前端计算：
```
  {
    // 示例：无参函数
    const contract = new ethers.utils.Interface(["function doSomething()"]);
    const selector = contract.getSighash("doSomething");
    const encodedData = contract.encodeFunctionData("doSomething", []);
    console.log("Encoded Data With Null:", encodedData);
    // 返回值是：0x82692679
  }

  {
    // 示例：有参函数，为123
    const contract = new ethers.utils.Interface(["function doSomething(uint256)"]);
    const selector = contract.getSighash("doSomething");
    const encodedData = contract.encodeFunctionData("doSomething", [123]);
    console.log("Encoded Data With 123:", encodedData);
    // 返回值是：0xa6b206bf000000000000000000000000000000000000000000000000000000000000007b
  }  
```
