
#### ```call()```函数说明：
- address类型的低级成员函数，它用来与其他合约交互。
- 返回值为(bool, bytes memory)，分别对应call是否成功以及目标函数的返回值的字节码。
- 官方推荐：通过触发fallback或receive函数发送ETH的方法。
- 官方不推荐：使用call函数调用其他合约的函数，恶意的合约会持有主动权，进而潜在一些攻击风险。


#### ```call()```函数的使用规则：
- 目标合约地址.call(字节码);
- 目标合约地址.call{value:发送数额, gas:gas数额}(字节码);
- 字节码：abi.encodeWithSignature("函数签名", 逗号分隔的具体参数)
- 调用的目标函数，它的可见性必须为 public或external


##### 范例：
```
function callSetX(address payable _addr, uint256 x) public payable {
    // call setX()，同时可以发送ETH
    (bool success, bytes memory data) = _addr.call{value: msg.value}(
        abi.encodeWithSignature("setX(uint256)", x)
    );
}

function callSetX(address payable _addr, uint256 x) public payable {
    // call setX()，同时不发送ETH
    (bool success, bytes memory data) = _addr.call(
        abi.encodeWithSignature("setX(uint256)", x)
    );
}

function callSetX(address payable _addr, uint256 x) public payable {
    // 单纯只发送ETH
    (bool success, bytes memory data) = _addr.call{value: msg.value}();
}
```