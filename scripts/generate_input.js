const { generateEmailVerifierInputs } = require("@zk-email/helpers");
const fs = require("fs");
const path = require("path");

async function run() {
  // 1. Carica l'email reale
  const rawEmail = fs.readFileSync(path.join(__dirname, "../emails/test.eml"), "utf8");
  
  // 2. Genera gli input grezzi usando l'helper di zk-email
  const inputs = await generateEmailVerifierInputs(rawEmail, {
    maxHeaderLength: 1024,
    maxBodyLength: 64000,
    n: 121,
    k: 17,
    ignoreBody: true
    });
  // 3. MAPPATURA PRECISA 
  // A sinistra: il nome del segnale nel tuo file .circom
  // A destra: il valore estratto dall'helper
  const circuitInputs = {
    "email_header": inputs.emailHeader,
    "email_header_len": inputs.emailHeaderLength, // Mappato su email_header_len
    "pubkey": inputs.pubkey,
    "signature": inputs.signature,
  };

  // 4. Salvataggio su file
  // Usiamo un replacer per gestire i numeri grandi (BigInt) trasformandoli in stringhe
  const outputPath = path.join(__dirname, "../circuits/build/input.json");
  fs.writeFileSync(
    outputPath,
    JSON.stringify(circuitInputs, (key, value) =>
      typeof value === "bigint" ? value.toString() : value
    , 2)
  );

  console.log(`File input.json generato correttamente in: ${outputPath}`);
}

run().catch((err) => {
    console.error("Errore durante la generazione degli input:");
    console.error(err);
});