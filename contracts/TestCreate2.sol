// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hello1 {
    //没有构造函数参数
    string public greeting = "Hello, World!";

    function getGreeting() public view returns (string memory) {
        return greeting;
    }
}

contract Deploy1 {
    event ContractDeployed(string funcName, address addr);

    //直接使用new来部署Hello1合约
    function deployHello1_New() public returns (address) {
        address addr;
        bytes32 salt = keccak256(abi.encodePacked(uint256(123)));
        Hello1 hello = new Hello1{salt: salt}(); //salt从简处理
        addr = address(hello);
        emit ContractDeployed("deployHello1_New", addr);
        return addr;
        //0x524315C7A26afd4a53e5E459D96861C0453bCC2C
    }

    // 直接使用create来部署Hello1合约
    function deployHello1_Create() public returns (address) {
        address addr;
        bytes memory bytecode = type(Hello1).creationCode; // 获取 Hello1 的 creationCode
        bytes32 salt = keccak256(abi.encodePacked(uint256(123)));
        assembly {
            // 使用 create2 指令来部署合约
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Deployment failed");
        emit ContractDeployed("deployHello1_Create", addr);
        return addr;
        //0xb9254e278cf8431CB5fbd4BE03BD1135201bE725
    }

    //预测部署Hello1的地址
    function calculateHello1Addr() public view returns (address) {
        address addr;
        bytes memory bytecode = type(Hello1).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(uint256(123)));
        // 注意，此处的部署者就是Deploy1合约自己
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        addr = address(uint160(uint256(hash)));
        return addr;
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Hello2 {
    //有构造函数参数
    string public greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function getGreeting() public view returns (string memory) {
        return greeting;
    }
}

contract Deploy2 {
    event ContractDeployed(string funcName, address addr);

    //直接使用new来部署Hello2合约
    function deployHello2_New(string memory _greeting)
        public
        returns (address)
    {
        address addr;
        bytes32 salt = keccak256(abi.encodePacked(uint256(123)));
        Hello2 hello = new Hello2{salt: salt}(_greeting);
        addr = address(hello);
        emit ContractDeployed("deployHello2_New", addr);
        return addr;
        //0xA8e982Fe7C1d8bAed33E0dCA73c2Ab4F2A3C9D1d
    }

    // 直接使用create来部署带构造函数参数的Hello2合约
    function deployHello2_Create(string memory _greeting)
        public
        returns (address)
    {
        address addr;
        bytes memory bytecode = type(Hello2).creationCode; // 获取 Hello2 的 creationCode
        bytes memory constructorArgs = abi.encode(_greeting); // 将构造函数参数编码
        bytes memory deploymentData = abi.encodePacked(
            bytecode,
            constructorArgs
        ); // 拼接 bytecode 和参数
        bytes32 salt = keccak256(abi.encodePacked(uint256(123)));
        assembly {
            // 使用 create2 指令来部署合约
            addr := create2(0, add(deploymentData, 0x20), mload(deploymentData), salt)
        }
        require(addr != address(0), "Deployment failed");
        emit ContractDeployed("deployHello2_Create", addr);
        return addr;
    }

    //预测部署Hello2的地址
    function calculateHello2Addr(string memory _greeting) public view returns (address) {
        address addr;
        bytes memory bytecode = type(Hello2).creationCode; // 获取 Hello2 的 creationCode
        bytes memory constructorArgs = abi.encode(_greeting); // 将构造函数参数编码
        bytes memory deploymentData = abi.encodePacked(
            bytecode,
            constructorArgs
        ); 
        bytes32 salt = keccak256(abi.encodePacked(uint256(123)));
        // 注意，此处的部署者就是Deploy1合约自己
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(deploymentData)
            )
        );
        addr = address(uint160(uint256(hash)));
        return addr;
    }
}
