part of 'settings_bloc.dart';

/// Enum per descrivere lo stato corrente della feature.
enum SettingsStatus { initial, loading, success, failure, saving, saved }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final AppSettings? settings;
  final String? failureMessage;
  final String? infoMessage;
  final List<String> warnings;
  final bool isDirty;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings,
    this.failureMessage,
    this.infoMessage,
    this.warnings = const [],
    this.isDirty = false,
  });

  /// Metodo di convenienza per creare una copia dello stato con valori aggiornati.
  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    String? failureMessage,
    String? infoMessage,
    List<String>? warnings,
    bool? isDirty,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      failureMessage: failureMessage ?? this.failureMessage,
      infoMessage: infoMessage ?? this.infoMessage,
      warnings: warnings ?? this.warnings,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [
    status,
    settings,
    failureMessage,
    infoMessage,
    warnings,
    isDirty,
  ];
}
