// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibMultiSig} from "../../libraries/multisig/LibMultiSig.sol";

/**
 * @title MultiSigViewFacet
 * @notice Facet for viewing MultiSig state and transaction details
 * @dev Part of Diamond Standard (EIP-2535) implementation
 */
contract MultiSigViewFacet {
    
    /**
     * @notice Get list of all owners
     * @return Array of owner addresses
     */
    function getOwners() external view returns (address[] memory) {
        return LibMultiSig.multiSigStorage().owners;
    }

    /**
     * @notice Check if an address is an owner
     * @param _owner Address to check
     * @return True if address is an owner
     */
    function isOwner(address _owner) external view returns (bool) {
        return LibMultiSig.multiSigStorage().isOwner[_owner];
    }

    /**
     * @notice Get required number of confirmations
     * @return Number of required confirmations
     */
    function requiredConfirmations() external view returns (uint256) {
        return LibMultiSig.multiSigStorage().requiredConfirmations;
    }

    /**
     * @notice Get total transaction count
     * @return Total number of transactions
     */
    function getTransactionCount() external view returns (uint256) {
        return LibMultiSig.multiSigStorage().transactionCount;
    }

    /**
     * @notice Get transaction details
     * @param _txId Transaction ID
     * @return to Destination address
     * @return value ETH value
     * @return data Call data
     * @return executed Whether transaction has been executed
     * @return confirmationCount Number of confirmations
     */
    function getTransaction(uint256 _txId)
        external
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 confirmationCount
        )
    {
        LibMultiSig.enforceTransactionExists(_txId);
        LibMultiSig.MultiSigStorage storage ms = LibMultiSig.multiSigStorage();
        LibMultiSig.Transaction storage transaction = ms.transactions[_txId];
        
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.confirmationCount
        );
    }

    /**
     * @notice Check if a transaction is confirmed by a specific owner
     * @param _txId Transaction ID
     * @param _owner Owner address
     * @return True if confirmed by owner
     */
    function isConfirmedBy(uint256 _txId, address _owner)
        external
        view
        returns (bool)
    {
        LibMultiSig.enforceTransactionExists(_txId);
        return LibMultiSig.multiSigStorage().transactions[_txId].isConfirmed[_owner];
    }

    /**
     * @notice Get confirmation count for a transaction
     * @param _txId Transaction ID
     * @return Number of confirmations
     */
    function getConfirmationCount(uint256 _txId)
        external
        view
        returns (uint256)
    {
        LibMultiSig.enforceTransactionExists(_txId);
        return LibMultiSig.multiSigStorage().transactions[_txId].confirmationCount;
    }

    /**
     * @notice Get diamond contract's ETH balance
     * @return ETH balance in wei
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get multiple transaction details at once (batch query)
     * @param _startId Starting transaction ID
     * @param _count Number of transactions to fetch
     * @return tos Arrays of addresses that received funds
     * @return values Array of amount they recieved
     * @return executeds Status of the transactions (true/false)
     * @return confirmationCounts How many signatories approved the transaction
     */
    function getTransactionsBatch(uint256 _startId, uint256 _count)
        external
        view
        returns (
            address[] memory tos,
            uint256[] memory values,
            bool[] memory executeds,
            uint256[] memory confirmationCounts
        )
    {
        LibMultiSig.MultiSigStorage storage ms = LibMultiSig.multiSigStorage();
        
        uint256 endId = _startId + _count;
        if (endId > ms.transactionCount) {
            endId = ms.transactionCount;
        }
        
        uint256 actualCount = endId - _startId;
        tos = new address[](actualCount);
        values = new uint256[](actualCount);
        executeds = new bool[](actualCount);
        confirmationCounts = new uint256[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            uint256 txId = _startId + i;
            LibMultiSig.Transaction storage txn = ms.transactions[txId];
            tos[i] = txn.to;
            values[i] = txn.value;
            executeds[i] = txn.executed;
            confirmationCounts[i] = txn.confirmationCount;
        }
    }

    /**
     * @notice Get pending transactions (not yet executed)
     * @return pendingTxIds Array of pending transaction IDs
     */
    function getPendingTransactions() external view returns (uint256[] memory pendingTxIds) {
        LibMultiSig.MultiSigStorage storage ms = LibMultiSig.multiSigStorage();
        
        // Count pending transactions
        uint256 pendingCount = 0;
        for (uint256 i = 0; i < ms.transactionCount; i++) {
            if (!ms.transactions[i].executed) {
                pendingCount++;
            }
        }
        
        // Collect pending transaction IDs
        pendingTxIds = new uint256[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 0; i < ms.transactionCount; i++) {
            if (!ms.transactions[i].executed) {
                pendingTxIds[index] = i;
                index++;
            }
        }
    }
}