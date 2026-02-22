// Questo file era mancante
import 'package:equatable/equatable.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';

class AccountInfo extends Equatable {
  final List<Balance> balances;
  final double totalEstimatedValueUSDC;

  const AccountInfo({
    required this.balances,
    this.totalEstimatedValueUSDC = 0.0,
  });

  @override
  List<Object?> get props => [balances, totalEstimatedValueUSDC];
}
