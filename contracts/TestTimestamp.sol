// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    block.timestamp
    -> 属于区块的属性
    -> 区块一旦生成，它就不会改变，直至新区块产生，block.timestamp才会更新
*/

contract TimestampContract {
    uint256 public lastUpdated;

    constructor() {
        lastUpdated = block.timestamp;
    }

    function updateTimestamp() public {
        // 该函数会改变状态变量，故"在进入前，就产生了新区块"
        // block.timestamp 必然会更新
        lastUpdated = block.timestamp;
    }
}