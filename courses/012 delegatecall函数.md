
#### ```delegatecall()```函数说明：
- address类型的低级成员函数，它用来与其他合约交互。
- 返回值为```(bool, bytes memory)```，分别对应delegatecall是否成功以及目标函数的返回值的字节码。
- 委托执行到目标合约的时候，上下文(Context，可以理解为包含变量和状态的环境)停留在当前合约。
- !!!注意：delegatecall有安全隐患，使用时要保证当前合约和目标合约的状态变量存储结构相同，并且目标合约安全，不然会造成资产损失。
- 适用：代理合约、钻石合约标准

#### ```delegatecall()```函数的使用规则：
- ```目标合约地址.delegatecall(字节码)```
- ```delegatecall``` 只会传递函数调用的参数和数据，而不会涉及 ETH 的传递，以及gas费用。
- 字节码：```abi.encodeWithSignature("函数签名", 逗号分隔的具体参数)```

##### 范例(contracts/TestDelegatecall.sol)：
```
    // 通过call来调用Logic的setVars()函数，将改变合约Logic里的状态变量(Logic中 num = 此处的_num，sender = Proxy的地址)
    function callSetVars(uint256 _num) external payable {
        // call setVars()
        (bool success, ) = addrLogic.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        require(success, "callSetVars failed");
    }

    // 通过delegatecall来调用Logic的setVars()函数，将改变合约Proxy里的状态变量(Logic中 num = 此处的_num，sender = addrAccount)
    function delegatecallSetVars(uint256 _num) external payable {
        // delegatecall setVars()
        (bool success, ) = addrLogic.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        require(success, "delegatecall failed");
    }
```    
