// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Strings.sol"; // 引入自定义的 Strings 库

contract TestVoting {
    event VerifyVoteLog(bool success, address voter, address recoveredAddress);

    function verifyVote(
        address voter, // 投票用户的地址
        string memory message, // 投票消息
        uint8 v, // 签名的 v 值
        bytes32 r, // 签名的 r 值
        bytes32 s // 签名的 s 值
    ) public returns (bool) {
        // 直接将消息处理为以太坊签名的消息
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(bytes(message).length), message)
        );

        // 从签名数据恢复出签名者的地址
        address recoveredAddress = ecrecover(ethSignedMessageHash, v, r, s);
        // 比较恢复出的地址和提供的用户地址
        bool success = (recoveredAddress == voter);

        emit VerifyVoteLog(success, voter, recoveredAddress);

        return success;
    }
}
