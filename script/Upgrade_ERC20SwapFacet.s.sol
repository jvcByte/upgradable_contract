// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {ERC20SwapFacet} from "../src/facet/ERC20SwapFacet.sol";

contract Upgrade_ERC20SwapFacet is Script {
    function run() external {
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        require(diamond != address(0), "DIAMOND_ADDRESS must be set");

        uint256 ownerPk = vm.envOr("OWNER_PRIVATE_KEY", uint256(0));
        if (ownerPk != 0) {
            vm.startBroadcast(ownerPk);
        } else {
            vm.startBroadcast();
        }

        // deploy the swap facet
        ERC20SwapFacet swapFacet = new ERC20SwapFacet();

        // prepare cut: replace mint functions with swap functionality
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);

        // 1) Remove existing mint(address,uint256) if present
        bytes4[] memory removeSelectors1 = new bytes4[](1);
        removeSelectors1[0] = bytes4(keccak256("mint(address,uint256)"));
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: removeSelectors1
        });

        // 2) Remove existing mintMsgSender(uint256) if present
        bytes4[] memory removeSelectors2 = new bytes4[](1);
        removeSelectors2[0] = bytes4(keccak256("mintMsgSender(uint256)"));
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: removeSelectors2
        });

        // 3) Add swap functions
        bytes4[] memory addSelectors = new bytes4[](6);
        addSelectors[0] = bytes4(keccak256("swap()"));
        addSelectors[1] = bytes4(keccak256("getEthPrice()"));
        addSelectors[2] = bytes4(keccak256("calculateTokens(uint256)"));
        addSelectors[3] = bytes4(keccak256("getContractBalance()"));
        addSelectors[4] = bytes4(keccak256("_getValidatedEthPrice()"));
        addSelectors[5] = bytes4(keccak256("_calculateTokenAmount(uint256,uint256)"));
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(swapFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: addSelectors
        });

        // execute diamondCut
        IDiamondCut(diamond).diamondCut(cut, address(0), "");

        vm.stopBroadcast();

        console.log("Replaced mint with swap functionality. ERC20SwapFacet at:", address(swapFacet));
    }
}
