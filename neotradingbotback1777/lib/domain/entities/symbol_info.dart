import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/utils/json_parser.dart';
import 'package:neotradingbotback1777/core/validation/input_validator.dart';

class SymbolInfo extends Equatable {
  final String symbol;

  /// Asset base (es. BTC). Presente in /exchangeInfo; opzionale qui.
  final String baseAsset;

  /// Asset di quotazione (es. USDC). Presente in /exchangeInfo; opzionale qui.
  final String quoteAsset;
  final double minQty;
  final double maxQty;
  final double stepSize;
  final double minNotional;

  /// Filtri del simbolo per calcoli di fee
  final List<Map<String, dynamic>> filters;

  const SymbolInfo({
    required this.symbol,
    required this.minQty,
    required this.maxQty,
    required this.stepSize,
    required this.minNotional,
    this.baseAsset = '',
    this.quoteAsset = '',
    this.filters = const [],
  });

  static Either<String, SymbolInfo> fromJson(Map<String, dynamic> json) {
    try {
      // Extract and validate symbol
      final symbolResult =
          JsonParser.safeExtract<String>(json, 'symbol', (v) => v.toString());

      if (symbolResult.isLeft()) {
        return Left(
            'Invalid symbol key: ${symbolResult.fold((f) => f.message, (r) => '')}');
      }

      final symbolStr = symbolResult.getOrElse((_) => '');
      final validation = InputValidator.validateSymbol(symbolStr);

      if (!validation.isValid) {
        return Left('Invalid symbol format: ${validation.error}');
      }

      // Extract and validate filters list
      final filtersResult = JsonParser.safeExtractList<Map<String, dynamic>>(
          json, 'filters', (v) => v as Map<String, dynamic>);
      if (filtersResult.isLeft()) {
        return Left(
            'Invalid filters: ${filtersResult.fold((f) => f.message, (r) => '')}');
      }

      final filters = filtersResult.getOrElse((_) => []);

      // Find LOT_SIZE filter
      final lotSizeFilterResult =
          JsonParser.safeFindInList<Map<String, dynamic>>(
              filters, (f) => f['filterType'] == 'LOT_SIZE', 'LOT_SIZE filter');
      if (lotSizeFilterResult.isLeft()) {
        return Left('LOT_SIZE filter not found');
      }

      // Find NOTIONAL filter
      final notionalFilterResult =
          JsonParser.safeFindInList<Map<String, dynamic>>(
              filters,
              (f) =>
                  f['filterType'] == 'NOTIONAL' ||
                  f['filterType'] == 'MIN_NOTIONAL',
              'NOTIONAL filter');
      if (notionalFilterResult.isLeft()) {
        return Left('NOTIONAL filter not found');
      }

      final lotSizeFilter = lotSizeFilterResult.getOrElse((_) => {});
      final notionalFilter = notionalFilterResult.getOrElse((_) => {});

      // Parse numeric values
      final minQtyResult =
          JsonParser.safeParseDouble(lotSizeFilter['minQty'], 'minQty');
      if (minQtyResult.isLeft()) {
        return Left(
            'Invalid minQty: ${minQtyResult.fold((f) => f.message, (r) => '')}');
      }

      final maxQtyResult =
          JsonParser.safeParseDouble(lotSizeFilter['maxQty'], 'maxQty');
      if (maxQtyResult.isLeft()) {
        return Left(
            'Invalid maxQty: ${maxQtyResult.fold((f) => f.message, (r) => '')}');
      }

      final stepSizeResult =
          JsonParser.safeParseDouble(lotSizeFilter['stepSize'], 'stepSize');
      if (stepSizeResult.isLeft()) {
        return Left(
            'Invalid stepSize: ${stepSizeResult.fold((f) => f.message, (r) => '')}');
      }

      // Handle both 'minNotional' and 'notional' fields
      final minNotionalValue =
          notionalFilter['minNotional'] ?? notionalFilter['notional'];
      final minNotionalResult =
          JsonParser.safeParseDouble(minNotionalValue, 'minNotional');
      if (minNotionalResult.isLeft()) {
        return Left(
            'Invalid minNotional: ${minNotionalResult.fold((f) => f.message, (r) => '')}');
      }

      // Lettura opzionale di base/quote asset se presenti a livello simbolo
      final base = json['baseAsset']?.toString() ?? '';
      final quote = json['quoteAsset']?.toString() ?? '';

      return Right(SymbolInfo(
        symbol: symbolResult.getOrElse((_) => ''),
        baseAsset: base,
        quoteAsset: quote,
        minQty: minQtyResult.getOrElse((_) => 0.0),
        maxQty: maxQtyResult.getOrElse((_) => 0.0),
        stepSize: stepSizeResult.getOrElse((_) => 0.0),
        minNotional: minNotionalResult.getOrElse((_) => 0.0),
        filters: filters,
      ));
    } catch (e) {
      return Left('SymbolInfo parsing failed: $e');
    }
  }

  @override
  List<Object> get props => [
        symbol,
        baseAsset,
        quoteAsset,
        minQty,
        maxQty,
        stepSize,
        minNotional,
        filters
      ];
}
