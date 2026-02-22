part of 'system_log_bloc.dart';

enum SystemLogStatus { initial, loading, subscribed, failure }

class SystemLogState extends Equatable {
  const SystemLogState({
    this.status = SystemLogStatus.initial,
    this.logs = const <SystemLog>[],
    this.errorMessage,
    this.activeLevels = const {LogLevel.info, LogLevel.warning, LogLevel.error},
    this.query = '',
    this.pageSize = 100,
    this.visibleCount = 100,
    this.autoScroll = true,
  });

  final SystemLogStatus status;
  final List<SystemLog> logs;
  final String? errorMessage;
  final Set<LogLevel> activeLevels;
  final String query;
  final int pageSize; // quanti item aggiungere per volta
  final int visibleCount; // quanti item mostrare
  final bool autoScroll; // auto scroll to top on new logs

  SystemLogState copyWith({
    SystemLogStatus? status,
    List<SystemLog>? logs,
    String? errorMessage,
    Set<LogLevel>? activeLevels,
    String? query,
    int? pageSize,
    int? visibleCount,
    bool? autoScroll,
  }) {
    return SystemLogState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      errorMessage: errorMessage ?? this.errorMessage,
      activeLevels: activeLevels ?? this.activeLevels,
      query: query ?? this.query,
      pageSize: pageSize ?? this.pageSize,
      visibleCount: visibleCount ?? this.visibleCount,
      autoScroll: autoScroll ?? this.autoScroll,
    );
  }

  @override
  List<Object?> get props => [
    status,
    logs,
    errorMessage,
    activeLevels,
    query,
    pageSize,
    visibleCount,
    autoScroll,
  ];
}
