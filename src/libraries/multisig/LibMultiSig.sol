// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title LibMultiSig
 * @notice Diamond storage library for MultiSig functionality
 * @dev Uses diamond storage pattern to avoid storage collisions
 */
library LibMultiSig {
    bytes32 constant MULTISIG_STORAGE_POSITION = keccak256("diamond.standard.multisig.storage");

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        mapping(address => bool) isConfirmed;
        uint256 confirmationCount;
    }

    struct MultiSigStorage {
        address[] owners;
        mapping(address => bool) isOwner;
        uint256 requiredConfirmations;
        uint256 transactionCount;
        mapping(uint256 => Transaction) transactions;
    }

    /**
     * @dev Returns the storage position for MultiSig data
     */
    function multiSigStorage() internal pure returns (MultiSigStorage storage ms) {
        bytes32 position = MULTISIG_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }

    /**
     * @dev Enforces that the caller is a MultiSig owner
     */
    function enforceIsOwner() internal view {
        if (!multiSigStorage().isOwner[msg.sender]) {
            revert NotOwner();
        }
    }

    /**
     * @dev Checks if transaction exists
     */
    function enforceTransactionExists(uint256 _txId) internal view {
        if (_txId >= multiSigStorage().transactionCount) {
            revert TransactionNotExists();
        }
    }

    /**
     * @dev Checks if transaction is not executed
     */
    function enforceNotExecuted(uint256 _txId) internal view {
        if (multiSigStorage().transactions[_txId].executed) {
            revert TransactionAlreadyExecuted();
        }
    }

    /**
     * @dev Checks if transaction is not confirmed by caller
     */
    function enforceNotConfirmed(uint256 _txId) internal view {
        if (multiSigStorage().transactions[_txId].isConfirmed[msg.sender]) {
            revert TransactionAlreadyConfirmed();
        }
    }

    /**
     * @dev Checks if transaction is confirmed by caller
     */
    function enforceConfirmed(uint256 _txId) internal view {
        if (!multiSigStorage().transactions[_txId].isConfirmed[msg.sender]) {
            revert TransactionNotConfirmed();
        }
    }

    // Custom errors
    error NotOwner();
    error InvalidOwner();
    error InvalidRequiredConfirmations();
    error TransactionNotExists();
    error TransactionAlreadyConfirmed();
    error TransactionNotConfirmed();
    error TransactionAlreadyExecuted();
    error InsufficientConfirmations();
    error TransactionFailed();
    error ZeroAddress();
    error DuplicateOwner();
}