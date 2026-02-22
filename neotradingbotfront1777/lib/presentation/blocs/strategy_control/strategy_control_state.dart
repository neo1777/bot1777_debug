part of 'strategy_control_bloc.dart';

enum OperationStatus { none, inProgress, success, failure }

class StrategyControlState extends Equatable {
  const StrategyControlState({
    this.status = OperationStatus.none,
    this.errorMessage,
  });

  final OperationStatus status;
  final String? errorMessage;

  bool get isOperationInProgress => status == OperationStatus.inProgress;

  StrategyControlState copyWith({
    OperationStatus? status,
    String? errorMessage,
  }) {
    return StrategyControlState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
