// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibERC20} from "../libraries/LibERC20.sol";

contract DiamondInit {
    function init(string memory _name, string memory _symbol, address _owner, uint256 _initialSupply, address _to) external {
        // set ERC20 metadata
        LibERC20.ERC20Storage storage es = LibERC20.erc20Storage();
        es.name = _name;
        es.symbol = _symbol;
        // mint initial supply if requested
        if (_initialSupply > 0 && _to != address(0)) {
            es.totalSupply += _initialSupply;
            es.balances[_to] += _initialSupply;
        }
        // owner is set during Diamond constructor and OwnershipFacet
        _owner; // silence to indicate provided but not used here
    }
}


