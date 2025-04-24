// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// 钻石标准接口 (EIP-2535)
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }
    function facets() external view returns (Facet[] memory);
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory);
    function facetAddresses() external view returns (address[] memory);
    function facetAddress(bytes4 _functionSelector) external view returns (address);
}

interface IDiamondCut {
    enum CutAction { Add, Replace, Remove }
    struct FacetCut {
        address facetAddress;
        CutAction action;
        bytes4[] functionSelectors;
    }
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// 错误定义
    error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);
    error NoSelectorsProvidedForFacet(address _facetAddress);
    error CannotReplaceImmutableFunction(bytes4 _selector);
    error CannotRemoveFunctionFromNonExistentFacet(bytes4 _selector);


////////////////////////////////////////////////////////////////////////////////////////////////////////////


// 钻石主合约
contract Diamond {
    // 存储结构
    struct DiamondStorage {
        mapping(bytes4 => address) selectorToFacet;
        mapping(address => bytes4[]) facetToSelectors;
        address[] facetAddresses;
        address owner;
    }
    
    // 存储位置
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    
    // 事件
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // 获取存储
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    constructor(address _owner) {
        DiamondStorage storage ds = diamondStorage();
        ds.owner = _owner;
    }
    
    // 修饰符：仅限拥有者
    modifier onlyOwner() {
        require(msg.sender == diamondStorage().owner, "Not owner");
        _;
    }
    
    // 实现 diamondCut 函数
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external onlyOwner {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCut memory cut = _diamondCut[facetIndex];
            if (cut.functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacet(cut.facetAddress);
            }
            
            DiamondStorage storage ds = diamondStorage();
            
            if (cut.action == IDiamondCut.CutAction.Add) {
                addFacet(ds, cut);
            } else if (cut.action == IDiamondCut.CutAction.Replace) {
                replaceFacet(ds, cut);
            } else if (cut.action == IDiamondCut.CutAction.Remove) {
                removeFacet(ds, cut);
            }
        }
        
        emit DiamondCut(_diamondCut, _init, _calldata);
        
        // 执行初始化调用
        if (_init != address(0)) {
            (bool success, ) = _init.delegatecall(_calldata);
            if (!success) {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }
    
    function addFacet(DiamondStorage storage ds, IDiamondCut.FacetCut memory cut) internal {
        if (ds.facetToSelectors[cut.facetAddress].length == 0) {
            ds.facetAddresses.push(cut.facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < cut.functionSelectors.length; selectorIndex++) {
            bytes4 selector = cut.functionSelectors[selectorIndex];
            ds.selectorToFacet[selector] = cut.facetAddress;
            ds.facetToSelectors[cut.facetAddress].push(selector);
        }
    }
    
    function replaceFacet(DiamondStorage storage ds, IDiamondCut.FacetCut memory cut) internal {
        for (uint256 selectorIndex; selectorIndex < cut.functionSelectors.length; selectorIndex++) {
            bytes4 selector = cut.functionSelectors[selectorIndex];
            address oldFacet = ds.selectorToFacet[selector];
            if (oldFacet == address(0)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            ds.selectorToFacet[selector] = cut.facetAddress;
            if (oldFacet != cut.facetAddress) {
                ds.facetToSelectors[cut.facetAddress].push(selector);
            }
        }
    }
    
    function removeFacet(DiamondStorage storage ds, IDiamondCut.FacetCut memory cut) internal {
        for (uint256 selectorIndex; selectorIndex < cut.functionSelectors.length; selectorIndex++) {
            bytes4 selector = cut.functionSelectors[selectorIndex];
            address facet = ds.selectorToFacet[selector];
            if (facet == address(0)) {
                revert CannotRemoveFunctionFromNonExistentFacet(selector);
            }
            delete ds.selectorToFacet[selector];
            // 移除选择器从facetToSelectors
            bytes4[] storage selectors = ds.facetToSelectors[facet];
            for (uint256 i; i < selectors.length; i++) {
                if (selectors[i] == selector) {
                    selectors[i] = selectors[selectors.length - 1];
                    selectors.pop();
                    break;
                }
            }
        }
    }
    
    // 实现 DiamondLoupe 的 facets 函数
    function facets() external view returns (IDiamondLoupe.Facet[] memory facets_) {
        DiamondStorage storage ds = diamondStorage();
        facets_ = new IDiamondLoupe.Facet[](ds.facetAddresses.length);
        for (uint256 i; i < ds.facetAddresses.length; i++) {
            facets_[i].facetAddress = ds.facetAddresses[i];
            facets_[i].functionSelectors = ds.facetToSelectors[ds.facetAddresses[i]];
        }
    }
    
    // 其他 Loupe 函数
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory) {
        return diamondStorage().facetToSelectors[_facet];
    }
    
    function facetAddresses() external view returns (address[] memory) {
        return diamondStorage().facetAddresses;
    }
    
    function facetAddress(bytes4 _functionSelector) external view returns (address) {
        return diamondStorage().selectorToFacet[_functionSelector];
    }
    
    // 回退函数，代理调用到对应的 Facet
    fallback() external payable {
        DiamondStorage storage ds = diamondStorage();
        address facet = ds.selectorToFacet[msg.sig];
        require(facet != address(0), "Function does not exist");
        
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    receive() external payable {}
}
