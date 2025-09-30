// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibERC20} from "../libraries/LibERC20.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract ERC20MintFacet {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function mint(address to, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        require(to != address(0), "ERC20: mint to zero");
        LibERC20.ERC20Storage storage es = LibERC20.erc20Storage();
        es.totalSupply += amount;
        es.balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
