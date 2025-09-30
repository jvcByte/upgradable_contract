// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facet/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facet/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facet/OwnershipFacet.sol";
import {ERC20Facet} from "../src/facet/ERC20Facet.sol";
import {DiamondInit} from "../src/upgrade_initializers/DiamondInit.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";

contract DeployDiamond is Script {
    function run() external {
        address owner = vm.envAddress("OWNER_ADDRESS");
        string memory name_ = vm.envString("TOKEN_NAME");
        string memory symbol_ = vm.envString("TOKEN_SYMBOL");
        uint256 initialSupply = vm.envOr("INITIAL_SUPPLY_WEI", uint256(0));
        address initialTo = vm.envOr("INITIAL_TO", owner);

        require(owner != address(0), "OWNER_ADDRESS must be set");
        require(bytes(name_).length != 0, "TOKEN_NAME must be set");
        require(bytes(symbol_).length != 0, "TOKEN_SYMBOL must be set");

        // Broadcast from owner if OWNER_PRIVATE_KEY is provided; otherwise use default sender
        uint256 ownerPk = vm.envOr("OWNER_PRIVATE_KEY", uint256(0));
        if (ownerPk != 0) {
            vm.startBroadcast(ownerPk);
        } else {
            vm.startBroadcast();
        }

        // deploy diamond core and facets
        DiamondCutFacet cutFacet = new DiamondCutFacet();
        Diamond diamond = new Diamond(owner, address(cutFacet));
        DiamondLoupeFacet loupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        ERC20Facet erc20Facet = new ERC20Facet();
        DiamondInit init = new DiamondInit();

        // build cut (exclude diamondCut selector, already seeded in constructor)
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);

        // DiamondLoupeFacet selectors
        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = bytes4(keccak256("facets()"));
        loupeSelectors[1] = bytes4(keccak256("facetFunctionSelectors(address)"));
        loupeSelectors[2] = bytes4(keccak256("facetAddresses()"));
        loupeSelectors[3] = bytes4(keccak256("facetAddress(bytes4)"));
        cut[0] = IDiamondCut.FacetCut({ facetAddress: address(loupeFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: loupeSelectors });

        // OwnershipFacet selectors
        bytes4[] memory ownSelectors = new bytes4[](2);
        ownSelectors[0] = bytes4(keccak256("transferOwnership(address)"));
        ownSelectors[1] = bytes4(keccak256("owner()"));
        cut[1] = IDiamondCut.FacetCut({ facetAddress: address(ownershipFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: ownSelectors });

        // ERC20Facet selectors
        bytes4[] memory erc20Selectors = new bytes4[](7);
        erc20Selectors[0] = bytes4(keccak256("name()"));
        erc20Selectors[1] = bytes4(keccak256("symbol()"));
        erc20Selectors[2] = bytes4(keccak256("decimals()"));
        erc20Selectors[3] = bytes4(keccak256("totalSupply()"));
        erc20Selectors[4] = bytes4(keccak256("balanceOf(address)"));
        erc20Selectors[5] = bytes4(keccak256("transfer(address,uint256)"));
        erc20Selectors[6] = bytes4(keccak256("approve(address,uint256)"));
        // Note: transferFrom included via approve/allowance path; add allowance and transferFrom selectors too
        bytes4[] memory erc20More = new bytes4[](2);
        erc20More[0] = bytes4(keccak256("allowance(address,address)"));
        erc20More[1] = bytes4(keccak256("transferFrom(address,address,uint256)"));

        // Extend erc20Selectors to include the extra two
        bytes4[] memory erc20All = new bytes4[](erc20Selectors.length + erc20More.length);
        for (uint i = 0; i < erc20Selectors.length; i++) erc20All[i] = erc20Selectors[i];
        for (uint j = 0; j < erc20More.length; j++) erc20All[erc20Selectors.length + j] = erc20More[j];

        cut[2] = IDiamondCut.FacetCut({ facetAddress: address(erc20Facet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: erc20All });

        // execute initial diamond cut with initializer
        IDiamondCut(address(diamond)).diamondCut(
            cut,
            address(init),
            abi.encodeWithSelector(DiamondInit.init.selector, name_, symbol_, owner, initialSupply, initialTo)
        );

        vm.stopBroadcast();

        console.log("Diamond deployed:", address(diamond));
    }
}


