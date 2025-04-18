// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/ArgsZero/ArgsZero.sol";

contract DeployerArgsZero {
    event Print_getComputeAddress(address indexed thisAdr, address indexed targetAdr);
    event Print_deployAddress(address indexed thisAdr, address indexed targetAdr);

    function getComputedAddress(bytes32 salt) public returns (address, address) {
        bytes memory bytecode = type(ArgsZero).creationCode;
        bytes memory payload = abi.encodePacked(bytecode);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(payload))
        );

        address addr = address(uint160(uint256(hash)));
        emit Print_getComputeAddress(address(this), addr);
        return (address(this), addr);
    }

    function deployAddress(bytes32 salt) public returns (address, address)
    {
        address addr;
        bytes memory bytecode = type(ArgsZero).creationCode;
        bytes memory payload = abi.encodePacked(bytecode);
        assembly {
            addr := create2(0, add(payload, 0x20), mload(payload), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Print_deployAddress(address(this), addr);
        return (address(this), addr);
    }

    //////////////////////////////////////////////////////////////////////////////

    function test_CompareAddress() public {
        bytes32 salt = keccak256(abi.encodePacked("deploy-salt"));

        (, address targetAdrA) = getComputedAddress(salt);

        (, address targetAdrB) = deployAddress(salt);

        require(
            targetAdrA == targetAdrB,
            "getComputed and deploy addresses do not match"
        );
    }
}

/*
    相当于模仿"Uniswap的工厂"，来统一部署(使用create2)代币池合约....
*/
