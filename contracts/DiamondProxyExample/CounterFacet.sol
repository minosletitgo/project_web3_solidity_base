// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 示例 Facet 合约
contract CounterFacet {
    // 存储结构
    struct CounterStorage {
        uint256 count;
    }

    // 存储位置
    bytes32 constant COUNTER_STORAGE_POSITION = keccak256("counter.facet.storage");

    function counterStorage() internal pure returns (CounterStorage storage cs) {
        bytes32 position = COUNTER_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    // 增加计数
    function increment() external {
        counterStorage().count += 1;
    }

    // 获取计数
    function getCount() external view returns (uint256) {
        return counterStorage().count;
    }
}

