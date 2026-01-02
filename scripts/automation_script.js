const { execSync } = require('child_process');
const { ethers } = require("ethers");
const { generateEmailVerifierInputs } = require("@zk-email/helpers");
const fs = require("fs");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, '../contracts/.env') });

async function run() {

    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    const contractAddress = process.env.CONTRACT_ADDRESS;
    const contract = new ethers.Contract(contractAddress, 
        ["function verifyEmailPresence(uint256[2] a, uint256[2][2] b, uint256[2] c, uint256[2] publicSignals) public"], wallet);

    console.log("1. Elaborazione Email...");
    const rawEmail = fs.readFileSync(path.join(__dirname, "../emails/email.eml"), "utf8");
    const inputs = await generateEmailVerifierInputs(rawEmail, {
        maxHeaderLength: 1024, maxBodyLength: 0, n: 121, k: 17, ignoreBody: true
    });

    // Salviamo temporaneamente l'input per la CLI
    const inputPath = path.resolve(__dirname, "../circuits/build/input.json");
    fs.writeFileSync(inputPath, JSON.stringify({
        "email_header": inputs.emailHeader,
        "email_header_len": inputs.emailHeaderLength,
        "pubkey": inputs.pubkey,
        "signature": inputs.signature
    }, (k, v) => typeof v === 'bigint' ? v.toString() : v));

    console.log("2. Generazione Prova ZK tramite CLI (Ottimizzazione RAM)...");
    
    const buildDir = path.resolve(__dirname, "../circuits/build");
    try {
        // Generazione Witness
        execSync(`node ${buildDir}/wallet_verifier_js/generate_witness.js ${buildDir}/wallet_verifier_js/wallet_verifier.wasm ${inputPath} ${buildDir}/witness.wtns`, { stdio: 'inherit' });
        
        // Generazione Prova 
        execSync(`snarkjs groth16 prove ${buildDir}/wallet_verifier_final.zkey ${buildDir}/witness.wtns ${buildDir}/proof.json ${buildDir}/public.json`, { stdio: 'inherit' });
        
        console.log("Prova generata via CLI.");
    } catch (e) {
        throw new Error("Fallimento durante il proving CLI.");
    }

    // 3. Lettura file generati per l'invio on-chain
    const proof = JSON.parse(fs.readFileSync(`${buildDir}/proof.json`));
    const publicSignals = JSON.parse(fs.readFileSync(`${buildDir}/public.json`));

    // Formattazione e Swap G2 
    const pA = [proof.pi_a[0], proof.pi_a[1]];
    const pB = [
        [proof.pi_b[0][1], proof.pi_b[0][0]], 
        [proof.pi_b[1][1], proof.pi_b[1][0]]
    ];
    const pC = [proof.pi_c[0], proof.pi_c[1]];

    console.log("4. Invio a Scroll Sepolia...");
    const tx = await contract.verifyEmailPresence(pA, pB, pC, publicSignals);
    console.log(`Successo! Hash: ${tx.hash}`);
}

run().catch(console.error);