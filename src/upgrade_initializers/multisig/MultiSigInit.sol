// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibMultiSig} from "../../libraries/multisig/LibMultiSig.sol";

/**
 * @title MultiSigInit
 * @notice Initialization contract for MultiSig diamond
 * @dev Called once during diamond deployment via diamondCut
 */
contract MultiSigInit {
    
    /**
     * @notice Initialize the MultiSig functionality
     * @param _owners Array of owner addresses
     * @param _requiredConfirmations Number of confirmations required
     */
    function init(address[] memory _owners, uint256 _requiredConfirmations) external {
        LibMultiSig.MultiSigStorage storage ms = LibMultiSig.multiSigStorage();
        
        if (_owners.length == 0) revert LibMultiSig.InvalidOwner();
        if (_requiredConfirmations == 0 || _requiredConfirmations > _owners.length) {
            revert LibMultiSig.InvalidRequiredConfirmations();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) revert LibMultiSig.ZeroAddress();
            if (ms.isOwner[owner]) revert LibMultiSig.DuplicateOwner();

            ms.isOwner[owner] = true;
            ms.owners.push(owner);
        }

        ms.requiredConfirmations = _requiredConfirmations;
        ms.transactionCount = 0;
    }
}