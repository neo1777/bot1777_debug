# Operational Runbook: NeoTradingBot1777

This document outlines the standard operating procedures for maintaining and recovering the NeoTradingBot1777 system.

## 🚨 Incident Response

### Scenario 1: Backend or Proxy Crash
**Symptoms**: Dashboard disconnected, logs stopped.
**Procedure**:
1. Check container status: `docker ps -a`
2. Check logs: 
   - Backend: `docker logs botbinance-backend --tail 100`
   - Proxy: `docker logs envoy-proxy --tail 100`
3. Restart services:
   ```bash
   ./scripts/deploy.sh remote  # For VPS (Recommended)
   # OR
   docker compose restart bot-backend envoy-proxy
   ```

### Scenario 2: API Rate Limits (429)
**Symptoms**: Logs show "Way too many requests" or HTTP 429.
**Procedure**:
1. The system has built-in backoff. Wait for 5-10 minutes.
2. If persistent, stop the bot: `docker compose stop bot-backend`
3. Check `neotradingbotback1777/.env` and increase `BINANCE_RATE_LIMIT_BUFFER`.

## 🧹 Maintenance

### Updating the Application
1. Pull latest code: `git pull origin main`
2. Run deployment script: `./scripts/deploy.sh remote`
   *This will rebuild the Docker image and restart the container.*

### Remote Deployment (VPS)
To deploy from your local machine to a remote VPS:
1. Create `scripts/.env.deploy` (using `.env.deploy.example`) with:
   ```bash
   VPS_IP=x.x.x.x
   VPS_USER=root
   VPS_PASS=your_password
   ```
2. Run `./scripts/deploy.sh remote`.

### Log Rotation
*Logs are currently emitted by Docker or handled by the internal Logging Service.*
- **Internal Logs**: The backend streams logs via gRPC.
- **Docker Logs**: Controlled by Docker engine. Use `docker logs botbinance-backend`.

## 🌪️ Disaster Recovery

### Data Backup
The critical state is stored in `./hive_data` (Hive database).
**Backup Procedure**:
1. Stop the bot: `docker compose stop bot-backend`
2. Copy the data folder: `cp -r ./hive_data ./backup_$(date +%Y%m%d)`
3. Restart: `docker compose start bot-backend`

### Restore Procedure
1. Stop the bot.
2. Replace `./hive_data` with backup content.
3. Restart the bot.

---

# Disaster Recovery Plan: NeoTradingBot1777

## 1. Objective
To ensure business continuity and minimize data loss in the event of catastrophic failure.

## 2. Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|---------|------------|------------|
| Server Crash | High | Low | Auto-restart (Docker/Isolates) |
| Data Corruption | Critical | Low | Atomic writes + Backup |
| API Outage (Binance) | High | Medium | Circuit Breaker + Backoff |

## 3. Recovery Strategies

### 3.1 Data Backup (RPO: 24h)
- **Primary**: Local Hive database files (`.hive` files).
- **Strategy**: Daily automated backup of the `./data` directory to external storage (e.g., AWS S3 or separate volume).
- **Retention**: Keep last 7 daily backups.

### 3.2 Service Restoration (RTO: < 15min)
- **Containerized**: Re-deploy using `deploy.sh` on any Docker-capable host.
- **Environment**: Keep a secure off-site copy of `.env`.

## 4. Drills
- **Schedule**: Perform a "Fire Drill" every 3 months.
- **Procedure**:
  1. Spin up a new VPS.
  2. Deploy bot using `deploy.sh` and backup data.
  3. Verify trading state restores correctly.
