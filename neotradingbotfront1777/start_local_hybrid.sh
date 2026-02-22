#!/bin/bash
# Helper script to start the local frontend connecting to a remote VPS backend.
set -e

echo "========================================================"
echo " Starting Local Frontend -> Remote VPS Hybrid Testing"
echo "========================================================"

read -p "Enter VPS IP address (e.g., 5.45.126.177): " VPS_IP
if [ -z "$VPS_IP" ]; then
    echo "VPS IP is required."
    exit 1
fi

read -p "Enter GRPC_API_KEY (from backend .env): " API_KEY

echo "Launching Flutter app targeting $VPS_IP:8080 (INSECURE)..."

flutter run -d chrome \
    --dart-define="GRPC_HOST=$VPS_IP" \
    --dart-define="GRPC_PORT=8080" \
    --dart-define="GRPC_ALLOW_INSECURE=true" \
    --dart-define="GRPC_API_KEY=$API_KEY"
