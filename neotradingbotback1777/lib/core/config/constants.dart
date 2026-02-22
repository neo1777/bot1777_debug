/// Contiene le costanti globali utilizzate nell'applicazione.
class Constants {
  /// URL di base per le API REST di Binance.
  static const String baseUrl = 'https://api.binance.com';

  /// URL di base per gli stream WebSocket di Binance.
  static const String wsBaseUrl = 'wss://stream.binance.com:9443';

  /// URL di base per le API REST di Binance Testnet.
  static const String testnetBaseUrl = 'https://testnet.binance.vision';

  /// URL di base per gli stream WebSocket di Binance Testnet.
  static const String testnetWsBaseUrl = 'wss://stream.testnet.binance.vision';

  /// Timeout standard per le richieste HTTP.
  static const Duration httpTimeout = Duration(seconds: 15);

  /// Simbolo di trading di default per l'applicazione.
  static const String defaultTradingSymbol = 'BTCUSDC';

  // Nomi delle box Hive per la persistenza
  static const String appSettingsBoxName = 'app_settings_box';
  static const String logSettingsBoxName = 'log_settings_box';
  static const String tradingRepositoryBoxName = 'trading_repository_box';
  static const String fifoTradesBoxName = 'fifo_trades_box';
  static const String balanceBoxName = 'balance_box';
  static const String accountInfoBoxName = 'account_info_box';
  static const String symbolInfoBoxName = 'symbol_info_box';
  static const String priceBoxName = 'price_box';
  static const String tradesHistoryBoxName = 'trades_history_box';
  static const String transactionJournalBoxName = 'transaction_journal_box';

  // Chiavi per i singoli record nelle box Hive
  static const String appSettingsKey = 'app_settings';
  static const String logSettingsKey = 'log_settings';

  // NUOVI: Endpoint per le fee
  static const String feeEndpoint = '/sapi/v1/account/tradeFee';
  static const String exchangeInfoEndpoint = '/api/v3/exchangeInfo';
  static const String accountEndpoint = '/api/v3/account';

  // Cache TTL per le fee
  static const Duration feeCacheTtl = Duration(hours: 1);

  // Rate limiting per le fee (rispetta limiti Binance)
  static const int maxFeeRequestsPerSecond = 10;
  static const Duration feeRequestDelay = Duration(milliseconds: 100);

  // Fee di default Binance
  static const double defaultMakerFee = 0.001; // 0.1%
  static const double defaultTakerFee = 0.001; // 0.1%
  static const double bnbDiscountPercentage = 0.25; // 25% sconto
}
