// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ArgsZero {
    int public value1 = 0;

    constructor() {

    }

    function setValue1(int _value1) public {
        value1 = _value1;
    }
}
