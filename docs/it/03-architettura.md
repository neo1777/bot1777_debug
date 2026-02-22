# NeoTradingBot 1777 - Diagrammi dell'Architettura

Questo documento contiene i diagrammi completi dell'architettura per il sistema NeoTradingBot 1777, fornendo rappresentazioni visive della struttura del sistema, dei flussi di dati e delle interazioni tra i componenti.

## Sommario

1. [Panoramica del Sistema](#panoramica-del-sistema)
2. [Livelli Clean Architecture](#livelli-clean-architecture)
3. [Diagramma del Flusso di Trading](#diagramma-del-flusso-di-trading)
4. [Diagramma del Flusso di Dati](#diagramma-del-flusso-di-dati)
5. [Diagramma di Interazione tra Componenti](#diagramma-di-interazione-tra-componenti)
6. [Architettura della Sicurezza](#architettura-della-sicurezza)
7. [Architettura di Deploy](#architettura-di-deploy)

## Panoramica del Sistema

```mermaid
graph TB
    subgraph "Frontend (Flutter)"
        UI[Livello Presentazione]
        BLoC[Livello BLoC]
        DI[Container DI]
    end

    subgraph "Backend (Dart)"
        GRPC[Server gRPC]
        UC[Casi d'Uso]
        DOM[Livello Dominio]
        INF[Livello Infrastruttura]
    end

    subgraph "Servizi Esterni"
        BINANCE[Binance API]
        HIVE[Database Hive]
    end

    UI --> BLoC
    BLoC --> DI
    DI --> GRPC
    GRPC --> UC
    UC --> DOM
    DOM --> INF
    INF --> BINANCE
    INF --> HIVE
```

## Livelli Clean Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        UI[UI Flutter]
        BLoC[Gestione Stato BLoC]
        VALID[Validazione Input]
    end

    subgraph "Application Layer"
        UC[Casi d'Uso]
        MGR[Manager]
        HANDLER[Gestori Errori]
    end

    subgraph "Domain Layer"
        ENT[Entità]
        REPO[Interfacce Repository]
        SERV[Servizi di Dominio]
        FAIL[Errori/Fallimenti]
    end

    subgraph "Infrastructure Layer"
        API[Servizi API]
        CACHE[Livello Cache]
        PERSIST[Persistenza]
        NET[Livello Network]
    end

    UI --> BLoC
    BLoC --> VALID
    VALID --> UC
    UC --> MGR
    MGR --> HANDLER
    HANDLER --> ENT
    ENT --> REPO
    REPO --> SERV
    SERV --> FAIL
    FAIL --> API
    API --> CACHE
    CACHE --> PERSIST
    PERSIST --> NET
```

## Diagramma del Flusso di Trading

```mermaid
sequenceDiagram
    participant U as Utente
    participant F as Frontend
    participant B as Backend
    participant T as Loop di Trading
    participant E as Valutatore
    participant A as API Binance

    U->>F: Avvia Strategia
    F->>B: gRPC StartStrategy
    B->>T: Inizializza Trading Loop
    T->>E: Valuta Decisioni di Trading
    E->>A: Ottieni Dati di Mercato
    A-->>E: Dati Prezzo
    E->>E: Calcola P&L
    E->>E: Verifica TP/SL
    alt TP/SL Attivato
        E->>A: Esegui Ordine di Vendita
        A-->>E: Conferma Ordine
        E->>T: Aggiorna Stato
        T->>B: Verifica Controllo Esecuzione (Cicli/StopDopoProssimaVendita)
        alt Deve Fermarsi
            B->>T: Termina Loop
            T->>B: Notifica Completamento
            B->>F: Strategia Completata
            F->>U: Mostra Risultati
        else Continua
            B->>T: Continua Prossimo Ciclo
            T->>T: Attendi Prossimo Tick
        end
    else Continua Monitoraggio
        T->>T: Attendi Prossimo Tick
        T->>E: Rivaluta
    end
```

## Architettura della Sicurezza

```mermaid
graph TB
    subgraph "Livelli di Sicurezza"
        TLS[Criptazione TLS]
        PINNING[Certificate Pinning]
        AUTH[Autenticazione API]
        VALID[Validazione Input]
    end

    subgraph "Protezione Dati"
        ENCRYPT[Criptazione Dati]
        SANITIZE[Sanificazione Input]
        AUDIT[Log di Audit]
        BACKUP[Backup Sicuro]
    end

    subgraph "Controllo Accessi"
        RATE_LIMIT[Rate Limiting]
        CIRCUIT_BREAK[Circuit Breaker]
        LOCK[Lock Distribuiti]
        PERMISSIONS[Sistema Permessi]
    end

    TLS --> PINNING
    PINNING --> AUTH
    AUTH --> VALID

    VALID --> ENCRYPT
    ENCRYPT --> SANITIZE
    SANITIZE --> AUDIT
    AUDIT --> BACKUP

    BACKUP --> RATE_LIMIT
    RATE_LIMIT --> CIRCUIT_BREAK
    CIRCUIT_BREAK --> LOCK
    LOCK --> PERMISSIONS
```

## Stato della Strategia di Trading

```mermaid
stateDiagram-v2
    [*] --> IDLE: Inizializza
    IDLE --> MONITORING_FOR_BUY: Avvia Strategia
    MONITORING_FOR_BUY --> POSITION_OPEN: Acquisto Iniziale
    MONITORING_FOR_BUY --> IDLE: Ferma Strategia
    POSITION_OPEN --> POSITION_OPEN: Acquisto DCA
    POSITION_OPEN --> IDLE: Vendita (TP/SL)
    POSITION_OPEN --> IDLE: Ferma Strategia
    IDLE --> [*]: Spegnimento
```

---

## Legenda

- **Frecce continue**: Dipendenze dirette
- **Frecce tratteggiate**: Dipendenze opzionali o condizionali
- **Rettangoli**: Componenti/Moduli
- **Cerchi**: Servizi esterni
- **Rombi**: Punti di decisione
- **Esagoni**: Archivi dati

## Note

- Tutti i diagrammi sono creati usando la sintassi Mermaid
- L'architettura segue i principi della Clean Architecture
- La sicurezza è implementata a più livelli
- Il monitoraggio delle prestazioni è integrato in tutto il sistema

