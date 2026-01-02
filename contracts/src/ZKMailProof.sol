// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Verifier.sol";

contract ZKMailProof {
    Groth16Verifier public immutable verifier;
    
    // Variabile di stato per il proprietario
    address public owner;

    mapping(bytes32 => bool) public authorizedProviders;
    mapping(bytes32 => bool) public usedNullifiers;

    // Definizione del modificatore di accesso
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view{
        require(msg.sender == owner, "Accesso negato: non sei il proprietario");
    }

    // Costruttore
    constructor(address _verifierAddress) {
        verifier = Groth16Verifier(_verifierAddress);
        owner = msg.sender; // Chi esegue il deploy diventa il proprietario
    }

    // Applicazione del modificatore alla funzione di governance
    function addProvider(bytes32 _pubkeyHash) external onlyOwner {
        authorizedProviders[_pubkeyHash] = true;
    }

    // Funzione opzionale per cambiare proprietario (best practice)
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Nuovo proprietario non valido");
        owner = _newOwner;
    }

    function verifyEmailPresence(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) public {
        bytes32 nullifier = bytes32(input[0]);
        bytes32 providerHash = bytes32(input[1]);

        require(authorizedProviders[providerHash], "Provider email non autorizzato");
        require(!usedNullifiers[nullifier], "Prova gia' utilizzata");
        require(verifier.verifyProof(a, b, c, input), "Matematica della prova non valida");

        usedNullifiers[nullifier] = true;
    }
}