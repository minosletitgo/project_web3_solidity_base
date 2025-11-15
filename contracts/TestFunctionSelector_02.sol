// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestFunctionSelector_02 {
    
    struct Call3 {
        address target;
        bool allowFailure;
        bytes callData;
    }
    
    struct Call3Value {
        address target;
        bool allowFailure;
        uint256 value;
        bytes callData;
    }
    
    struct Result {
        bool success;
        bytes returnData;
    }
    
    
    function aggregate3(Call3[] calldata calls) external payable returns (Result[] memory returnData) {
    
    }
    
    function aggregate3Value(Call3Value[] calldata calls) external payable returns (Result[] memory returnData) {
    
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    function getAggregate3ValueSelector_0() public pure returns (bytes4) {
        // 原始打印
        return bytes4(this.aggregate3Value.selector);
    }
    
    function getAggregate3ValueSelector_1() public pure returns (bytes4) {
        // 错误打印
        return bytes4(keccak256(bytes("aggregate3Value(Call3Value[])")));
    }
    
    function getAggregate3ValueSelector_2() public pure returns (bytes4) {
        // 正确打印（结构体展开）
        return bytes4(keccak256("aggregate3Value((address,bool,uint256,bytes)[])"));
    }
}
