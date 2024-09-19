// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// library CodeFetcher {
//     function getCreationCode() external pure returns (bytes memory) {
//         return type(FunctionSelector).creationCode;
//     }
// }

contract FunctionSelector {
    //constructor() {}

    function DoSomething() public pure {}

    function DoSomething2(uint256 value) public pure {}

    //////////////////////////////////////////////////////////

    // function GetContractCreationCode() public pure returns (bytes memory) {
    //     return CodeFetcher.getCreationCode();
    // }

    /*
        说明：
        在调用合约FunctionSelector成功后，查看"Transaction Action"或"input":
        1. 部署的时候，使用的是"合约部署字节码"（即，creationCode）
        2. 调用普通函数的时候，使用的是"函数Selector"（前4字节为"selector"，后32字节为"参数"）
    */

    function GetSelector_DoSomething() public pure returns (bytes4) {
        return bytes4(keccak256("DoSomething()"));
    }

    function GetSelector_DoSomething_UsingSelector() public pure returns (bytes4)
    {
        return this.DoSomething.selector;
    }

    function GetSelector_DoSomething2() public pure returns (bytes4) {
        return bytes4(keccak256("DoSomething2(uint256)"));
    }

    function GetSelector_DoSomething2_UsingSelector() public pure returns (bytes4)
    {
        return this.DoSomething2.selector;
    }
}

contract FunctionSelectorHelper {
    function GetContractCreationCode() public pure returns (bytes memory) {
        return type(FunctionSelector).creationCode;
    }
}
