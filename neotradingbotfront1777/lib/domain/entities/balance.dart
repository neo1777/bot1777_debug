import 'package:equatable/equatable.dart';

class Balance extends Equatable {
  const Balance({
    required this.asset,
    required this.free,
    required this.locked,
    this.estimatedValueUSDC = 0.0,
    this.freeStr = '',
    this.lockedStr = '',
    this.estimatedValueUSDCStr = '',
  });

  final String asset;
  final double free;
  final double locked;
  final double estimatedValueUSDC;
  final String freeStr;
  final String lockedStr;
  final String estimatedValueUSDCStr;

  double get total => free + locked;

  @override
  List<Object?> get props => [
    asset,
    free,
    locked,
    estimatedValueUSDC,
    freeStr,
    lockedStr,
    estimatedValueUSDCStr,
  ];

  @override
  String toString() =>
      'Balance(asset: $asset, free: $free, locked: $locked, estimatedValueUSDC: $estimatedValueUSDC)';

  Balance copyWith({
    String? asset,
    double? free,
    double? locked,
    double? estimatedValueUSDC,
    String? freeStr,
    String? lockedStr,
    String? estimatedValueUSDCStr,
  }) {
    return Balance(
      asset: asset ?? this.asset,
      free: free ?? this.free,
      locked: locked ?? this.locked,
      estimatedValueUSDC: estimatedValueUSDC ?? this.estimatedValueUSDC,
      freeStr: freeStr ?? this.freeStr,
      lockedStr: lockedStr ?? this.lockedStr,
      estimatedValueUSDCStr:
          estimatedValueUSDCStr ?? this.estimatedValueUSDCStr,
    );
  }
}
