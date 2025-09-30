
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "../libraries/LibDiamond.sol";

contract WithdrawalFacet {

        event ETHWithdrawn(address indexed to, uint256 amount);
        error InvalidSender();
        error WithdrawalFailed();

     /**
     * @notice Withdraw accumulated ETH from diamond contract
     * @dev Only callable by diamond owner (via LibDiamond)
     */
    function withdrawETH() external payable {
        LibDiamond.enforceIsContractOwner();
        address to = msg.sender;
        
        if (to == address(0)) revert InvalidSender();
        
        (bool success, ) = to.call{value: address(this).balance}("");
        if (!success) revert WithdrawalFailed();
        
        emit ETHWithdrawn(to, address(this).balance);
    }
}