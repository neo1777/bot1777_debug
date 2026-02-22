// Questo file di supporto era mancante
import 'package:equatable/equatable.dart';

class Balance extends Equatable {
  final String asset;
  final double free;
  final double locked;
  final double estimatedValueUSDC;

  const Balance({
    required this.asset,
    required this.free,
    required this.locked,
    this.estimatedValueUSDC = 0.0,
  });

  double get total => free + locked;

  @override
  List<Object?> get props => [asset, free, locked, estimatedValueUSDC];
}
