/// Servizio per calcolare automaticamente la quantità fissa in base al prezzo corrente
/// e all'importo in dollari specificato.
class QuantityCalculatorService {
  /// Cache dinamica dei step size recuperati da ExchangeInfo via gRPC/API.
  /// Prioritaria rispetto ai valori hardcoded di fallback.
  static final Map<String, double> _dynamicStepSizes = {};

  /// Aggiorna la cache dei step size con dati reali dall'exchange.
  /// Chiamare dopo aver ottenuto ExchangeInfo dal backend.
  static void updateStepSizesFromExchangeInfo(Map<String, double> stepSizes) {
    _dynamicStepSizes
      ..clear()
      ..addAll(stepSizes);
  }

  /// Calcola la quantità fissa in base all'importo in dollari e al prezzo corrente
  ///
  /// [tradeAmount] - Importo in dollari (es. 10.0)
  /// [currentPrice] - Prezzo corrente della coppia di trading
  /// [stepSize] - Dimensione del passo per l'arrotondamento (es. 0.00001 per BTC)
  ///
  /// Restituisce la quantità arrotondata secondo le regole dell'exchange
  static double calculateFixedQuantity({
    required double tradeAmount,
    required double currentPrice,
    double stepSize = 0.00001, // Default per BTC
  }) {
    if (tradeAmount <= 0 || currentPrice <= 0) {
      return 0.0;
    }

    // Calcola la quantità grezza
    final rawQuantity = tradeAmount / currentPrice;

    // Arrotonda secondo stepSize
    final roundedQuantity = _roundToStepSize(rawQuantity, stepSize);

    return roundedQuantity;
  }

  /// Arrotonda una quantità secondo la dimensione del passo specificata
  static double _roundToStepSize(double quantity, double stepSize) {
    if (stepSize <= 0) return quantity;

    // Calcola il numero di passi
    final steps = (quantity / stepSize).round();

    // Restituisce la quantità arrotondata
    return steps * stepSize;
  }

  /// Ottiene la dimensione del passo per un simbolo specifico.
  /// Usa i dati dinamici dall'exchange se disponibili, altrimenti fallback hardcoded.
  static double getStepSizeForSymbol(String symbol) {
    // Priorità 1: dati reali dall'exchange
    final upperSymbol = symbol.toUpperCase();
    if (_dynamicStepSizes.containsKey(upperSymbol)) {
      return _dynamicStepSizes[upperSymbol]!;
    }

    // Priorità 2: valori predefiniti per le coppie più comuni (fallback)
    const fallbackStepSizes = {
      'BTCUSDC': 0.00001,
      'BTCUSDT': 0.00001,
      'ETHUSDC': 0.0001,
      'ETHUSDT': 0.0001,
      'ADAUSDC': 0.1,
      'ADAUSDT': 0.1,
      'DOTUSDC': 0.01,
      'DOTUSDT': 0.01,
      'LINKUSDC': 0.01,
      'LINKUSDT': 0.01,
      'MATICUSDC': 0.1,
      'MATICUSDT': 0.1,
      'SOLUSDC': 0.01,
      'SOLUSDT': 0.01,
    };

    return fallbackStepSizes[upperSymbol] ?? 0.00001;
  }

  /// Calcola la quantità fissa per un simbolo specifico
  static double calculateForSymbol({
    required String symbol,
    required double tradeAmount,
    required double currentPrice,
  }) {
    final stepSize = getStepSizeForSymbol(symbol);
    return calculateFixedQuantity(
      tradeAmount: tradeAmount,
      currentPrice: currentPrice,
      stepSize: stepSize,
    );
  }

  /// Formatta la quantità per la visualizzazione
  static String formatQuantity(double quantity, {int precision = 8}) {
    if (quantity == 0) return '0';

    // Rimuove gli zeri finali non significativi
    final formatted = quantity.toStringAsFixed(precision);
    return formatted
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  /// Calcola l'importo equivalente in dollari per una quantità fissa
  static double calculateEquivalentAmount({
    required double fixedQuantity,
    required double currentPrice,
  }) {
    return fixedQuantity * currentPrice;
  }
}
