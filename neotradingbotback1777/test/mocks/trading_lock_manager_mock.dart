import 'package:neotradingbotback1777/core/locks/trading_lock_manager.dart';

/// Un'implementazione "Fake" di TradingLockManager per i test.
/// Esegue semplicemente l'operazione senza alcuna logica di lock.
class FakeTradingLockManager implements TradingLockManager {
  @override
  Future<T> executeTradingOperation<T>(
    String symbol,
    Future<T> Function() operation, {
    bool checkCooldown = true,
  }) async {
    // Esegui direttamente l'operazione senza lock.
    return await operation();
  }

  @override
  Future<T> executeTradingOperationSync<T>(
    String symbol,
    T Function() operation, {
    bool checkCooldown = true,
  }) async {
    // Esegui direttamente l'operazione senza lock.
    return operation();
  }

  // Implementa gli altri metodi con un comportamento vuoto o di default
  // che non influenzi i test.
  @override
  void cleanupOldOperationTimes() {
    // Non fa nulla.
  }

  @override
  TradingLockStats getStats() {
    return const TradingLockStats(
      activeLocksCount: 0,
      trackedSymbolsCount: 0,
      operationCooldown: Duration.zero,
    );
  }

  @override
  Duration? getTimeUntilNextOperation(String symbol) {
    return null;
  }
}
