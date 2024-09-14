// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 模拟逻辑合约
contract Logic {
    //0x1e7bA0BcDaaDA9e986Ec30F872c454c5C01Aa1Da
    uint public num;
    address public sender;

    event DoSetVars(uint _num);

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        emit DoSetVars(_num);
    }
}

//模拟代理合约
contract Proxy {
    //0x1ecF8deF93460AeA1aEe242e86814dbD95a1e010    
    uint256 public num;
    address public sender;

    address public addrAccount;
    address public addrLogic;

    constructor(address _addrLogic) {
        require(_addrLogic != address(0));
        addrAccount = msg.sender;
        addrLogic = _addrLogic;
    }

    // 通过call来调用Logic的setVars()函数，将改变合约Logic里的状态变量(Logic中 num = 此处的_num，sender = Proxy的地址)
    function callSetVars(uint256 _num) external payable {
        // call setVars()
        (bool success, ) = addrLogic.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        require(success, "callSetVars failed");
    }

    // 通过delegatecall来调用Logic的setVars()函数，将改变合约Proxy里的状态变量(Logic中 num = 此处的_num，sender = addrAccount)
    function delegatecallSetVars(uint256 _num) external payable {
        // delegatecall setVars()
        (bool success, ) = addrLogic.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        require(success, "delegatecall failed");
    }
}
