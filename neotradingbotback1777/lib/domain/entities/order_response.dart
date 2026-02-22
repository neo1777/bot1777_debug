import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/utils/json_parser.dart';

class OrderResponse extends Equatable {
  final String symbol;
  final int orderId;
  final String? clientOrderId;
  final int timestamp;
  final String status;
  final double executedQty;
  final double? cumulativeQuoteQty;
  final List<Map<String, dynamic>>? fills;

  const OrderResponse({
    required this.symbol,
    required this.orderId,
    required this.timestamp,
    required this.status,
    required this.executedQty,
    this.clientOrderId,
    this.cumulativeQuoteQty,
    this.fills,
  });

  static Either<String, OrderResponse> fromJson(Map<String, dynamic> json) {
    try {
      final symbolResult =
          JsonParser.safeExtract<String>(json, 'symbol', (v) => v.toString());
      if (symbolResult.isLeft())
        return Left(
            'Invalid symbol: ${symbolResult.fold((f) => f.message, (r) => '')}');

      final orderIdResult = JsonParser.safeParseInt(json['orderId'], 'orderId');
      if (orderIdResult.isLeft())
        return Left(
            'Invalid orderId: ${orderIdResult.fold((f) => f.message, (r) => '')}');

      final statusResult =
          JsonParser.safeExtract<String>(json, 'status', (v) => v.toString());
      if (statusResult.isLeft())
        return Left(
            'Invalid status: ${statusResult.fold((f) => f.message, (r) => '')}');

      final executedQtyResult =
          JsonParser.safeParseDouble(json['executedQty'], 'executedQty');
      if (executedQtyResult.isLeft())
        return Left(
            'Invalid executedQty: ${executedQtyResult.fold((f) => f.message, (r) => '')}');

      final transactTimeResult =
          JsonParser.safeParseInt(json['transactTime'], 'transactTime');
      if (transactTimeResult.isLeft())
        return Left(
            'Invalid transactTime: ${transactTimeResult.fold((f) => f.message, (r) => '')}');

      final cumulativeQuoteQtyResult = JsonParser.safeParseDouble(
          json['cummulativeQuoteQty'], 'cummulativeQuoteQty');
      final fillsResult = JsonParser.safeExtractList<Map<String, dynamic>>(
          json, 'fills', (v) => v as Map<String, dynamic>);

      return Right(OrderResponse(
        symbol: symbolResult.getOrElse((_) => ''),
        orderId: orderIdResult.getOrElse((_) => 0),
        clientOrderId: json['clientOrderId'] as String?,
        timestamp: transactTimeResult.getOrElse((_) => 0),
        status: statusResult.getOrElse((_) => ''),
        executedQty: executedQtyResult.getOrElse((_) => 0.0),
        cumulativeQuoteQty:
            cumulativeQuoteQtyResult.fold((l) => null, (r) => r),
        fills: fillsResult.fold((l) => null, (r) => r),
      ));
    } catch (e) {
      return Left('OrderResponse parsing failed: $e');
    }
  }

  @override
  List<Object?> get props => [
        symbol,
        orderId,
        clientOrderId,
        timestamp,
        status,
        executedQty,
        cumulativeQuoteQty,
        fills
      ];
}
