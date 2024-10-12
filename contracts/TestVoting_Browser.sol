// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestVoting_Browser {
    event VerifyVoteLog(bool success, address voter, address recoveredAddress);

    function verifyVote(
        address voter, // 投票用户的地址
        bytes32 msgHash, 
        bytes memory signature
    ) public returns (bool) {
        // 检查签名长度，65是标准r,s,v签名的长度
        require(signature.length == 65, "invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        // 目前只能用assembly (内联汇编)来从签名中获得r,s,v的值
        assembly {
            /*
            前32 bytes存储签名的长度 (动态数组存储规则)
            add(sig, 32) = sig的指针 + 32
            等效为略过signature的前32 bytes
            mload(p) 载入从内存地址p起始的接下来32 bytes数据
            */
            // 读取长度数据后的32 bytes
            r := mload(add(signature, 0x20))
            // 读取之后的32 bytes
            s := mload(add(signature, 0x40))
            // 读取最后一个byte
            v := byte(0, mload(add(signature, 0x60)))
        }
        // 使用ecrecover(全局函数)：利用 msgHash 和 r,s,v 恢复 signer 地址
        address recoveredAddress = ecrecover(msgHash, v, r, s);

        // 比较恢复出的地址和提供的用户地址
        bool success = (recoveredAddress == voter);

        emit VerifyVoteLog(success, voter, recoveredAddress);

        return success;
    }
}
