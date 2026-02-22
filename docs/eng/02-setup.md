# Setup & Installation Guide

Welcome to NeoTradingBot 1777. This guide will help you set up your development and production environments from scratch.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Dart SDK** (Stable): `v3.0.0+`
- **Flutter SDK**: `v3.10.0+`
- **Docker & Docker Compose**: For containerized deployment.
- **Protobuf Compiler (`protoc`)**: For regenerating gRPC stubs.
- **Git**: For version control.

## 🔑 1. Binance API Keys

1. Log in to your Binance account.
2. Go to [API Management](https://www.binance.com/en/my/settings/api-management).
3. Create a new API Key with **Enable Spot & Margin Trading** permissions.
4. **IMPORTANT**: Whitelist your VPS IP for enhanced security.
5. Save your `API_KEY` and `SECRET_KEY`.

## 🔒 2. Security Setup (TLS)

NeoTradingBot uses gRPC with mandatory TLS. You must generate your own certificates.

### Local/Development
1. Run the generation script:
   ```bash
   ./scripts/generate_certs.sh 127.0.0.1
   ```
2. This creates `certs/server.crt` and `certs/server.key`.

### Production (VPS)
1. Run the script with your VPS Public IP:
   ```bash
   ./scripts/generate_certs.sh YOUR_VPS_IP
   ```

## 🛠️ 3. Protobuf Generation

If you modify the `.proto` files in the `proto/` directory, you must regenerate the Dart stubs:

1. Install the Dart protoc plugin:
   ```bash
   dart pub global activate protoc_plugin
   ```
2. Run the generation script:
   ```bash
   ./scripts/generate_protos.sh
   ```

## 🚀 4. Running Locally

### Backend
1. Go to the backend directory: `cd neotradingbotback1777`
2. Configure `.env` (use `.env.example` as a template).
3. Run the server:
   ```bash
   dart run lib/main.dart
   ```

   frontend (Dashboard)
1. Go to the frontend directory: `cd neotradingbotfront1777`
2. Run the Flutter app:
   ```bash
   flutter run -d chrome
   ```
   > **Note**: For Web, the app connects to port **9090** (Envoy Proxy). Ensure the Envoy container is running (locally or on VPS). By default, it connects to the VPS.

## 🚢 5. Deployment (Docker)

### Remote Deploy (Recommended)
1. Configure `scripts/.env.deploy` with your VPS details.
2. Run the remote deployment script:
   ```bash
   cd scripts
   ./deploy.sh remote
   ```
This script will archive the project, transfer it to the VPS, and orchestrate the Docker container rebuild.

### Manual Docker Setup
If you prefer manual control:
```bash
docker compose up --build -d
```

## ❓ Troubleshooting
- **gRPC Connection Error**: Ensure the backend host and port in the frontend match your environment.
- **TLS Handshake Fail**: Verify that the `server.crt` in `neotradingbotfront1777/assets/certs/` matches the one used by the server.
- **Permission Denied**: Ensure `scripts/` are executable: `chmod +x scripts/*.sh`.

