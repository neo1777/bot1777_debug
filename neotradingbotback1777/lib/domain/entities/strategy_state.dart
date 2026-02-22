/// Definisce gli stati operativi possibili per una strategia di trading.
/// L'uso di una macchina a stati finiti (FSM) previene bug logici
/// garantendo che solo azioni valide possano essere eseguite in ogni stato.
library;
// ignore_for_file: constant_identifier_names

enum StrategyState {
  /// La strategia è inattiva o è stata fermata. Stato terminale o iniziale.
  IDLE,

  /// La strategia è attiva e sta analizzando il mercato per identificare
  /// una condizione di acquisto favorevole.
  MONITORING_FOR_BUY,

  /// La strategia ha piazzato un ordine di acquisto e sta attendendo
  /// la sua completa esecuzione (fill) da parte dell'exchange.
  BUY_ORDER_PLACED,

  /// La strategia detiene una posizione (asset acquistato) e sta analizzando
  /// il mercato per una condizione di vendita (es. take profit, stop loss).
  POSITION_OPEN_MONITORING_FOR_SELL,

  /// La strategia ha piazzato un ordine di vendita e sta attendendo
  /// la sua completa esecuzione (fill) da parte dell'exchange.
  SELL_ORDER_PLACED,

  /// La strategia è in pausa: nessuna nuova azione viene intrapresa
  /// finché non viene esplicitamente ripresa.
  PAUSED,
}
