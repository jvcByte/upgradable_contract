// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract DiamondCutFacet is IDiamondCut {
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {
        LibDiamond.enforceIsContractOwner();
        for (uint256 i = 0; i < _diamondCut.length; i++) {
            FacetCutAction action = _diamondCut[i].action;
            if (action == FacetCutAction.Add) {
                LibDiamond.addFunctions(_diamondCut[i].facetAddress, _diamondCut[i].functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                LibDiamond.replaceFunctions(_diamondCut[i].facetAddress, _diamondCut[i].functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                LibDiamond.removeFunctions(_diamondCut[i].facetAddress, _diamondCut[i].functionSelectors);
            } else {
                revert("DiamondCutFacet: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        _initializeDiamondCut(_init, _calldata);
    }

    function _initializeDiamondCut(address _init, bytes calldata _calldata) private {
        if (_init == address(0)) {
            require(_calldata.length == 0, "DiamondCutFacet: _init is address(0) but _calldata is not empty");
        } else {
            require(_calldata.length > 0, "DiamondCutFacet: _calldata must not be empty");
            require(_init.code.length > 0, "DiamondCutFacet: _init must be a contract");
            Address.functionDelegateCall(_init, _calldata);
        }
    }
}


