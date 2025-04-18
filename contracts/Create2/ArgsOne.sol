// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ArgsOne {
    int public value1 = 0;

    constructor(int _value1) {
        value1 = _value1;
    }

    function setValue1(int _value1) public {
        value1 = _value1;
    }
}
