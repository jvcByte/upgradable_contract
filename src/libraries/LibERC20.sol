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
        address svgLogoContract; // Address of the SVG logo contract
    }

    function erc20Storage() internal pure returns (ERC20Storage storage es) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    /// @notice Set the SVG logo contract address
    /// @param svgLogoAddress The address of the SVG logo contract
    function setSVGLogoContract(address svgLogoAddress) internal {
        ERC20Storage storage es = erc20Storage();
        es.svgLogoContract = svgLogoAddress;
    }

    /// @notice Get the SVG logo contract address
    /// @return The address of the SVG logo contract
    function getSVGLogoContract() internal view returns (address) {
        return erc20Storage().svgLogoContract;
    }
}
