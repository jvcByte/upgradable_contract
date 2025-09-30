// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

contract Diamond {
    constructor(address _contractOwner, address _diamondCutFacet) {
        _contractOwner; // ignore param, set owner to the actual deployer (broadcaster)
        LibDiamond.setContractOwner(msg.sender);

        // seed diamondCut selector to point to _diamondCutFacet so initial cut can be executed
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // register facet address if first time
        LibDiamond.FacetFunctionSelectors storage ffs = ds.facetFunctionSelectors[_diamondCutFacet];
        if (ffs.selectors.length == 0) {
            ffs.facetPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_diamondCutFacet);
        }

        bytes4 selector = IDiamondCut.diamondCut.selector; // 0x1f931c1c
        ffs.selectors.push(selector);
        ds.selectorToFacetAndPosition[selector] = LibDiamond.FacetAddressAndPosition({
            facetAddress: _diamondCutFacet,
            selectorPosition: uint16(ffs.selectors.length - 1)
        });
    }

    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: function not found");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}


