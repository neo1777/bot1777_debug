import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/entities/fee_info.dart';

/// Interfaccia per il repository delle fee
///
/// Gestisce il recupero e la cache delle informazioni sulle fee
/// per i simboli di trading
abstract class IFeeRepository {
  /// Recupera le fee per un simbolo specifico
  ///
  /// Priorità: 1. Fee precise dall'account (se autenticato)
  ///           2. Fee base dal simbolo (fallback)
  ///           3. Fee di default (ultimo fallback)
  Future<Either<Failure, FeeInfo>> getSymbolFees(String symbol);

  /// Recupera le fee per tutti i simboli attivi
  ///
  /// Utilizza rate limiting per rispettare i limiti Binance
  Future<Either<Failure, Map<String, FeeInfo>>> getAllSymbolFees();

  /// Aggiorna le fee per un simbolo specifico
  ///
  /// Forza un refresh delle fee bypassando la cache
  Future<Either<Failure, FeeInfo>> refreshSymbolFees(String symbol);

  /// Pulisce la cache delle fee
  ///
  /// Utile per forzare un refresh completo
  Future<void> clearCache();

  /// Controlla se le fee per un simbolo sono ancora valide
  ///
  /// Basato su TTL configurabile
  bool areFeesValid(String symbol);

  /// Recupera le fee solo se non sono in cache o sono scadute
  ///
  /// Ottimizzazione per ridurre le chiamate API non necessarie
  Future<Either<Failure, FeeInfo>> getSymbolFeesIfNeeded(String symbol);
}
