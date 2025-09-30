// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {WithdrawalFacet} from "../src/facet/WithdrawalFacet.sol";

contract Upgrade_WithdrawalFacet is Script {
    function run() external {
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        require(diamond != address(0), "DIAMOND_ADDRESS must be set");

        uint256 ownerPk = vm.envOr("OWNER_PRIVATE_KEY", uint256(0));
        if (ownerPk != 0) {
            vm.startBroadcast(ownerPk);
        } else {
            vm.startBroadcast();
        }

        // deploy the withdraw facet
        WithdrawalFacet withdrawalFacet = new WithdrawalFacet();

        // prepare cut: replace mint functions with swap functionality
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        
        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = bytes4(keccak256("withdrawETH()"));
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(withdrawalFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: addSelectors
        });

        // execute diamondCut
        IDiamondCut(diamond).diamondCut(cut, address(0), "");

        vm.stopBroadcast();

        console.log("WithdrawalFacet at:", address(withdrawalFacet));
    }
}
