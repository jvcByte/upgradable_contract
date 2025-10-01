// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibMultiSig} from "../../libraries/multisig/LibMultiSig.sol";
import {LibERC20} from "../../libraries/LibERC20.sol";

/**
 * @title MultiSigManagementFacet
 * @notice Facet for managing MultiSig transactions (submit, confirm, revoke, execute)
 * @dev Part of Diamond Standard (EIP-2535) implementation
 * @dev Executes transactions by minting ERC20 tokens to the recipient
 */
contract MultiSigManagementFacet {
    
    // Events
    event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value);
    event TransactionConfirmed(uint256 indexed txId, address indexed owner);
    event TransactionRevoked(uint256 indexed txId, address indexed owner);
    event TransactionExecuted(uint256 indexed txId, address indexed to, uint256 tokenAmount);
    event Deposit(address indexed sender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Submit a new transaction for approval
     * @param _to Destination address (will receive minted tokens)
     * @param _value Amount of tokens to mint (in token decimals, usually 18)
     * @param _data Call data (optional, can be used for additional logic)
     * @return txId The transaction ID
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external returns (uint256 txId) {
        LibMultiSig.enforceIsOwner();
        LibMultiSig.MultiSigStorage storage ms = LibMultiSig.multiSigStorage();
        
        txId = ms.transactionCount;
        
        LibMultiSig.Transaction storage transaction = ms.transactions[txId];
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;
        transaction.executed = false;
        transaction.confirmationCount = 0;

        ms.transactionCount++;

        emit TransactionSubmitted(txId, _to, _value);
    }

    /**
     * @notice Confirm a pending transaction
     * @param _txId Transaction ID to confirm
     */
    function confirmTransaction(uint256 _txId) external {
        LibMultiSig.enforceIsOwner();
        LibMultiSig.enforceTransactionExists(_txId);
        LibMultiSig.enforceNotExecuted(_txId);
        LibMultiSig.enforceNotConfirmed(_txId);
        
        LibMultiSig.MultiSigStorage storage ms = LibMultiSig.multiSigStorage();
        LibMultiSig.Transaction storage transaction = ms.transactions[_txId];
        
        transaction.isConfirmed[msg.sender] = true;
        transaction.confirmationCount++;

        emit TransactionConfirmed(_txId, msg.sender);
    }

    /**
     * @notice Revoke a previously given confirmation
     * @param _txId Transaction ID to revoke confirmation for
     */
    function revokeConfirmation(uint256 _txId) external {
        LibMultiSig.enforceIsOwner();
        LibMultiSig.enforceTransactionExists(_txId);
        LibMultiSig.enforceNotExecuted(_txId);
        LibMultiSig.enforceConfirmed(_txId);
        
        LibMultiSig.MultiSigStorage storage ms = LibMultiSig.multiSigStorage();
        LibMultiSig.Transaction storage transaction = ms.transactions[_txId];
        
        transaction.isConfirmed[msg.sender] = false;
        transaction.confirmationCount--;

        emit TransactionRevoked(_txId, msg.sender);
    }

    /**
     * @notice Execute a confirmed transaction by minting tokens to recipient
     * @param _txId Transaction ID to execute
     * @dev Mints ERC20 tokens to the `to` address instead of sending ETH
     * @dev If data is provided, it will be executed as a call to the `to` address
     */
    function executeTransaction(uint256 _txId) external {
        LibMultiSig.enforceIsOwner();
        LibMultiSig.enforceTransactionExists(_txId);
        LibMultiSig.enforceNotExecuted(_txId);
        
        LibMultiSig.MultiSigStorage storage ms = LibMultiSig.multiSigStorage();
        LibMultiSig.Transaction storage transaction = ms.transactions[_txId];
        
        if (transaction.confirmationCount < ms.requiredConfirmations) {
            revert LibMultiSig.InsufficientConfirmations();
        }

        transaction.executed = true;

        // Mint tokens to the recipient
        LibERC20.ERC20Storage storage es = LibERC20.erc20Storage();
        es.totalSupply += transaction.value;
        es.balances[transaction.to] += transaction.value;

        emit Transfer(address(0), transaction.to, transaction.value);
        emit TransactionExecuted(_txId, transaction.to, transaction.value);

        // Execute additional call data if provided
        if (transaction.data.length > 0) {
            (bool success, ) = transaction.to.call(transaction.data);
            if (!success) revert LibMultiSig.TransactionFailed();
        }
    }
}