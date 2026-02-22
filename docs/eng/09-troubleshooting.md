# Troubleshooting Guide

This document lists common issues and their solutions.

## 🛠️ gRPC & Connectivity Issues

### ❌ Error: `HandshakeException: Handshake error in client`
- **Cause**: The client (Frontend) does not trust the server's certificate.
- **Solution**:
  1. Ensure you have run `./scripts/generate_certs.sh` with the correct IP.
  2. Copy `certs/server.crt` to `neotradingbotfront1777/assets/certs/server.crt`.
  3. Rebuild/Restart the frontend app.

### ❌ Error: `Connection refused` (Port 50051)
- **Cause**: The backend is not running or a firewall is blocking the port.
- **Solution**:
  1. Check if the backend is up: `docker ps`.
  2. Ensure port 50051 is open in your cloud provider firewall (e.g., AWS Security Groups, DigitalOcean Firewalls).
  3. Verify `GRPC_HOST` in `.env` is set to `0.0.0.0` to allow external connections.

### ❌ Error: `Deadline exceeded`
- **Cause**: Network latency is too high or the server is overloaded.
- **Solution**:
  1. Check the server resources (`top` or `htop`).
  2. Check your network connection.

## 💰 Binance API Issues

### ❌ Error: `API-key format invalid`
- **Cause**: The API Key in your `.env` is incorrect or contains spaces.
- **Solution**: Double-check the `API_KEY` in `neotradingbotback1777/.env`.

### ❌ Error: `Timestamp for this request is outside of the recvWindow`
- **Cause**: Your system clock is out of sync with Binance servers.
- **Solution**:
  1. Synchronize your server time: `ntpdate -u pool.ntp.org`.
  2. Or increase `BINANCE_RECV_WINDOW_MS` in your `.env` (Max 60000).

## 🐳 Docker Issues

### ❌ Error: `Bind for 0.0.0.0:50051 failed: port is already allocated`
- **Cause**: Another process is using port 50051.
- **Solution**: Identify the process using `sudo lsof -i :50051` and stop it.

### ❌ Error: `Execution failed (Exit code 1)` on Backend
- **Cause**: Often due to missing environment variables or invalid certificates.
- **Solution**: Check the logs: `docker logs botbinance-backend`. If using AOT build, try running in JIT mode (`dart run lib/main.dart`) to see detailed error messages.

