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
        Hello1 hello = new Hello1();        
        addr = address(hello);
        emit ContractDeployed("deployHello1_New", addr);
        return addr;
        //0xA8e982Fe7C1d8bAed33E0dCA73c2Ab4F2A3C9D1d
    }

    // 直接使用create来部署Hello1合约
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
    function deployHello2_New(string memory _greeting) public returns (address) {
        address addr;
        Hello2 hello = new Hello2(_greeting);        
        addr = address(hello);
        emit ContractDeployed("deployHello2_New", addr);
        return addr;
        //0xA8e982Fe7C1d8bAed33E0dCA73c2Ab4F2A3C9D1d
    }

    // 直接使用create来部署带构造函数参数的Hello2合约
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
}


