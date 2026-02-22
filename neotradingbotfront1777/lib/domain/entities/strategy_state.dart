import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum StrategyStatus { idle, running, paused, error, recovering, unspecified }

/// Estensione centralizzata per la presentazione dello stato della strategia.
/// Ogni valore dell'enum ha un nome visualizzabile, colore e icona associati.
extension StrategyStatusExtension on StrategyStatus {
  /// Nome localizzato per l'UI.
  String get displayName {
    switch (this) {
      case StrategyStatus.idle:
        return 'INATTIVA';
      case StrategyStatus.running:
        return 'ATTIVA';
      case StrategyStatus.paused:
        return 'IN PAUSA';
      case StrategyStatus.error:
        return 'ERRORE';
      case StrategyStatus.recovering:
        return 'RIPRISTINO';
      case StrategyStatus.unspecified:
        return 'NON SPECIFICATO';
    }
  }

  /// Colore semantico per badge e indicatori.
  Color get color {
    switch (this) {
      case StrategyStatus.idle:
        return Colors.grey;
      case StrategyStatus.running:
        return Colors.greenAccent;
      case StrategyStatus.paused:
        return Colors.orangeAccent;
      case StrategyStatus.error:
        return Colors.redAccent;
      case StrategyStatus.recovering:
        return Colors.amber;
      case StrategyStatus.unspecified:
        return Colors.blueGrey;
    }
  }

  /// Icona rappresentativa dello stato.
  IconData get icon {
    switch (this) {
      case StrategyStatus.idle:
        return Icons.pause_circle_outline;
      case StrategyStatus.running:
        return Icons.play_circle_filled;
      case StrategyStatus.paused:
        return Icons.pause_circle_filled;
      case StrategyStatus.error:
        return Icons.error_outline;
      case StrategyStatus.recovering:
        return Icons.autorenew;
      case StrategyStatus.unspecified:
        return Icons.help_outline;
    }
  }
}

class StrategyState extends Equatable {
  final String symbol;
  final StrategyStatus status;
  final int openTradesCount;
  final double averagePrice;
  final double totalQuantity;
  final double lastBuyPrice;
  final int currentRoundId;
  final double cumulativeProfit;
  final int successfulRounds;
  final int failedRounds;
  final String? warningMessage;
  final List<String> warnings;

  const StrategyState({
    required this.symbol,
    required this.status,
    required this.openTradesCount,
    required this.averagePrice,
    required this.totalQuantity,
    required this.lastBuyPrice,
    required this.currentRoundId,
    required this.cumulativeProfit,
    required this.successfulRounds,
    required this.failedRounds,
    this.warningMessage,
    this.warnings = const [],
  });

  factory StrategyState.initial({required String symbol}) {
    return StrategyState(
      symbol: symbol,
      status: StrategyStatus.idle,
      openTradesCount: 0,
      averagePrice: 0.0,
      totalQuantity: 0.0,
      lastBuyPrice: 0.0,
      currentRoundId: 0,
      cumulativeProfit: 0.0,
      successfulRounds: 0,
      failedRounds: 0,
      warningMessage: null,
      warnings: const [],
    );
  }

  StrategyState copyWith({
    String? symbol,
    StrategyStatus? status,
    int? openTradesCount,
    double? averagePrice,
    double? totalQuantity,
    double? lastBuyPrice,
    int? currentRoundId,
    double? cumulativeProfit,
    int? successfulRounds,
    int? failedRounds,
    String? warningMessage,
    List<String>? warnings,
  }) {
    return StrategyState(
      symbol: symbol ?? this.symbol,
      status: status ?? this.status,
      openTradesCount: openTradesCount ?? this.openTradesCount,
      averagePrice: averagePrice ?? this.averagePrice,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      lastBuyPrice: lastBuyPrice ?? this.lastBuyPrice,
      currentRoundId: currentRoundId ?? this.currentRoundId,
      cumulativeProfit: cumulativeProfit ?? this.cumulativeProfit,
      successfulRounds: successfulRounds ?? this.successfulRounds,
      failedRounds: failedRounds ?? this.failedRounds,
      warningMessage: warningMessage ?? this.warningMessage,
      warnings: warnings ?? this.warnings,
    );
  }

  @override
  List<Object?> get props => [
    symbol,
    status,
    openTradesCount,
    averagePrice,
    totalQuantity,
    lastBuyPrice,
    currentRoundId,
    cumulativeProfit,
    successfulRounds,
    failedRounds,
    warningMessage,
    warnings,
  ];
}
