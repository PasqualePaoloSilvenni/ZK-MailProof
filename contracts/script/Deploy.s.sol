// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/ZKMailProof.sol";
import "../src/Verifier.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy del Verifier 
        Groth16Verifier verifier = new Groth16Verifier();
        
        // 2. Deploy di ZKMailProof 
        ZKMailProof mailProof = new ZKMailProof(address(verifier));

        vm.stopBroadcast();
    }
}