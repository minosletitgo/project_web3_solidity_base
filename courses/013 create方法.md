
#### 概述：
- 在以太坊虚拟机（EVM, Ethereum Virtual Machine）中，CREATE是一个操作码（opcode），用来创建新的智能合约账户（也称为合约账户）。
- CREATE操作码允许现有的合约（外部拥有账户EOA或者合约账户）通过发送一个交易来部署新的合约代码到区块链上。
- 通常情况下，不需要具备"预测地址"的合约，都是使用```CREATE```方式来部署。
- 从以太坊伊斯坦布尔硬分叉(2019年12月8日左右)开始，引入了```CREATE2```操作码，它允许更可预测地确定新合约地址，并且支持确定性的合约部署。
- ```CREATE2```相比于```CREATE```提供了额外的```salt```值，使得合约地址可以通过计算得出，而不依赖于交易的```nonce```。

　

#### ```CREATE``` 或 ```CREATE2``` 操作码的工作方式
- 交易提交：当一个包含合约字节码的交易被提交到网络时，它会被包含在一个区块内。
- 区块挖掘：当区块被挖出时，包含交易的调用栈会执行CREATE或```CREATE2```操作码。
- 条件检查：CREATE或```CREATE2```操作码会检查是否满足创建新合约的条件，比如是否有足够的gas来支付创建合约的成本。
- 创建合约账户：如果条件满足，EVM就会尝试创建一个新的合约账户，并且将提供的字节码写入该账户的状态存储中。
- 执行构造函数：创建过程中，如果合约构造函数执行成功，并且没有遇到错误（如超出gas限制），那么新合约就会被部署成功，并且返回新合约的地址。

　

#### 合约的部署字节码(或，原始字节码)：
- 合约部署时，合约代码的原始字节。
- 这个字节码是由 Solidity 编译器生成的，代表了合约的机器代码，能够被以太坊虚拟机（EVM）执行。
- 获取：```type(合约名).creationCode```
- 大部分时候字节码是固定的(少量影响因素：编译器版本变化、合约代码变化、编译器的优化设置变化)

　

-------------------------------------------------------------------------------------

　

#### CREATE操作码的适用场景：
- 标准合约部署，当你需要部署一个新合约，且不需要预测或控制合约地址时。
- 内部合约创建: 在合约中创建新的合约时，CREATE 可以方便地用于合约间的互动。

　

#### CREATE操作码的优点：
- 简单性: 直接创建合约，不需要额外的参数。
- 广泛兼容性: 在旧版本的以太坊和现有系统中广泛支持。

　

#### CREATE操作码的缺点：
- 地址不可预测: 由于地址依赖于交易的 nonce，因此无法在合约部署前预测合约地址。

　

-------------------------------------------------------------------------------------



#### 使用new操作符来部署新的合约实例时，即触发EVM中的CREATE操作码。
```
    Contract x = new Contract{value: _value}(params)
    
    function deployHello1_New() public returns (address) {
        address addr;
        Hello1 hello = new Hello1{value: msg.value}();        
        addr = address(hello);
        emit ContractDeployed("deployHello1_New", addr);
        return addr;
    }
```

#### 使用底层assembly + CREATE操作码 来部署合约，且目标合约没有构造函数参数。(详见：TestCreate.sol)
```
    function deployHello1_Create() public returns (address) {
        address addr;
        bytes memory bytecode = type(Hello1).creationCode; // 获取 Hello1 的 creationCode
        assembly {
            // 使用 create 指令来部署合约
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(addr != address(0), "Deployment failed");
        emit ContractDeployed("deployHello1_Create", addr);
        return addr;
    }
```

#### 使用底层assembly + CREATE操作码 来部署合约，且目标合约有构造函数参数。(详见：TestCreate.sol)
```
    function deployHello2_Create(string memory _greeting) public returns (address) {
        address addr;
        bytes memory bytecode = type(Hello2).creationCode; // 获取 Hello2 的 creationCode
        bytes memory constructorArgs = abi.encode(_greeting); // 将构造函数参数编码
        bytes memory deploymentData = abi.encodePacked(bytecode, constructorArgs); // 拼接 bytecode 和参数
        assembly {
            // 使用 create 指令来部署合约
            addr := create(0, add(deploymentData, 0x20), mload(deploymentData))
        }
        require(addr != address(0), "Deployment failed");
        emit ContractDeployed("deployHello2_Create", addr);
        return addr;
    }
```



-------------------------------------------------------------------------------------



#### 在不部署合约的情况下，预测合约的地址:
- 公式：```address = keccak256(0xFF ++ creator_address ++ _nonce ++ keccak256(init_code))```
- 0xff：常量字节
- creator_address：部署者的地址(这个地址有可能指向的是一个合约，如工厂合约)
- nonce：部署者的交易计数器(注意：每个地址的 nonce 值在发送交易时由网络维护，合约中是不能直接获取交易的 nonce)
- 在ethers.js中，```const nonce = await provider.getTransactionCount(address);```

```
    // 计算CREATE生成的合约地址
    function computeCreateAddress(address _creator, uint256 _nonce, bytes memory _bytecode) public pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                byte(0xff),
                _creator,
                _nonce,
                keccak256(_bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    // 计算目标合约的字节码(考虑有构造函数参数)
    function getExampleBytecode(uint256 _param1, string memory _param2) public pure returns (bytes memory) {
        // 先计算初始化字节码
        bytes memory bytecode = type(ExampleContract).creationCode;
        // 在字节码末尾追加构造函数参数的编码
        bytes memory constructorArgs = abi.encode(_param1, _param2);
        return abi.encodePacked(bytecode, constructorArgs);
    }
```    

#### 其他
- 通常情况下不认定```CREATE```操作码，具备预测地址的特性的(因为```nonce```值，即使在js中，也难以预测!)
- 面试题：在代码环境都不变的情况下，普通合约连续部署多次，合约地址都不相同。
- 回答：默认情况下。部署合约使用的是```CREATE```方式，```nonce```值势必在递增。（例外，```Hardhat 或 anvil 等```本地节点会重置数据，故重置后部署地址会相同。）

#### ```Openzepplin```的实现
```
    https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/proxy/Clones.sol
    
    function clone(address implementation, uint256 value) internal returns (address instance) {
        if (address(this).balance < value) {
            revert Errors.InsufficientBalance(address(this).balance, value);
        }
        assembly ("memory-safe") {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(value, 0x09, 0x37)
        }
        if (instance == address(0)) {
            revert Errors.FailedDeployment();
        }
    }
```
