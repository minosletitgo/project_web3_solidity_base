// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ArgsTwo {
    int public nValue1 = 0;
    string public strValue2 = "";

    constructor(int _nValue1, string memory _strValue2) {
        nValue1 = _nValue1;
        strValue2 = _strValue2;
    }

    function setValue1(int _nValue1) public {
        nValue1 = _nValue1;
    }

    function setValue2(string memory _strValue2) public {
        strValue2 = _strValue2;
    }
}
