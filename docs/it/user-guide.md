# Guida Utente: NeoTradingBot 1777

## 🚀 Per Iniziare

1. **Accedi alla Dashboard**: Apri l'applicazione Flutter (Desktop o Web).
2. **Stato della Connessione**: Verifica che l'indicatore "Server Status" in alto a destra sia VERDE.

## 📊 Panoramica della Dashboard

- **Panoramica Account**: Mostra il bilancio totale (USDC) e il valore stimato delle posizioni aperte.
- **Strategie Attive**: Elenco delle coppie di trading attualmente monitorate.
  - **Stato**: IDLE (Fermo), LISTENING (In ascolto), POSITION_OPEN (Posizione Aperta).
  - **PnL**: Profitto/Perdita (Profit/Loss) per la posizione attiva corrente.
- **Console Log**: Flusso in tempo reale degli eventi di sistema.

## ⚙️ Configurazione

Le strategie sono configurate tramite le impostazioni dell'app (attualmente basate su file o tramite i default del backend).

### Parametri Chiave
- **Allocazione**: Quantità di USDC da allocare per ogni trade.
- **Target di Profitto**: Guadagno percentuale per attivare una vendita (es. 1.5%).
- **Stop Loss**: Perdita percentuale per attivare una vendita (es. -2.0%).
- **Passaggio DCA**: Percentuale di ribasso per attivare un acquisto di mediazione (DCA).

## ❓ FAQ (Domande Frequenti)

**D: Cosa succede se chiudo la dashboard?**
R: Il bot di trading gira sul backend (server). Chiudere la UI **NON** ferma il trading.

**D: Come faccio a fermare una strategia?**
R: Usa il pulsante "Stop" accanto alla strategia nella dashboard. Questo terminerà correttamente il ciclo di trading per quel simbolo.

**D: I miei certificati sono sicuri?**
R: Sì, la comunicazione tra dashboard e server è criptata via TLS. Nessuno può intercettare i tuoi dati sulla rete.

