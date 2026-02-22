import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/generated/proto/grpc/health/v1/health.pbgrpc.dart';
import 'package:rxdart/rxdart.dart';

/// Implementazione concreta e stateful del servizio gRPC Health.
///
/// Utilizza un [BehaviorSubject] per mantenere e trasmettere lo stato di salute
/// attuale, permettendo aggiornamenti dinamici e notifiche in tempo reale
/// tramite il metodo `watch`.
class HealthServiceImpl extends HealthServiceBase {
  final _log = LogManager.getLogger();

  // BehaviorSubject mantiene l'ultimo stato e lo notifica ai nuovi iscritti.
  // Inizializziamo il servizio come SERVING di default.
  final BehaviorSubject<HealthCheckResponse_ServingStatus> _statusSubject =
      BehaviorSubject.seeded(HealthCheckResponse_ServingStatus.SERVING);

  HealthServiceImpl() {
    _log.i('HealthService inizializzato con stato: SERVING');
  }

  /// Aggiorna lo stato di salute del servizio.
  ///
  /// Questo metodo può essere chiamato da altre parti dell'applicazione per
  /// segnalare un cambiamento nello stato (es. perdita di connessione al DB).
  /// [serviceName] è ignorato in questa implementazione semplice, ma potrebbe
  /// essere usato per gestire la salute di più servizi individualmente.
  void setStatus(String serviceName, HealthCheckResponse_ServingStatus status) {
    if (_statusSubject.value != status) {
      _log.w('Stato di salute cambiato per "$serviceName" a: ${status.name}');
      _statusSubject.add(status);
    }
  }

  /// Metodo unario che restituisce lo stato di salute corrente.
  @override
  Future<HealthCheckResponse> check(
      ServiceCall call, HealthCheckRequest request) async {
    // Restituisce l'ultimo valore emesso dal subject.
    return HealthCheckResponse()..status = _statusSubject.value;
  }

  /// Metodo streaming che invia lo stato di salute attuale e ogni cambiamento successivo.
  @override
  Stream<HealthCheckResponse> watch(
      ServiceCall call, HealthCheckRequest request) async* {
    _log.i('Nuovo client in ascolto per lo stato di salute (watch).');
    // Si sottoscrive allo stream del subject. L'uso di async* e yield*
    // gestisce la propagazione dei dati e la chiusura dello stream.
    await for (final status in _statusSubject.stream) {
      yield HealthCheckResponse()..status = status;
    }
  }

  /// Chiude le risorse del servizio, in particolare lo stream controller.
  Future<void> dispose() async {
    await _statusSubject.close();
    _log.i('HealthService smaltito correttamente.');
  }
}
