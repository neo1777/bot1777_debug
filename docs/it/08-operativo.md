# Guida Operativa — NeoTradingBot 1777

## Risposta agli Incidenti

### Scenario 1: Backend Crash / Non Risponde

**Sintomi**: Dashboard disconnessa, log si fermano.

```bash
# 1. Controlla stato container
docker ps -a

# 2. Leggi i log
docker logs botbinance-backend --tail 100

# 3. Riavvia il servizio
./scripts/deploy.sh remote   # Deploy completo su VPS
# oppure
docker compose restart bot-backend
```

### Scenario 2: Rate Limit API Binance (HTTP 429)

**Sintomi**: Log mostrano "Way too many requests" o HTTP 429.

1. Il sistema ha backoff integrato — attendi 5-10 minuti
2. Se persiste, ferma il bot: `docker compose stop bot-backend`
3. In `neotradingbotback1777/.env` aumenta `BINANCE_RATE_LIMIT_BUFFER`

### Scenario 3: Frontend Disconnesso (gRPC)

1. Verifica status dalla pagina `/diagnostics/tls`
2. Controlla che il backend sia attivo: `docker ps`
3. Verifica che host/porta in `.env.frontend` corrispondano
4. Controlla il certificato TLS in `neotradingbotfront1777/assets/certs/`

## Manutenzione

### Aggiornamento dell'Applicazione

```bash
# 1. Scarica il codice più recente
git pull origin main

# 2. Rigenera proto se modificati
./generate_proto.sh

# 3. Deploy
./scripts/deploy.sh remote
```

### Deploy Remoto (VPS)

1. Configura `scripts/.env.deploy` (usa `.env.deploy.example`):
   ```
   VPS_IP=x.x.x.x
   VPS_USER=root
   VPS_PASS=la_tua_password
   ```
2. Esegui: `./scripts/deploy.sh remote`

Lo script si occupa di archiviare, trasferire e ricostruire i container Docker.

### Setup Manuale Docker (Locale)

```bash
docker compose up --build -d
```

### Gestione dei Log

- **Log Interni**: Backend invia log via gRPC alla dashboard (`/system-logs`)
- **Log Docker**: `docker logs botbinance-backend`
- **Livello Log**: Configurabile live dalla UI in `/log-settings`

## Backup e Disaster Recovery

### Valutazione dei Rischi

| Rischio | Impatto | Probabilità | Mitigazione |
| :--- | :--- | :--- | :--- |
| Crash Server | Alto | Bassa | Riavvio automatico Docker / Isolate |
| Corruzione Dati | Critico | Bassa | Scritture atomiche + Backup |
| Interruzione API Binance | Alto | Media | Circuit Breaker + Backoff |

### Backup dello Stato (RPO: 24h)

Lo stato critico è in `./hive_data` (database Hive).

```bash
# 1. Ferma il bot
docker compose stop bot-backend

# 2. Backup dei dati
cp -r ./hive_data ./backup_$(date +%Y%m%d)

# 3. Riavvia
docker compose start bot-backend
```

**Strategia**: Backup automatizzato giornaliero su storage esterno (S3 o volume separato). Conserva gli ultimi 7 backup.

### Ripristino del Servizio (RTO: < 15 min)

1. Ferma il bot
2. Sostituisci `./hive_data` con il contenuto del backup
3. Verifica che il file `.env` sia presente e corretto
4. Riavvia: `docker compose up -d`
5. Verifica connessione dalla pagina `/diagnostics/tls`

### Simulazioni DR (Quarterly)

Ogni 3 mesi:
1. Avvia un nuovo VPS
2. Deploy con `./scripts/deploy.sh` e dati di backup
3. Verifica ripristino corretto dello stato trading
