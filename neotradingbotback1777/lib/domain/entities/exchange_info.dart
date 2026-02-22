import 'package:equatable/equatable.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';

class ExchangeInfo extends Equatable {
  final List<SymbolInfo> symbols;

  const ExchangeInfo({required this.symbols});

  factory ExchangeInfo.fromJson(Map<String, dynamic> json) {
    final rawSymbols = json['symbols'];
    if (rawSymbols == null || rawSymbols is! List) {
      return const ExchangeInfo(symbols: []);
    }
    final validSymbols = <SymbolInfo>[];
    for (final raw in rawSymbols) {
      if (raw is Map<String, dynamic>) {
        SymbolInfo.fromJson(raw).fold(
          (_) {}, // Ignora simboli malformati (es. indici o opzioni senza filtri standard)
          (symbol) => validSymbols.add(symbol),
        );
      }
    }

    return ExchangeInfo(symbols: validSymbols);
  }

  @override
  List<Object?> get props => [symbols];
}
