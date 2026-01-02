// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ZKMailProof.sol";
import "../src/Verifier.sol";

contract ZKMailProofTest is Test {
    ZKMailProof public mailProof;
    Groth16Verifier public verifier;

    function setUp() public {
        verifier = new Groth16Verifier();
        mailProof = new ZKMailProof(address(verifier));
        
        // --- CONFIGURAZIONE REALE ---
        // 1. Prendi il secondo valore da public.json (l'hash del provider)
        uint256 providerHash = 0x...; // INCOLLA QUI (formato 0x...)
        mailProof.addProvider(bytes32(providerHash));
    }

    function testCompleteProof() public {
        // --- DATI DA proof.json ---
        uint256[2] memory a = [
            uint256(0x...), // pi_a[0]
            uint256(0x...)  // pi_a[1]
        ];

        uint256[2][2] memory b = [
            [
                uint256(0x...), // pi_b[0][1],
                uint256(0x...)  // pi_b[0][0]
            ], 
            [
                uint256(0x...), // pi_b[1][1]
                uint256(0x...)  // pi_b[1][0]
                ]  
        ];

        uint256[2] memory c = [
            uint256(0x...), // pi_c[0]
            uint256(0x...)  // pi_c[1]
        ];

        // --- DATI DA public.json ---
        uint256[2] memory input = [
            uint256(0x...), // Nullifier (public.json[0])
            uint256(0x...)  // Provider Hash (public.json[1])
        ];

        // ESECUZIONE VERIFICA
        vm.prank(address(0x123)); // Simula un utente qualsiasi
        mailProof.verifyEmailPresence(a, b, c, input);

        // Se arriviamo qui senza revert, il test è passato!
        assertTrue(mailProof.usedNullifiers(bytes32(input[0])));
    }
}