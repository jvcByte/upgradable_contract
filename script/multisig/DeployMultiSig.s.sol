// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IDiamondCut} from "../../src/interfaces/IDiamondCut.sol";
import {MultiSigManagementFacet} from "../../src/facet/multisig/MultiSigManagementFacet.sol";
import {MultiSigViewFacet} from "../../src/facet/multisig/MultiSigViewFacet.sol";
import {MultiSigInit} from "../../src/upgrade_initializers/multisig/MultiSigInit.sol";

/**
 * @title DeployMultiSig
 * @notice Deploy and add MultiSig facets to existing Diamond
 * @dev Usage: 
 *   1. Set DIAMOND_ADDRESS in .env
 *   2. Set MULTISIG_OWNERS (comma-separated addresses) in .env
 *   3. Set MULTISIG_REQUIRED_CONFIRMATIONS in .env
 *   4. Run: forge script script/DeployMultiSig.s.sol:DeployMultiSig --rpc-url sepolia --broadcast --verify
 */
contract DeployMultiSig is Script {
    function run() external {
        // Get diamond address from env
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        require(diamond != address(0), "DIAMOND_ADDRESS must be set");

        // Get MultiSig configuration from env
        string memory ownersStr = vm.envString("MULTISIG_OWNERS");
        uint256 requiredConfirmations = vm.envUint("MULTISIG_REQUIRED_CONFIRMATIONS");
        
        // Parse owners (comma-separated addresses)
        address[] memory owners = parseAddresses(ownersStr);
        require(owners.length > 0, "At least one owner required");
        require(requiredConfirmations > 0 && requiredConfirmations <= owners.length, 
            "Invalid required confirmations");

        console.log("Deploying MultiSig to Diamond:", diamond);
        console.log("Number of owners:", owners.length);
        console.log("Required confirmations:", requiredConfirmations);

        // Start broadcast
        uint256 deployerPk = vm.envOr("OWNER_PRIVATE_KEY", uint256(0));
        if (deployerPk != 0) {
            vm.startBroadcast(deployerPk);
        } else {
            vm.startBroadcast();
        }

        // 1. Deploy facets
        console.log("\n1. Deploying MultiSigManagementFacet...");
        MultiSigManagementFacet managementFacet = new MultiSigManagementFacet();
        console.log("   Deployed at:", address(managementFacet));

        console.log("\n2. Deploying MultiSigViewFacet...");
        MultiSigViewFacet viewFacet = new MultiSigViewFacet();
        console.log("   Deployed at:", address(viewFacet));

        console.log("\n3. Deploying MultiSigInit...");
        MultiSigInit initContract = new MultiSigInit();
        console.log("   Deployed at:", address(initContract));

        // 2. Prepare diamondCut
        console.log("\n4. Preparing diamondCut...");
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        // Management facet selectors
        bytes4[] memory managementSelectors = new bytes4[](4);
        managementSelectors[0] = bytes4(keccak256("submitTransaction(address,uint256,bytes)"));
        managementSelectors[1] = bytes4(keccak256("confirmTransaction(uint256)"));
        managementSelectors[2] = bytes4(keccak256("revokeConfirmation(uint256)"));
        managementSelectors[3] = bytes4(keccak256("executeTransaction(uint256)"));

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(managementFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: managementSelectors
        });

        // View facet selectors
        bytes4[] memory viewSelectors = new bytes4[](10);
        viewSelectors[0] = bytes4(keccak256("getOwners()"));
        viewSelectors[1] = bytes4(keccak256("isOwner(address)"));
        viewSelectors[2] = bytes4(keccak256("requiredConfirmations()"));
        viewSelectors[3] = bytes4(keccak256("getTransactionCount()"));
        viewSelectors[4] = bytes4(keccak256("getTransaction(uint256)"));
        viewSelectors[5] = bytes4(keccak256("isConfirmedBy(uint256,address)"));
        viewSelectors[6] = bytes4(keccak256("getConfirmationCount(uint256)"));
        viewSelectors[7] = bytes4(keccak256("getBalance()"));
        viewSelectors[8] = bytes4(keccak256("getTransactionsBatch(uint256,uint256)"));
        viewSelectors[9] = bytes4(keccak256("getPendingTransactions()"));

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(viewFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: viewSelectors
        });

        // 3. Prepare init call data
        bytes memory initCalldata = abi.encodeWithSelector(
            MultiSigInit.init.selector,
            owners,
            requiredConfirmations
        );

        // 4. Execute diamondCut
        console.log("\n5. Executing diamondCut...");
        IDiamondCut(diamond).diamondCut(cut, address(initContract), initCalldata);

        vm.stopBroadcast();

        // 5. Verification output
        console.log("\n");
        console.log("===================================================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("===================================================================");
        console.log("Diamond Address:           ", diamond);
        console.log("MultiSigManagementFacet:   ", address(managementFacet));
        console.log("MultiSigViewFacet:         ", address(viewFacet));
        console.log("MultiSigInit:              ", address(initContract));
        console.log("");
        console.log("Configuration:");
        console.log("  Owners:                  ", owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            console.log("    Owner", i + 1, ":", owners[i]);
        }
        console.log("  Required Confirmations:  ", requiredConfirmations);
        console.log("=====================================================================");
    }

    /**
     * @dev Parse comma-separated addresses from string
     * @param addressesStr Comma-separated addresses (no spaces)
     * Example: "0x123...,0x456...,0x789..."
     */
    function parseAddresses(string memory addressesStr) internal pure returns (address[] memory) {
        bytes memory strBytes = bytes(addressesStr);
        
        // Count commas to determine array size
        uint256 count = 1;
        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == ",") count++;
        }
        
        address[] memory addresses = new address[](count);
        uint256 index = 0;
        uint256 start = 0;
        
        for (uint256 i = 0; i <= strBytes.length; i++) {
            if (i == strBytes.length || strBytes[i] == ",") {
                // Extract substring
                bytes memory addrBytes = new bytes(i - start);
                for (uint256 j = 0; j < i - start; j++) {
                    addrBytes[j] = strBytes[start + j];
                }
                
                // Convert to address
                addresses[index] = parseAddress(string(addrBytes));
                index++;
                start = i + 1;
            }
        }
        
        return addresses;
    }

    /**
     * @dev Parse single address from string
     */
    function parseAddress(string memory addr) internal pure returns (address) {
        bytes memory addrBytes = bytes(addr);
        require(addrBytes.length == 42, "Invalid address length");
        require(addrBytes[0] == "0" && addrBytes[1] == "x", "Address must start with 0x");
        
        uint160 result = 0;
        for (uint256 i = 2; i < 42; i++) {
            uint8 digit = uint8(addrBytes[i]);
            uint8 value;
            
            if (digit >= 48 && digit <= 57) {
                value = digit - 48; // 0-9
            } else if (digit >= 65 && digit <= 70) {
                value = digit - 55; // A-F
            } else if (digit >= 97 && digit <= 102) {
                value = digit - 87; // a-f
            } else {
                revert("Invalid hex character");
            }
            
            result = result * 16 + value;
        }
        
        return address(result);
    }

    /**
     * @dev Repeat a string n times (helper for console output)
     */
    function repeat(string memory str, uint256 n) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(strBytes.length * n);
        
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = 0; j < strBytes.length; j++) {
                result[i * strBytes.length + j] = strBytes[j];
            }
        }
        
        return string(result);
    }
}