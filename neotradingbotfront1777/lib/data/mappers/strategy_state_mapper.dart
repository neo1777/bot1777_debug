import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;

/// Converte un DTO gRPC [grpc.StrategyStateResponse] nell'entità di dominio [StrategyState].
String? _extractWarning(grpc.StrategyStateResponse proto) {
  try {
    final map = (proto.toProto3Json() as Map<String, dynamic>);
    final v = map['warningMessage'];
    return v is String ? v : null;
  } catch (_) {
    return null;
  }
}

List<String> _extractWarnings(grpc.StrategyStateResponse proto) {
  try {
    final map = (proto.toProto3Json() as Map<String, dynamic>);
    final v = map['warnings'];
    if (v is List) {
      return v.whereType<String>().toList();
    }
  } catch (_) {}
  return const [];
}

StrategyState strategyStateFromProto(grpc.StrategyStateResponse proto) {
  // Lettura con preferenza ai nuovi campi string, fallback ai legacy double
  double parseOr(double legacy, String? s) {
    if (s != null && s.isNotEmpty) {
      final v = double.tryParse(s);
      if (v != null && v.isFinite) return v;
    }
    return legacy;
  }

  String? avgStr;
  String? qtyStr;
  String? lastStr;
  String? cumStr;

  try {
    final map = (proto.toProto3Json() as Map<String, dynamic>);
    avgStr = map['averagePriceStr'] as String?;
    qtyStr = map['totalQuantityStr'] as String?;
    lastStr = map['lastBuyPriceStr'] as String?;
    cumStr = map['cumulativeProfitStr'] as String?;
  } catch (_) {}

  return StrategyState(
    symbol: proto.symbol,
    status: _strategyStatusFromProto(proto.status),
    openTradesCount: proto.openTradesCount,
    averagePrice: parseOr(proto.averagePrice, avgStr),
    totalQuantity: parseOr(proto.totalQuantity, qtyStr),
    lastBuyPrice: parseOr(proto.lastBuyPrice, lastStr),
    currentRoundId: proto.currentRoundId,
    cumulativeProfit: parseOr(proto.cumulativeProfit, cumStr),
    successfulRounds: proto.successfulRounds,
    failedRounds: proto.failedRounds,
    warningMessage: _extractWarning(proto),
    warnings: _extractWarnings(proto),
  );
}

/// Converte la stringa di stato dal DTO gRPC nell'enum di dominio [StrategyStatus].
StrategyStatus _strategyStatusFromProto(grpc.StrategyStatus status) {
  switch (status) {
    case grpc.StrategyStatus.STRATEGY_STATUS_IDLE:
      return StrategyStatus.idle;
    case grpc.StrategyStatus.STRATEGY_STATUS_RUNNING:
      return StrategyStatus.running;
    case grpc.StrategyStatus.STRATEGY_STATUS_PAUSED:
      return StrategyStatus.paused;
    case grpc.StrategyStatus.STRATEGY_STATUS_ERROR:
      return StrategyStatus.error;
    case grpc.StrategyStatus.STRATEGY_STATUS_RECOVERING:
      return StrategyStatus.recovering;
    default:
      return StrategyStatus.unspecified;
  }
}
