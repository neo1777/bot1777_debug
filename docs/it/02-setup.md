# Guida al Setup e all'Installazione

Benvenuto in NeoTradingBot 1777. Questa guida ti aiuterà a configurare il tuo ambiente di sviluppo e di produzione da zero.

## 📋 Prerequisiti

Prima di iniziare, assicurati di avere installato:

- **Dart SDK** (Stable): `v3.0.0+`
- **Flutter SDK**: `v3.10.0+`
- **Docker & Docker Compose**: Per il deploy containerizzato.
- **Compilatore Protobuf (`protoc`)**: Per rigenerare gli stub gRPC.
- **Git**: Per il controllo di versione.

## 🔑 1. Chiavi API Binance

1. Accedi al tuo account Binance.
2. Vai su [Gestione API](https://www.binance.com/en/my/settings/api-management).
3. Crea una nuova chiave API con permessi di **Spot & Margin Trading**.
4. **IMPORTANTE**: Inserisci l'IP del tuo server in whitelist per una sicurezza maggiore.
5. Salva la tua `API_KEY` e la tua `SECRET_KEY`.

## 🔒 2. Configurazione Sicurezza (TLS)

NeoTradingBot utilizza gRPC con TLS obbligatorio. Devi generare i tuoi certificati.

### Locale / Sviluppo
1. Esegui lo script di generazione:
   ```bash
   ./scripts/generate_certs.sh 127.0.0.1
   ```
2. Questo creerà `certs/server.crt` e `certs/server.key`.

### Produzione (VPS)
1. Esegui lo script con l'IP pubblico del tuo VPS:
   ```bash
   ./scripts/generate_certs.sh TUO_IP_VPS
   ```

## 🛠️ 3. Generazione Protobuf

Se modifichi i file `.proto` nella directory `proto/`, devi rigenerare gli stub Dart:

1. Installa il plugin protoc per Dart:
   ```bash
   dart pub global activate protoc_plugin
   ```
2. Esegui lo script di generazione:
   ```bash
   ./scripts/generate_protos.sh
   ```

## 🚀 4. Avvio Locale

### Backend
1. Vai nella directory del backend: `cd neotradingbotback1777`
2. Configura il file `.env` (usa `.env.example` come modello).
3. Avvia il server:
   ```bash
   dart run lib/main.dart
   ```

### Frontend (Dashboard)
1. Vai nella directory del frontend: `cd neotradingbotfront1777`
2. Avvia l'app Flutter:
   ```bash
   flutter run -d chrome # O il tuo dispositivo preferito
   ```

## 🚢 5. Deploy (Docker)

### Deploy Remoto (Consigliato)
1. Configura `scripts/.env.deploy` con i dati del tuo VPS.
2. Esegui lo script di deploy remoto:
   ```bash
   cd scripts
   ./deploy.sh remote
   ```
Questo script si occuperà di archiviare il progetto, trasferirlo sul VPS e orchestrare la ricostruzione dei container Docker.

### Setup Manuale Docker
Se preferisci il controllo manuale:
```bash
docker compose up --build -d
```

## ❓ Risoluzione dei Problemi
- **Errore di Connessione gRPC**: Verifica che l'host e la porta del backend nel frontend corrispondano al tuo ambiente.
- **Fallimento Handshake TLS**: Assicurati che il file `server.crt` in `neotradingbotfront1777/assets/certs/` corrisponda a quello usato dal server.
- **Permesso Negato**: Assicurati che gli script in `scripts/` siano eseguibili: `chmod +x scripts/*.sh`.

