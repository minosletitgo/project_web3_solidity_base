// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TargetContract {
    //0xF7c72F54eD6efbdF3fd076527E312E5652Aa148b
    event DoSetValue(uint256 value);
    event DoReceive();
    event DoFallback();

    uint256 public value;

    // 函数用于设置存储的值
    function setValue(uint256 _value) public payable {
        // 切记标记为payable，因为外界可能会指定以太币（否则，会call失败）
        value = _value;
        emit DoSetValue(_value);
    }

    // receive 函数，用于处理直接接收以太币
    receive() external payable {
        // 处理接收以太币
        emit DoReceive();
    }

    // fallback 函数，用于处理不匹配的调用
    fallback() external payable {
        // 处理未匹配的调用
        emit DoFallback();
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////

contract CallerContract {
    //0x085fA96a75F74a6CF8898Cc20Bf9bf030718a7b6
    address public targetContractAddress;

    constructor(address _address) payable {
        setTargetContractAddress(_address);
    }

    // 设置目标合约地址
    function setTargetContractAddress(address _address) public {
        require(_address != address(0));
        targetContractAddress = _address;
    }

    // 发送以太币（0或者大于0，都一样） + 指定函数签名为空 = 会触发receive
    function TryCallTarget_0() public payable {
        (bool success, ) = targetContractAddress.call{value: msg.value}("");
        require(success, "Call failed");
    }

    // 发送以太币（0或者大于0，都一样） + 指定已存在函数的签名 = 不会触发receive && 不会触发fallback
    function TryCallTarget_1(uint256 _value) public payable {
        bytes memory data = abi.encodeWithSignature(
            "setValue(uint256)",
            _value
        );

        (bool success, ) = targetContractAddress.call{value: msg.value}(data);
        require(success, "Call failed");
    }

    // 发送以太币（0或者大于0，都一样） + 指定不存在函数的签名 = 会触发fallback
    function TryCallTarget_2(uint256 _value) public payable {
        bytes memory data = abi.encodeWithSignature(
            "setValueXXXX(uint256)",
            _value
        );

        (bool success, ) = targetContractAddress.call{value: msg.value}(data);
        require(success, "Call failed");
    }
}
