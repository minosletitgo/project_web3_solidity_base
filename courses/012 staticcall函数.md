### 理解
- ```staticcall``` 是一种低级别的调用方式，用于执行只读操作。
- 它类似于```call```，但有一个重要的限制：```staticcall```不允许修改合约状态。
- 这意味着目标函数最好是标记为 ```pure``` 或 ```view``` 的函数。
- 如果被调用的函数尝试修改状态（例如写入存储变量），交易将回滚。```Error: VM Exception while processing transaction: revert```

### 示例
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReadOnlyContract {
    uint256 public value;

    // 设置值的函数（会修改状态）
    function setValue(uint256 _value) external {
        value = _value;
    }

    // 获取值的函数（只读操作）
    function getValue() external view returns (uint256) {
        return value;
    }
}

contract StaticCallExample {
    // 使用 staticcall 调用外部合约的只读函数
    function getReadOnlyValue(address _contractAddress) external view returns (uint256) {
        // ABI 编码函数签名和参数
        bytes memory payload = abi.encodeWithSignature("getValue()");

        // 使用 staticcall 调用目标合约
        (bool success, bytes memory returnData) = _contractAddress.staticcall(payload);

        // 检查调用是否成功
        require(success, "Static call failed");

        // 解码返回值
        uint256 result = abi.decode(returnData, (uint256));
        return result;
    }
}
```
