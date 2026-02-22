# Protobuf Resource Inventory (Final)

## 1. Application Contracts (Source of Truth)
Centralized in the root directory to ensure consistency across all sub-projects.

| File Path | Description | Version |
| :--- | :--- | :--- |
| `proto/trading/v1/trading_service.proto` | Main trading logic, orders, and account info. | v1 |
| `proto/grpc/health/v1/health.proto` | Standard gRPC Health Checking protocol. | v1 |

## 2. Generated Code (Dart Stubs)
Generated into specialized directories within each sub-project. **DO NOT EDIT MANUALLY.**

- **Backend**: `neotradingbotback1777/lib/generated/proto/`
- **Frontend**: `neotradingbotfront1777/lib/generated/proto/`

## 3. Build Infrastructure (Tools)
Located in the root to separate build logic from application code.

| Directory | Content |
| :--- | :--- |
| `tools/protoc/bin/` | The `protoc` compiler executable. |
| `tools/protoc/include/google/protobuf/` | Standard Well-Known Types (WKTs) like `Empty`, `Timestamp`, etc. |

## 4. Best Practices Status
- [x] **Namespace isolation**: Using `trading.v1` and `grpc.health.v1`.
- [x] **Centralized Protos**: No duplicates.
- [x] **High Precision**: Decimal values handled via string fields.
- [x] **Standard Compliance**: Health checks follow the official gRPC spec.
- [x] **TLS Encryption**: Full end-to-end TLS enabled using self-signed certs.
- [x] **Certificate Pinning**: Frontend trusts only the specific `server.crt` asset.
- [x] **Secure by Default**: `STRICT_BOOT` prevents insecure backend startup.

---

# Protobuf Best Practices for Dart & Flutter

This document outlines the standard and recommended practices for using Protocol Buffers and gRPC in our project architecture.

## 📁 Directory Structure
### Recommended: Centralized Root
A single `proto/` folder at the project root is preferred for multi-platform projects (Backend + Frontend).
```
/neotradingbot1777
  /proto
    /trading
      v1/
        trading_service.proto
        trading_models.proto
    /account
      v1/
        account_models.proto
  /neotradingbotback1777 (Backend)
  /neotradingbotfront1777 (Frontend)
```

### Generation Output
Generated Dart files should be isolated from manual code:
- **Location**: `lib/generated/proto/` or `lib/src/generated/`.
- **Note**: These files should never be edited manually.

## 🛠️ Definition Guidelines
### Packages & Imports
- **Package Name**: Should match the folder structure (e.g., `package trading.v1;`).
- **Imports**: Use relative imports from the root of the proto repository.

### Well-Known Types
Use standard Google protos instead of custom "empty" or "timestamp" objects.
- `import "google/protobuf/empty.proto";` -> use `google.protobuf.Empty`
- `import "google/protobuf/timestamp.proto";` -> use `google.protobuf.Timestamp`

### Naming & Tags
- **Enums**: First value MUST be `ENUM_NAME_UNSPECIFIED = 0;`.
- **Field Tags**: Values 1-15 are most efficient (1 byte). Use them for high-frequency fields.
- **CamelCase**: Use `UpperCamelCase` for Messages and `snake_case` for field names.

## 🤖 Code Generation (Dart)
Use `protoc` with the Dart plugin:
`protoc --dart_out=grpc:lib/generated/proto -I proto proto/trading/v1/trading_service.proto`

## 🛡️ Performance & Maintenance
- **Small Messages**: Avoid deep nesting or hundreds of fields.
- **Versioning**: Add new fields, don't change tags or types of existing ones.
- **Contract-First**: Define the `.proto` before implementing the logic.
