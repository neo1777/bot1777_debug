# Guida alla Risoluzione dei Problemi (Troubleshooting)

Questo documento elenca i problemi comuni e le relative soluzioni.

## 🛠️ Problemi di gRPC e Connettività

### ❌ Errore: `HandshakeException: Handshake error in client`
- **Causa**: Il client (Frontend) non si fida del certificato del server.
- **Soluzione**:
  1. Assicurati di aver eseguito `./scripts/generate_certs.sh` con l'IP corretto.
  2. Copia `certs/server.crt` in `neotradingbotfront1777/assets/certs/server.crt`.
  3. Riavvia l'applicazione frontend.

### ❌ Errore: `Connection refused` (Porta 50051)
- **Causa**: Il backend non è attivo o un firewall sta bloccando la porta.
- **Soluzione**:
  1. Verifica se il backend è attivo: `docker ps`.
  2. Assicurati che la porta 50051 sia aperta nel firewall del tuo provider cloud.
  3. Verifica che `GRPC_HOST` nel file `.env` sia impostato su `0.0.0.0` per permettere connessioni esterne.

### ❌ Errore: `Deadline exceeded`
- **Causa**: La latenza di rete è troppo alta o il server è sovraccarico.
- **Soluzione**:
  1. Controlla le risorse del server (`top` o `htop`).
  2. Verifica la tua connessione di rete.

## 💰 Problemi API Binance

### ❌ Errore: `API-key format invalid`
- **Causa**: La API Key nel file `.env` è errata o contiene spazi.
- **Soluzione**: Ricontrolla la `API_KEY` in `neotradingbotback1777/.env`.

### ❌ Errore: `Timestamp for this request is outside of the recvWindow`
- **Causa**: L'orologio del tuo sistema non è sincronizzato con i server di Binance.
- **Soluzione**:
  1. Sincronizza l'orario del server: `ntpdate -u pool.ntp.org`.
  2. Oppure aumenta `BINANCE_RECV_WINDOW_MS` nel tuo `.env` (Massimo 60000).

## 🐳 Problemi Docker

### ❌ Errore: `Bind for 0.0.0.0:50051 failed: port is already allocated`
- **Causa**: Un altro processo sta usando la porta 50051.
- **Soluzione**: Identifica il processo con `sudo lsof -i :50051` e Terminalo.

### ❌ Errore: `Execution failed (Exit code 1)` sul Backend
- **Causa**: Spesso dovuto a variabili d'ambiente mancanti o certificati non validi.
- **Soluzione**: Controlla i log: `docker logs botbinance-backend`. Se usi la build AOT, prova a eseguire in modalità JIT (`dart run lib/main.dart`) per vedere messaggi di errore più dettagliati.
