// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {CXIIIWK13Token} from "../src/CXIIIWK13Token.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployCXIIIWK13Token is Script {
    function run() external {
    address owner = vm.envAddress("OWNER_ADDRESS");
    string memory tokenName = vm.envString("TOKEN_NAME");
    string memory tokenSymbol = vm.envString("TOKEN_SYMBOL");

    require(owner != address(0), "OWNER_ADDRESS must be set");
    require(bytes(tokenName).length != 0, "TOKEN_NAME must be set");
    require(bytes(tokenSymbol).length != 0, "TOKEN_SYMBOL must be set");

    vm.startBroadcast();

    address proxy = Upgrades.deployUUPSProxy(
        "CXIIIWK13Token.sol",
        abi.encodeCall(CXIIIWK13Token.initialize, (owner, tokenName, tokenSymbol))
    );

    vm.stopBroadcast();
    address implementation = Upgrades.getImplementationAddress(proxy);
    console.log("Deployed UUPS proxy:", proxy);
    console.log("Implementation:", implementation);
}

}
