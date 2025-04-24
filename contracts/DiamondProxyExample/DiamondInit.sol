// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "Diamond.sol"

// 部署初始化合约
contract DiamondInit {
    function init(address _counterFacet) external returns (IDiamondCut.FacetCut[] memory cuts) {
        cuts = new IDiamondCut.FacetCut[](1);
        
        bytes4[] memory functionSelectors = new bytes4[](2);
        functionSelectors[0] = CounterFacet.increment.selector;
        functionSelectors[1] = CounterFacet.getCount.selector;
        
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: _counterFacet,
            action: IDiamondCut.CutAction.Add,
            functionSelectors: functionSelectors
        });
    }
}
