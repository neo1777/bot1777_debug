#!/bin/bash
# Helper script to start the backend locally or on a VPS for testing.
set -e

# Load or establish environment
if [ ! -f .env ]; then
    echo "Creating .env for testing..."
    if [ -f ../.env.example ]; then
        cp ../.env.example .env
    else
        echo "Warning: ../.env.example not found. Creating empty .env"
        touch .env
    fi
fi

# We force insecure mode for local VPS/Hybrid testing to avoid TLS certificate hassle initially
# IN PRODUCTION THIS MUST BE FALSE
echo "GRPC_ALLOW_INSECURE=true" >> .env
echo "GRPC_PORT=8080" >> .env

echo "=================================================="
echo "Starting NeoTradingBot Backend in Hybrid Test Mode"
echo "Port: 8080"
echo "Security: INSECURE (ALLOW_INSECURE_GRPC=true)"
echo "Binding: 0.0.0.0 (Accessible externally)"
echo "=================================================="

# Export env vars explicitly for the Dart process just in case
export ALLOW_INSECURE_GRPC=true
export GRPC_PORT=8080

dart run lib/main.dart
