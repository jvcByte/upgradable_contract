// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibERC20} from "../libraries/LibERC20.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../SVGLogo.sol";

/// @title TokenMetadataFacet
/// @notice Facet for managing ERC20 token metadata including logos
contract TokenMetadataFacet {
    /// @notice Set the SVG logo contract for this token
    /// @param svgLogoAddress The address of the SVG logo contract
    function setSVGLogo(address svgLogoAddress) external {
        LibDiamond.enforceIsContractOwner();
        LibERC20.setSVGLogoContract(svgLogoAddress);
    }

    /// @notice Get the SVG logo contract address
    /// @return The address of the SVG logo contract
    function getSVGLogoContract() external view returns (address) {
        return LibERC20.getSVGLogoContract();
    }

    /// @notice Generate token URI with metadata including logo
    /// @return A JSON string with token metadata
    function tokenURI() external view returns (string memory) {
        LibERC20.ERC20Storage storage es = LibERC20.erc20Storage();
        address svgLogoAddress = es.svgLogoContract;

        string memory logoURI = "";
        if (svgLogoAddress != address(0)) {
            logoURI = SVGLogo(svgLogoAddress).tokenURI();
        }

        // Create JSON metadata
        return string(abi.encodePacked(
            '{"name":"', es.name,
            '","symbol":"', es.symbol,
            '","decimals":18',
            ',"logo":"', logoURI, '"}'
        ));
    }

    /// @notice Get basic token information
    /// @return name The token name
    /// @return symbol The token symbol
    /// @return decimals The token decimals
    /// @return totalSupply The total supply
    /// @return svgLogoContract The SVG logo contract address
    function getTokenInfo() external view returns (
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        address svgLogoContract
    ) {
        LibERC20.ERC20Storage storage es = LibERC20.erc20Storage();
        return (
            es.name,
            es.symbol,
            18, // decimals
            es.totalSupply,
            es.svgLogoContract
        );
    }
}
