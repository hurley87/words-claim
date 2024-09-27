//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/FunToken.sol";
import "forge-std/Script.sol";

contract DeployFunToken is Script {
    address constant _TOKEN_OWNER_ADDRESS = address(0x1169E27981BceEd47E590bB9E327b26529962bAe);

    function run() public {
        // Use address provided in config to broadcast transactions
        vm.startBroadcast();

        // Deploy the ERC-20 token
        FunToken implementation = new FunToken(_TOKEN_OWNER_ADDRESS);
        // Stop broadcasting calls from our address
        vm.stopBroadcast();
        // Log the token address
        console.log("Token Implementation Address:", address(implementation));
    }
}
