
#### CREATE2操作码的适用场景：
- 可预测性：当你需要知道一个合约将要部署到哪个具体地址时，比如在工厂模式中预先分配地址给子合约。
- 确定性：对于一些需要根据输入参数生成不同实例的应用，如 NFT 或者去中心化交易所中的订单合约，使用 CREATE2 可以确保每次生成的地址是确定性的。
- 避免冲突：当多个合约或用户试图部署具有相同初始化代码的合约时，可以使用不同的 salt 来避免地址冲突。

#### CREATE2操作码的优点：
- 确定性：使用 CREATE2 创建的合约地址是可预测的，这对于某些应用场景来说非常重要，例如在合约之间建立信任关系时。
- 减少风险：由于地址是已知的，可以提前设置好权限控制或者进行安全审计，降低了部署后发现地址错误的风险。
- 节省Gas：相较于 CREATE 操作码，CREATE2 在某些情况下可能更加高效，因为它减少了查找未使用的地址所需的工作量。

#### CREATE操作码的缺点：
- 复杂性增加：使用 CREATE2 需要在智能合约中实现额外的逻辑来处理 salt 和初始化代码，这可能会增加开发复杂度。
- 潜在的安全问题：如果 salt 被泄露或者生成算法被预测，恶意方可能抢先部署合约到预期地址，导致安全风险。因此，salt 值的选择和保护非常重要。
- 部署灵活性降低：一旦指定了 salt 和初始化代码，就无法轻易改变部署位置，这可能会限制某些动态部署场景的灵活性。



------------------------------------------------------------------------------------------------------------



#### 使用new操作符来部署新的合约实例时，即触发EVM中的CREATE2操作码。
```
    Contract x = new Contract{salt: _salt, value: _value}(params)
    
    function deployHello2_New(string memory _greeting) public returns (address) {
        address addr;
        bytes32 salt = keccak256(abi.encodePacked(uint256(123)));
        Hello2 hello = new Hello2{salt: salt, value: msg.value}(_greeting);        
        addr = address(hello);
        emit ContractDeployed("deployHello2_New", addr);
        return addr;
    }
```

#### 使用底层```assembly + CREATE2```操作码 来部署合约
```
    function deployAddress(bytes32 salt) public returns (address, address) {
        address addr;
        bytes memory bytecode = type(ArgsZero).creationCode;
        // 合约构造函数，参数为空
        bytes memory payload = abi.encodePacked(bytecode);
        assembly {
            addr := create2(0, add(payload, 0x20), mload(payload), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Print_deployAddress(address(this), addr);
        return (address(this), addr);
    }
    
    function deployAddress(bytes32 salt, uint256 value1) public returns (uint256, address, address) {
        address addr;
        bytes memory bytecode = type(ArgsOne).creationCode;
        // 合约构造函数，参数为 1 个
        bytes memory payload = abi.encodePacked(bytecode, abi.encode(value1));
        assembly {
            addr := create2(0, add(payload, 0x20), mload(payload), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Print_deployAddress(value1, address(this), addr);
        return (value1, address(this), addr);
    }
    
    function deployAddress(bytes32 salt, uint256 value1, string memory value2) public returns (address, address) {
        address addr;
        bytes memory bytecode = type(ArgsTwo).creationCode;
        // 合约构造函数，参数为 2 个
        bytes memory payload = abi.encodePacked(bytecode, abi.encode(value1, value2));
        assembly {
            addr := create2(0, add(payload, 0x20), mload(payload), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Print_deployAddress(address(this), addr);
        return (address(this), addr);
    }
```

#### 预测使用```CREATE2```操作码部署的合约地址
```
    function getComputedAddress(bytes32 salt) public returns (address, address) {
        bytes memory bytecode = type(ArgsZero).creationCode;
        // 合约构造函数，参数为空
        bytes memory payload = abi.encodePacked(bytecode);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(payload))
        );

        address addr = address(uint160(uint256(hash)));
        emit Print_getComputeAddress(address(this), addr);
        return (address(this), addr);
    }
    
    function getComputedAddress(bytes32 salt, uint256 value1) public returns (uint256, address, address) {
        bytes memory bytecode = type(ArgsOne).creationCode;
        // 合约构造函数，参数为 1 个
        bytes memory payload = abi.encodePacked(bytecode, abi.encode(value1));
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(payload))
        );

        address addr = address(uint160(uint256(hash)));
        emit Print_getComputeAddress(value1, address(this), addr);
        return (value1, address(this), addr);
    }    
    
    function getComputedAddress(bytes32 salt, uint256 value1, string memory value2) public returns (address, address) {
        bytes memory bytecode = type(ArgsOne).creationCode;
        // 合约构造函数，参数为 2 个
        bytes memory payload = abi.encodePacked(bytecode, abi.encode(value1, value2));
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(payload))
        );

        address addr = address(uint160(uint256(hash)));
        emit Print_getComputeAddress(address(this), addr);
        return (address(this), addr);
    }    
```



------------------------------------------------------------------------------------------------------------



#### 设置 Salt 的基本原则
- 唯一性：每个合约应该有一个唯一的 salt 值，这样可以保证即使使用相同的初始化代码也不会产生地址冲突。
- 不可预测性：salt 值应当难以被第三方猜测到，以防止恶意方抢先部署合约。
- 可重复性：对于需要多次部署相同类型合约的情况，应能够通过相同的 salt 值和初始化代码得到相同的合约地址。

#### 设置 Salt 的方式列举：
- 随机数：最常见的方法是使用随机数作为 salt 值。这可以通过区块链提供的随机数生成器，或者是合约内部实现的伪随机数生成器来实现。
    ```bytes32 salt = keccak256(abi.encodePacked(blockhash(block.number - 1), someData));```
- 合约参数：使用合约的一些参数作为 salt 的一部分，比如合约的所有者地址、合约的某些配置参数等。    
    ```bytes32 salt = keccak256(abi.encodePacked(owner, someConfigParameter));```
- 递增计数器：对于需要批量部署类似合约的场景，可以使用一个简单的递增计数器作为 salt 值的一部分，确保每次部署的合约都有不同的地址。    
    ```bytes32 salt = keccak256(abi.encodePacked(counter++));```
- 哈希组合：将上述方法组合起来，形成更复杂的 salt 值。例如，使用随机数加上合约参数，再结合递增计数器来生成 salt 值。
    ```bytes32 salt = keccak256(abi.encodePacked(blockhash(block.number - 1), owner, counter++));```

#### 在不部署合约的情况下，预测合约的地址:(详见：TestCreate2.sol)
- 公式：```address = keccak256(0xFF ++ creator_address ++ salt ++ keccak256(init_code))```
- 0xff：常量字节
- creator_address：部署者的地址(这个地址有可能指向的是一个合约，如工厂合约)
- salt：私有算法支持的盐值

#### 其他
- 一般情况下，使用```CREATE2```操作码部署合约，与预测合约地址，都需要在同一个上层合约中（如，Uniswap的工厂合约）
- 在```Foundry```的```script```模拟环境，可能无法完全预测一致的地址，因为不是标准的链上合约。
- 用例```project_web3_solidity_base\contracts\Create2```
- 如果，部署者的环境数据都相同，重复使用相同参数，进行```CREATE```部署合约会失败，因为合约已存在。

#### ```Openzepplin```的实现
```
    https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/proxy/Clones.sol
    
    function cloneDeterministic(
        address implementation,
        bytes32 salt,
        uint256 value
    ) internal returns (address instance) {
        if (address(this).balance < value) {
            revert Errors.InsufficientBalance(address(this).balance, value);
        }
        assembly ("memory-safe") {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(value, 0x09, 0x37, salt)
        }
        if (instance == address(0)) {
            revert Errors.FailedDeployment();
        }
    }
```


