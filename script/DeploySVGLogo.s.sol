// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Diamond} from "../src/Diamond.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {TokenMetadataFacet} from "../src/facet/TokenMetadataFacet.sol";
import {SVGDeployerFacet} from "../src/facet/SVGDeployerFacet.sol";
import {SVGLogo} from "../src/SVGLogo.sol";

/// @title Deploy SVG Logo and Token Metadata
/// @notice Deployment script for adding SVG logo functionality to existing diamond
contract DeploySVGLogo is Script {
    // CUT logo SVG data
    string constant CUT_LOGO_SVG = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 200" width="600" height="200" role="img" aria-label="CUT logo"><defs><linearGradient id="grad" x1="0" x2="1" y1="0" y2="1"><stop offset="0%" stop-color="#ff7a18"/><stop offset="50%" stop-color="#af002d"/><stop offset="100%" stop-color="#3a1c71"/></linearGradient><filter id="ds" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur in="SourceAlpha" stdDeviation="6" result="blur"/><feOffset in="blur" dx="0" dy="6" result="off"/><feColorMatrix in="off" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.35" result="shadow"/><feBlend in="SourceGraphic" in2="shadow" mode="normal"/></filter><linearGradient id="shine" x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="rgba(255,255,255,0.55)"/><stop offset="100%" stop-color="rgba(255,255,255,0.05)"/></linearGradient><mask id="cutMask"><rect x="0" y="0" width="600" height="200" fill="white"/><rect x="-50" y="70" width="700" height="20" fill="black" transform="rotate(-18 300 100)"/></mask><style type="text/css"><![CDATA[.logoText { font-family: "Segoe UI", Roboto, Helvetica, Arial, sans-serif; font-weight: 900; font-size: 128px; letter-spacing: -6px; }]]></style></defs><rect width="100%" height="100%" fill="#0b1220"/><g transform="translate(40,140)" filter="url(#ds)"><text class="logoText" x="0" y="0" fill="#071028" stroke="#071028" stroke-width="6" style="paint-order: stroke fill;">CUT</text></g><g transform="translate(40,140)"><text class="logoText" x="0" y="0" fill="url(#grad)" stroke="#0b0710" stroke-width="1.5" style="paint-order: stroke fill;">CUT</text><text class="logoText" x="0" y="0" fill="url(#shine)" style="mix-blend-mode: overlay; pointer-events: none;">CUT</text><g mask="url(#cutMask)"><rect x="-50" y="70" width="700" height="20" transform="rotate(-18 300 100)" fill="#ffffff" opacity="0.85"/><rect x="-50" y="82" width="700" height="4" transform="rotate(-18 300 100)" fill="#000000" opacity="0.12"/></g></g><g transform="translate(40,165)"><rect x="0" y="0" width="140" height="6" rx="3" fill="url(#grad)" opacity="0.9"/></g></svg>';

    function run() external {
        // Get the existing diamond address from environment
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        require(diamond != address(0), "DIAMOND_ADDRESS must be set");

        // Broadcast transactions
        uint256 ownerPk = vm.envOr("OWNER_PRIVATE_KEY", uint256(0));
        if (ownerPk != 0) {
            vm.startBroadcast(ownerPk);
        } else {
            vm.startBroadcast();
        }

        console.log("Deploying SVG logo and metadata facets to diamond:", diamond);

        // 1. Deploy facets
        TokenMetadataFacet metadataFacet = new TokenMetadataFacet();
        SVGDeployerFacet svgDeployerFacet = new SVGDeployerFacet();

        console.log("TokenMetadataFacet deployed at:", address(metadataFacet));
        console.log("SVGDeployerFacet deployed at:", address(svgDeployerFacet));

        // 2. Create diamond cut to add the facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        // TokenMetadataFacet selectors
        bytes4[] memory metadataSelectors = new bytes4[](3);
        metadataSelectors[0] = TokenMetadataFacet.setSVGLogo.selector;
        metadataSelectors[1] = TokenMetadataFacet.getSVGLogoContract.selector;
        metadataSelectors[2] = TokenMetadataFacet.tokenURI.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(metadataFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: metadataSelectors
        });

        // SVGDeployerFacet selectors
        bytes4[] memory svgDeployerSelectors = new bytes4[](2);
        svgDeployerSelectors[0] = SVGDeployerFacet.deploySVGLogo.selector;
        svgDeployerSelectors[1] = SVGDeployerFacet.deploySVGLogoWithURI.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(svgDeployerFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: svgDeployerSelectors
        });

        // 3. Execute diamond cut (no initializer needed for these facets)
        IDiamondCut(diamond).diamondCut(cut, address(0), "");

        console.log("Facets added to diamond successfully");

        // 4. Deploy SVG logo using the diamond's SVGDeployerFacet
        address svgLogo = SVGDeployerFacet(diamond).deploySVGLogo(CUT_LOGO_SVG, "CUT Token Logo");
        console.log("SVG Logo deployed at:", svgLogo);

        // 5. Set the SVG logo for the token using TokenMetadataFacet
        TokenMetadataFacet(diamond).setSVGLogo(svgLogo);
        console.log("SVG Logo set for token");

        // 6. Get and display the token URI to verify everything works
        string memory tokenURI = TokenMetadataFacet(diamond).tokenURI();
        console.log("Token URI:", tokenURI);

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("Diamond:", diamond);
        console.log("SVG Logo Contract:", svgLogo);
        console.log("TokenMetadataFacet:", address(metadataFacet));
        console.log("SVGDeployerFacet:", address(svgDeployerFacet));
        console.log("\nYou can now call:");
        console.log("- TokenMetadataFacet(diamond).tokenURI() to get metadata with logo");
        console.log("- TokenMetadataFacet(diamond).getSVGLogoContract() to get logo contract address");
        console.log("- SVGLogo(svgLogo).getSVG() to get the raw SVG data");
    }
}
