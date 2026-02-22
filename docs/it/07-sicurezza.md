# Politica di Sicurezza

## 🛡️ Standard di Sicurezza
NeoTradingBot 1777 è progettato con la sicurezza come priorità assoluta. In produzione, ogni canale di comunicazione è protetto via TLS con certificate pinning per prevenire attacchi Man-In-The-Middle (MITM).

## 🔒 Segnalazione di una Vulnerabilità

Se scopri una vulnerabilità di sicurezza in questo progetto, **NON** aprire una issue pubblica. Invece, segnalala tramite uno dei seguenti metodi:

1. **Email**: [security@neotradingbot.com](mailto:security@neotradingbot.com) (Segnaposto)
2. **Messaggio Privato**: Contatta direttamente i manutentori principali.

Includi:
- Una descrizione della vulnerabilità.
- Un proof of concept (PoC) se disponibile.
- L'impatto potenziale.

Confermeremo la ricezione della segnalazione entro 48 ore e forniremo una stima dei tempi per la risoluzione.

## 🛠️ Blindatura della Sicurezza

- **gRPC TLS**: Il backend è impostato su `STRICT_BOOT=true` di default, il che significa che non si avvierà senza certificati TLS validi. Questo previene l'avvio accidentale in modalità non sicura in produzione.
- **Certificate Pinning**: Il frontend Flutter verifica l'identità del server utilizzando una chiave pubblica "pinnata" (`server.crt`).
- **Autenticazione gRPC**: L'API Key per le chiamate gRPC viene caricata in modo sicuro tramite il singleton `EnvConfig`. Questo garantisce che le configurazioni fornite tramite file `.env` siano caricate correttamente, prevenendo bypass accidentali dell'autenticazione.
- **Gestione dei Segreti**: Tutte le chiavi API e i segreti devono essere conservati in variabili d'ambiente o in un vault sicuro. Non committare mai i file `.env`.
- **Audit delle Dipendenze**: Eseguiamo audit regolari delle dipendenze Dart e Flutter. Eseguiamo periodicamente sessioni di revisione del codice tramite Kilo AI per identificare vulnerabilità proattivamente.

## 💾 Privacy dei Dati
Il bot comunica esclusivamente con:
- API di Binance (Trading)
- API di Telegram (Notifiche Opzionali)
- Il tuo Client (via gRPC)

Nessun dato viene inviato a server di monitoraggio esterni, a meno che non sia esplicitamente configurato dall'utente.

