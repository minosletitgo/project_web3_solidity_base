// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMyInterface {
    function myFunction(uint256 value) external;

    function anotherFunction(address addr) external;

    function thirdFunction(bool flag) external;
}

contract MyContract {
    function getInterfaceId() public pure returns (bytes4) {
        return type(IMyInterface).interfaceId;
    }

    function getInterfaceId2() public pure returns (bytes4) {
        // 获取每个函数的选择器
        bytes4 selector1 = bytes4(keccak256("myFunction(uint256)"));
        bytes4 selector2 = bytes4(keccak256("anotherFunction(address)"));
        bytes4 selector3 = bytes4(keccak256("thirdFunction(bool)"));

        // 将所有选择器进行 XOR 运算，得到 interfaceId
        return selector1 ^ selector2 ^ selector3;
    }
}
