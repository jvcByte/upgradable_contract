// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {ERC20MintFacet} from "../src/facet/ERC20MintFacet.sol";

contract Upgrade_ERC20MintFacet is Script {
    function run() external {
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        require(diamond != address(0), "DIAMOND_ADDRESS must be set");

        uint256 ownerPk = vm.envOr("OWNER_PRIVATE_KEY", uint256(0));
        if (ownerPk != 0) {
            vm.startBroadcast(ownerPk);
        } else {
            vm.startBroadcast();
        }

        // deploy the mint facet
        ERC20MintFacet mintFacet = new ERC20MintFacet();

        // prepare cut in two steps to avoid selector conflicts
        // 1) Replace existing mint(address,uint256) if present
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        bytes4[] memory replaceSelectors = new bytes4[](1);
        replaceSelectors[0] = bytes4(keccak256("mint(address,uint256)"));
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: replaceSelectors
        });

        // 2) Add mintMsgSender(uint256) if it's a new selector
        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = bytes4(keccak256("mintMsgSender(uint256)"));
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: addSelectors
        });

        // execute diamondCut without initializer
        IDiamondCut(diamond).diamondCut(cut, address(0), "");

        vm.stopBroadcast();

        console.log("Added ERC20MintFacet at:", address(mintFacet));
    }
}
