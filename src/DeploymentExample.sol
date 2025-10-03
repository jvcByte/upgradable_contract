// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Diamond.sol";
import "./facet/DiamondCutFacet.sol";
import "./facet/ERC20Facet.sol";
import "./facet/TokenMetadataFacet.sol";
import "./facet/SVGDeployerFacet.sol";

/// @title Deployment Script Example
/// @notice This contract shows how to deploy the diamond with all facets including SVG logo support
contract Deploy {
    // Example SVG data for a token logo
    string constant EXAMPLE_SVG = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 200" width="600" height="200" role="img" aria-label="CUT logo"><defs><linearGradient id="grad" x1="0" x2="1" y1="0" y2="1"><stop offset="0%" stop-color="#ff7a18"/><stop offset="50%" stop-color="#af002d"/><stop offset="100%" stop-color="#3a1c71"/></linearGradient><filter id="ds" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur in="SourceAlpha" stdDeviation="6" result="blur"/><feOffset in="blur" dx="0" dy="6" result="off"/><feColorMatrix in="off" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.35" result="shadow"/><feBlend in="SourceGraphic" in2="shadow" mode="normal"/></filter><linearGradient id="shine" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="rgba(255,255,255,0.55)"/><stop offset="100%" stop-color="rgba(255,255,255,0.05)"/></linearGradient><mask id="cutMask"><rect x="0" y="0" width="600" height="200" fill="white"/><rect x="-50" y="70" width="700" height="20" fill="black" transform="rotate(-18 300 100)"/></mask><style type="text/css"><![CDATA[.logoText { font-family: "Segoe UI", Roboto, Helvetica, Arial, sans-serif; font-weight: 900; font-size: 128px; letter-spacing: -6px; }]]></style></defs><rect width="100%" height="100%" fill="#0b1220"/><g transform="translate(40,140)" filter="url(#ds)"><text class="logoText" x="0" y="0" fill="#071028" stroke="#071028" stroke-width="6" style="paint-order: stroke fill;">CUT</text></g><g transform="translate(40,140)"><text class="logoText" x="0" y="0" fill="url(#grad)" stroke="#0b0710" stroke-width="1.5" style="paint-order: stroke fill;">CUT</text><text class="logoText" x="0" y="0" fill="url(#shine)" style="mix-blend-mode: overlay; pointer-events: none;">CUT</text><g mask="url(#cutMask)"><rect x="-50" y="70" width="700" height="20" transform="rotate(-18 300 100)" fill="#ffffff" opacity="0.85"/><rect x="-50" y="82" width="700" height="4" transform="rotate(-18 300 100)" fill="#000000" opacity="0.12"/></g></g><g transform="translate(40,165)"><rect x="0" y="0" width="140" height="6" rx="3" fill="url(#grad)" opacity="0.9"/></g></svg>';

    function deployWithSVGLogo() external returns (address diamond, address svgLogo) {
        // 1. Deploy DiamondCutFacet first
        DiamondCutFacet cutFacet = new DiamondCutFacet();

        // 2. Deploy Diamond with DiamondCutFacet
        Diamond diamondContract = new Diamond(msg.sender, address(cutFacet));
        diamond = address(diamondContract);

        // 3. Deploy other facets
        ERC20Facet erc20Facet = new ERC20Facet();
        TokenMetadataFacet metadataFacet = new TokenMetadataFacet();
        SVGDeployerFacet svgDeployerFacet = new SVGDeployerFacet();

        // 4. Create diamond cut to add all facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](4);

        // ERC20Facet
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(erc20Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: _getERC20Selectors()
        });

        // TokenMetadataFacet
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(metadataFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: _getMetadataSelectors()
        });

        // SVGDeployerFacet
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(svgDeployerFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: _getSVGDeployerSelectors()
        });

        // 5. Execute diamond cut
        IDiamondCut(address(diamondContract)).diamondCut(cut, address(0), "");

        // 6. Initialize ERC20 token (you would call this through the diamond)
        // ERC20Facet(address(diamondContract)).initialize("My Token", "MTK", 1000000);

        // 7. Deploy SVG logo using SVGDeployerFacet
        svgLogo = SVGDeployerFacet(address(diamondContract)).deploySVGLogo(EXAMPLE_SVG, "MyToken Logo");

        // 8. Set the SVG logo for the token
        TokenMetadataFacet(address(diamondContract)).setSVGLogo(svgLogo);

        return (diamond, svgLogo);
    }

    function _getERC20Selectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](9);
        selectors[0] = ERC20Facet.name.selector;
        selectors[1] = ERC20Facet.symbol.selector;
        selectors[2] = ERC20Facet.decimals.selector;
        selectors[3] = ERC20Facet.totalSupply.selector;
        selectors[4] = ERC20Facet.balanceOf.selector;
        selectors[5] = ERC20Facet.transfer.selector;
        selectors[6] = ERC20Facet.approve.selector;
        selectors[7] = ERC20Facet.allowance.selector;
        selectors[8] = ERC20Facet.transferFrom.selector;
        return selectors;
    }

    function _getMetadataSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = TokenMetadataFacet.setSVGLogo.selector;
        selectors[1] = TokenMetadataFacet.getSVGLogoContract.selector;
        selectors[2] = TokenMetadataFacet.tokenURI.selector;
        return selectors;
    }

    function _getSVGDeployerSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = SVGDeployerFacet.deploySVGLogo.selector;
        selectors[1] = SVGDeployerFacet.deploySVGLogoWithURI.selector;
        return selectors;
    }
}

// Example usage in JavaScript (for deployment scripts):
/*
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    // Deploy the example contract
    const DeploymentExample = await ethers.getContractFactory("DeploymentExample");
    const deployment = await DeploymentExample.deploy();
    await deployment.deployed();

    // Deploy diamond with SVG logo
    const tx = await deployment.deployWithSVGLogo();
    const receipt = await tx.wait();

    console.log("Diamond deployed at:", receipt.events[0].args.diamond);
    console.log("SVG Logo deployed at:", receipt.events[1].args.svgLogo);

    // Use the diamond to get token URI
    const diamond = await ethers.getContractAt("TokenMetadataFacet", receipt.events[0].args.diamond);
    const tokenURI = await diamond.tokenURI();
    console.log("Token URI:", tokenURI);
}
*/
