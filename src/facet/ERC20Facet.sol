// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibERC20} from "../libraries/LibERC20.sol";

contract ERC20Facet {
    using LibERC20 for LibERC20.ERC20Storage;

    // --- ERC20 standard functions ---

    function name() external view returns (string memory) {
        return LibERC20.erc20Storage().name;
    }

    function symbol() external view returns (string memory) {
        return LibERC20.erc20Storage().symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return LibERC20.erc20Storage().totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return LibERC20.erc20Storage().balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        LibERC20.ERC20Storage storage es = LibERC20.erc20Storage();
        require(es.balances[msg.sender] >= amount, "ERC20: insufficient balance");

        es.balances[msg.sender] -= amount;
        es.balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        LibERC20.ERC20Storage storage es = LibERC20.erc20Storage();
        es.allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return LibERC20.erc20Storage().allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        LibERC20.ERC20Storage storage es = LibERC20.erc20Storage();
        uint256 allowed = es.allowances[from][msg.sender];
        require(allowed >= amount, "ERC20: allowance exceeded");
        require(es.balances[from] >= amount, "ERC20: insufficient balance");

        es.balances[from] -= amount;
        es.balances[to] += amount;
        es.allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    // --- ERC20 events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
