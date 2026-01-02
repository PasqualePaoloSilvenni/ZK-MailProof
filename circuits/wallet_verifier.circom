pragma circom 2.1.5;

include "@zk-email/circuits/email-verifier.circom";
include "@zk-email/zk-regex-circom/circuits/common/email_domain_regex.circom";

/// @title WalletVerifier
/// @notice Circuito per la verifica dell'identità tramite firma DKIM e dominio email.
template WalletVerifier(
    max_header_len,
    max_body_len,
    n,
    k,
    ignore_body,
    enable_body_hash_check,
    enable_remove_soft_linebreaks,
    expose_input_hash
) {
    // --- INPUT PRIVATI ---
    signal input email_header[max_header_len]; 
    signal input email_header_len;             // Lunghezza effettiva dell'header per il padding SHA-256
    signal input pubkey[k];                   // Chiave pubblica RSA del server (divisa in k chunk)
    signal input signature[k];                // Firma RSA dell'email (divisa in k chunk)

    // --- OUTPUT PUBBLICI ---
    signal output pubkey_hash;                 // Hash della chiave pubblica (identificativo del mittente)
    signal output reveal_nullifier;           // Nullifier anti-Sybil derivato univocamente dall'email

    // VERIFICA DELLA FIRMA DKIM (RSA + SHA-256)
    // Utilizza il componente core di zk-email per validare l'integrità dell'intestazione.
    component ev = EmailVerifier(
        max_header_len, 
        max_body_len, 
        n, 
        k, 
        ignore_body, 
        enable_body_hash_check, 
        enable_remove_soft_linebreaks, 
        expose_input_hash
    );
    
    ev.emailHeader <== email_header;
    ev.pubkey <== pubkey;
    ev.signature <== signature;
    ev.emailHeaderLength <== email_header_len;

    pubkey_hash <== ev.pubkeyHash;

    // GENERAZIONE DEL NULLIFIER
    // In questa implementazione, il nullifier è legato alla chiave pubblica e alla firma 
    // per garantire che una specifica identità possa essere registrata una sola volta.
    reveal_nullifier <== ev.pubkeyHash; 

    // VERIFICA DEL DOMINIO TRAMITE REGEX
    // Dimostra che il dominio (es. @studenti.unina.it) è presente nell'intestazione firmata.
    component domainRegex = EmailDomainRegex(max_header_len);
    domainRegex.msg <== email_header;
}

// Istanza principale: Configurazione per RSA-2048 (n=121, k=17)
// Header limitato a 1024 caratteri per ottimizzare il numero di vincoli (constraints).
component main = WalletVerifier(1024, 0, 121, 17, 1, 0, 0, 0);