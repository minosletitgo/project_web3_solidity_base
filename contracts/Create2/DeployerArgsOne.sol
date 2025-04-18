// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/ArgsOne/ArgsOne.sol";

contract DeployerArgsOne {
    event Print_getComputeAddress(uint256 value1 ,address indexed thisAdr, address indexed targetAdr);
    event Print_deployAddress(uint256 value1 ,address indexed thisAdr, address indexed targetAdr);

    function getComputedAddress(
        bytes32 salt,
        uint256 value1
    ) public returns (uint256, address, address) {
        bytes memory bytecode = type(ArgsOne).creationCode;
        bytes memory payload = abi.encodePacked(bytecode, abi.encode(value1));
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(payload))
        );

        address addr = address(uint160(uint256(hash)));
        emit Print_getComputeAddress(value1, address(this), addr);
        return (value1, address(this), addr);
    }

    function deployAddress(bytes32 salt, uint256 value1) public returns (uint256, address, address)
    {
        address addr;
        bytes memory bytecode = type(ArgsOne).creationCode;
        bytes memory payload = abi.encodePacked(bytecode, abi.encode(value1));
        assembly {
            addr := create2(0, add(payload, 0x20), mload(payload), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Print_deployAddress(value1, address(this), addr);
        return (value1, address(this), addr);
    }

    //////////////////////////////////////////////////////////////////////////////

    function test_CompareAddress() public {
        bytes32 salt = keccak256(abi.encodePacked("deploy-salt"));
        uint256 number = 2;

        (, , address targetAdrA) = getComputedAddress(salt, number);

        (, , address targetAdrB) = deployAddress(salt, number);

        require(
            targetAdrA == targetAdrB,
            "getComputed and deploy addresses do not match"
        );
    }
}

/*
    相当于模仿"Uniswap的工厂"，来统一部署(使用create2)代币池合约....
*/
