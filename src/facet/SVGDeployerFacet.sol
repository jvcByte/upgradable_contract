// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../SVGLogo.sol";

/// @title SVGDeployerFacet
/// @notice Facet for deploying SVG logo contracts for ERC20 tokens
contract SVGDeployerFacet {
    /// @notice Emitted when a new SVG logo contract is deployed
    event SVGLogoDeployed(address indexed svgContract, string name);

    /// @notice Deploy a new SVG logo contract
    /// @param svgData The SVG data as a string (should include <svg> tags)
    /// @param logoName A name identifier for the logo
    /// @return svgContract The address of the deployed SVG contract
    function deploySVGLogo(string calldata svgData, string calldata logoName)
        public
        returns (address svgContract)
    {
        // Only contract owner can deploy SVG logos
        LibDiamond.enforceIsContractOwner();

        // Deploy the SVG logo contract
        SVGLogo newSVGLogo = new SVGLogo(svgData);
        svgContract = address(newSVGLogo);

        emit SVGLogoDeployed(svgContract, logoName);
    }

    /// @notice Deploy an SVG logo and return its tokenURI format
    /// @param svgData The SVG data as a string
    /// @param logoName A name identifier for the logo
    /// @return svgContract The address of the deployed SVG contract
    /// @return tokenURI The tokenURI string for the SVG
    function deploySVGLogoWithURI(string calldata svgData, string calldata logoName)
        external
        returns (address svgContract, string memory tokenURI)
    {
        // Only contract owner can deploy SVG logos
        LibDiamond.enforceIsContractOwner();

        // Deploy the SVG logo contract
        SVGLogo newSVGLogo = new SVGLogo(svgData);
        svgContract = address(newSVGLogo);

        emit SVGLogoDeployed(svgContract, logoName);
        tokenURI = newSVGLogo.tokenURI();
    }
}
