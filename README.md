# ZK-MailProof

**ZK-MailProof** è un protocollo di attestazione di identità decentralizzata e anonima. Permette a un utente di dimostrare on-chain il possesso di un indirizzo email appartenente a un dominio specifico (es. `@gmail.com`) senza mai rivelare l'indirizzo email reale, sfruttando le firme **DKIM** e le prove a conoscenza zero (**ZK-SNARKs**).
Il progetto è distribuito sulla rete di test **Scroll Sepolia L2**.

## Requisiti Hardware
Il circuito crittografico genera circa **871.000 vincoli**. Per evitare errori di memoria (`Out of Bounds`) su macchine con 8GB di RAM:
- **WSL2**: È caldamente consigliato l'uso di Linux/WSL2.
- **Swap**: Assicurati di aver configurato almeno **24GB di file Swap**.
- **Node.js**: Esegui gli script aumentando l'allocazione della memoria
### Nota sui file Crittografici 
Per ragioni di spazio, i file .zkey e .ptau non sono inclusi nella repository. Per eseguire lo script di automazione è necessario:
1. Compilare il circuito .circom:
   cd circuits
   circom circuits/wallet_verifier.circom --r1cs --wasm --sym --output ./circuits/build -l node_modules
2. Spostati nella cartella dei build: cd circuits/build
3. Download del file Powers of Tau: wget https://storage.googleapis.com/zkevm/ptau/powersOfTau28_hez_final_20.ptau
4. Generazione della Proving Key: dato che il circuito conta circa 871.102 vincoli, la generazione della .zkey richiede molta RAM. Utilizziamo lo Swap di sistema e aumentiamo il limite di memoria di Node.js per evitare crash:
   node --max-old-space-size=12288 $(which snarkjs) groth16 setup ../wallet_verifier.r1cs powersOfTau28_hez_final_20.ptau wallet_verifier_final.zkey
5. Esportazione della Verification Key: snarkjs zkey export verificationkey wallet_verifier_final.zkey verification_key.json

## Setup del Progetto

### 1. Configurazione Variabili d'Ambiente
Per motivi di sicurezza, il file `.env` non è incluso nella repository. Crea un file chiamato `.env` all'interno della cartella `contracts/` e inserisci i seguenti parametri:

```env
PRIVATE_KEY=IL_TUO_PRIVATE_KEY_0x... (Chiave privata del tuo wallet)
RPC_URL=https://sepolia-rpc.scroll.io
CONTRACT_ADDRESS=0xE8A9D15914BF2E4A17a5508b89A2CcF4b25D0244 (indirizzo Smart Contract deployato on-chain)
```

### 2. Preparazione del file mail
Il protocollo richiede un'email reale per estrarre la firma DKIM.

1. Scarica un'email (es. da Gmail) in formato .eml (pulsante "Scarica messaggio").

2. Rinomina il file in email.eml.

3. Inserisci il file nella cartella emails del progetto.

### 3. Installazione Dipendenze
Entra nella cartella degli script e installa i moduli necessari:

cd scripts
npm install

### 4. Esecuzione automatizzata

Una volta configurato il file .env e inserita l'email, puoi avviare l'intera pipeline (Generazione Witness -> Generazione Prova ZK -> Transazione su Scroll) con un unico comando.
Dalla cartella principale, esegui:

cd scripts
node --max-old-space-size=12288 automation_script.js

Lo script si occuperà di:

1. Leggere e analizzare email.eml.

2. Generare gli input per il circuito Circom.

3. Calcolare il Witness e la Prova Groth16 (sfruttando la CLI per ottimizzare la RAM).

4. Inviare la prova allo Smart Contract su Scroll Sepolia.

## Struttura della repository
```
zk-mailproof/
├── circuits/       # File .circom (Logica ZK)
├── contracts/      # Smart Contracts Solidity (Foundry)
├── scripts/        # Script JS per generare le prove
└── emails/         # Esempi di file .eml per i test
```
