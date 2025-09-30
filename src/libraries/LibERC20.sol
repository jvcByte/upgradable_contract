// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LibERC20 {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.erc20.storage");

    struct ERC20Storage {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    function erc20Storage() internal pure returns (ERC20Storage storage es) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}
