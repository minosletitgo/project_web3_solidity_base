// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ABIDemo {
    event DoSomething(
        uint256 _value,
        address _addr,
        string _str,
        uint256[2] _array
    );

    // 一个假定的函数签名，用于示例
    function doSomething(
        uint256 _value,
        address _addr,
        string memory _str,
        uint256[2] memory _array
    ) public {
        emit DoSomething(_value, _addr, _str, _array);
    }

    // 使用 abi.encode 对参数进行编码
    function encodeExample() public pure returns (bytes memory) {
        uint256 value = 10;
        address addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
        string memory str = "0xAA";
        uint256[2] memory array = [(uint256)(5), (uint256)(6)];
        return abi.encode(value, addr, str, array);
    }

    // 使用 abi.encodePacked 对参数进行编码
    function encodePackedExample() public pure returns (bytes memory) {
        uint256 value = 10;
        address addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
        string memory str = "0xAA";
        uint256[2] memory array = [(uint256)(5), (uint256)(6)];
        return abi.encodePacked(value, addr, str, array);
    }

    // 使用 abi.encodeWithSignature 对参数进行编码
    function encodeWithSignatureExample() public pure returns (bytes memory) {
        uint256 value = 10;
        address addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
        string memory str = "0xAA";
        uint256[2] memory array = [(uint256)(5), (uint256)(6)];
        return
            abi.encodeWithSignature(
                "doSomething(uint256,address,string,uint256[2])",
                value,
                addr,
                str,
                array
            );
    }

    // 使用 abi.encodeWithSelector 对参数进行编码
    function encodeWithSelectorExample() public pure returns (bytes memory) {
        bytes4 selector = bytes4(
            keccak256("doSomething(uint256,address,string,uint256[2])")
        );
        uint256 value = 0;
        address addr = address(0);
        string memory str = "";
        uint256[2] memory array;
        return abi.encodeWithSelector(selector, value, addr, str, array);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////

contract CallABI {
    //address private addrTarget;
    ABIDemo private targetContract;

    event DoSomething(
        uint256 _value,
        address _addr,
        string _str,
        uint256[2] _array
    );    

    constructor(address adr) {
        //addrTarget = adr;
        targetContract = ABIDemo(adr);
    }

    // 使用 abi.decode 来反向解码
    function callDecodeToTargetContract(bytes memory data) public {
        uint256 value = 0;
        address addr = address(0);
        string memory str = "";
        uint256[2] memory array;
        (value, addr, str, array) = abi.decode(
            data,
            (uint256, address, string, uint256[2])
        );
        emit DoSomething(value, addr, str, array);
    }

    // 使用 abi.encodeWithSignature 调用目标合约的测试函数
    function callFunctionWithSignature() public {
        uint256 value = 0;
        address addr = address(0);
        string memory str = "CallABI.callFunctionWithSignature";
        uint256[2] memory array;

        // 编码调用
        bytes memory data = abi.encodeWithSignature(
            "doSomething(uint256,address,string,uint256[2])",
            value,
            addr,
            str,
            array
        );
        (bool success, ) = address(targetContract).call(data);
        require(success, "Call failed");
    }

    // 使用 abi.encodeWithSelector 调用目标合约的测试函数
    function callFunctionWithSelector() public {
        uint256 value = 0;
        address addr = address(0);
        string memory str = "CallABI.callFunctionWithSelector";
        uint256[2] memory array;
        // 编码调用
        bytes memory data = abi.encodeWithSelector(
            targetContract.doSomething.selector,
            value,
            addr,
            str,
            array
        );
        (bool success, ) = address(targetContract).call(data);
        require(success, "Call failed");
    }
}
