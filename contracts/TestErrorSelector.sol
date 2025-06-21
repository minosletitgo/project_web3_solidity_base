// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TestErrorSelector {
    // 定义两个自定义 error
    error TransferNotOwner(); // 无参数的 error
    error TransferNotOwnerWithSender(address sender); // 带参数的 error

    // 函数：获取并记录 TransferNotOwner 的 selector
    function getTransferNotOwnerSelector() public pure returns(bytes4 selector1, bytes4 selector2) {
        selector1 = TransferNotOwner.selector;
        selector2 = bytes4(keccak256("TransferNotOwner()"));
    }

    // 函数：获取并记录 TransferNotOwnerWithSender 的 selector
    function getTransferNotOwnerWithSenderSelector() public pure returns(bytes4 selector1, bytes4 selector2) {
        selector1 = TransferNotOwnerWithSender.selector;
        selector2 = bytes4(keccak256("TransferNotOwnerWithSender(address)"));
    }
}
