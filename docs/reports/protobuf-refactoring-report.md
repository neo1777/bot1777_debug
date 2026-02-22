# Report di Refactoring Protobuf

Questo report analizza lo stato attuale dell'infrastruttura Protobuf e propone miglioramenti specifici per risolvere i problemi di duplicazione e precisione.

## 🔴 Problemi Attuali ("Pasticci")

### 1. Codice Generato Duplicato
I file Dart generati sono duplicati in più directory, causando confusione negli import:
- **Backend**:
  - `lib/presentation/grpc/generated/` (Obsoleto/Parziale)
  - `lib/presentation/grpc/generated/proto/` (Attuale/Parziale)
- **Frontend**:
  - `lib/generated/` (Obsoleto/Parziale)
  - `lib/generated/proto/` (Attuale/Parziale)

### 2. Struttura Inconsistente delle Directory
- I file `.proto` si trovavano in una cartella piatta `/proto/`, ignorando i nomi dei package defined (`trading`, `grpc.health.v1`).
- I proto standard di Google erano mescolati con il codice del backend.

### 3. Gap di Precisione
Molte parti di `trading_service.proto` utilizzavano ancora campi `double`, che causano arrotondamenti indesiderati nel trading:
- **AccountInfoResponse**: Mancava `totalEstimatedValueUSDCStr`.
- **BalanceProto**: Mancavano le versioni stringa per `free`, `locked`.
- **PriceResponse**: Molti campi (prezzo, volume, variazione) erano solo `double`.

## 🟢 Miglioramenti Proposti e Implementati

### 1. Standardizzazione Architetturale
- **Sorgente**: Mantenere `/proto/` come unica fonte di verità.
- **Struttura Rispecchiata**:
  - `/proto/trading/v1/trading_service.proto`
  - `/proto/grpc/health/v1/health.proto`
- **Output**: Standardizzato in `lib/generated/proto/` per entrambi i progetti.

### 2. Pulizia dei File
- **ELIMINAZIONE**: Rimossi tutti i vecchi file `.pb.dart` dalle directory non standard.
- **STRUMENTI**: Spostato il compilatore e i tipi standard in `tools/protoc/` per isolarli dal codice dell'app.

### 3. Aggiornamenti dei Contenuti
- **Precisione**: Aggiunti campi `*Str` per tutti i valori decimali critici.
- **Opzioni**: Aggiunto `option dart_package` per una migliore organizzazione logica.

### 4. Allineamento Health Check
Assicurata la corretta implementazione di `health.proto` nel backend per l'integrazione con strumenti di monitoraggio standard.

## 🛠️ Strategia di Implementazione
1. Backup dei proto correnti.
2. Riorganizzazione delle cartelle e dei namespace.
3. Aggiornamento della precisione (campi String).
4. Eliminazione di massa del vecchio codice generato.
5. Script di generazione unico e portatile (`scripts/generate_protos.sh`).

