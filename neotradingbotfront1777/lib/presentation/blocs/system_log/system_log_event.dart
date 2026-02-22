part of 'system_log_bloc.dart';

abstract class SystemLogEvent extends Equatable {
  const SystemLogEvent();

  @override
  List<Object> get props => [];
}

class SystemLogSubscriptionRequested extends SystemLogEvent {
  const SystemLogSubscriptionRequested();
}

class _SystemLogReceived extends SystemLogEvent {
  const _SystemLogReceived(this.log);
  final SystemLog log;

  @override
  List<Object> get props => [log];
}

class _SystemLogStreamFailed extends SystemLogEvent {
  const _SystemLogStreamFailed(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}

class SystemLogFilterChanged extends SystemLogEvent {
  const SystemLogFilterChanged({this.levels, this.query});
  final Set<LogLevel>? levels; // null = nessun cambiamento
  final String? query; // null = nessun cambiamento

  @override
  List<Object> get props => [levels ?? {}, query ?? ''];
}

class SystemLogClearRequested extends SystemLogEvent {
  const SystemLogClearRequested();
}

class SystemLogLoadMoreRequested extends SystemLogEvent {
  const SystemLogLoadMoreRequested();
}

class SystemLogToggleAutoScroll extends SystemLogEvent {
  const SystemLogToggleAutoScroll(this.enabled);
  final bool enabled;

  @override
  List<Object> get props => [enabled];
}
