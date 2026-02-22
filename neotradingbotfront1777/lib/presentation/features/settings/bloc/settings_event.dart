part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object> get props => [];
}

/// Evento per richiedere il caricamento delle impostazioni iniziali.
/// Usa [force] = true per forzare il ricaricamento anche se già caricate.
class SettingsFetched extends SettingsEvent {
  final bool force;
  const SettingsFetched({this.force = false});
  @override
  List<Object> get props => [force];
}

/// Evento per richiedere l'aggiornamento delle impostazioni.
class SettingsUpdated extends SettingsEvent {
  final AppSettings settings;
  const SettingsUpdated(this.settings);
  @override
  List<Object> get props => [settings];
}

/// Evento per notificare il cambiamento dello stato "dirty" (modifiche non salvate).
class SettingsDirtyChanged extends SettingsEvent {
  final bool isDirty;
  const SettingsDirtyChanged(this.isDirty);
  @override
  List<Object> get props => [isDirty];
}
