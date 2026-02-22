import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_notification_service.dart';
import 'package:intl/intl.dart';

class SendStatusReport {
  final AccountRepository _accountRepo;
  final StrategyStateRepository _strategyStateRepo;
  final PriceRepository _priceRepo;
  final INotificationService _notificationService;

  SendStatusReport(
    this._accountRepo,
    this._strategyStateRepo,
    this._priceRepo,
    this._notificationService,
  );

  Future<Either<Failure, void>> call() async {
    try {
      final buffer = StringBuffer();
      final now = DateTime.now();
      final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');

      buffer.writeln('📊 *STATUS REPORT - ${formatter.format(now)}*');
      buffer.writeln('------------------------------------------');

      // 1. Account Info
      final accountResult = await _accountRepo.getAccountInfo();
      accountResult.fold(
        (f) => buffer.writeln('❌ Account: Errore nel recupero dati'),
        (info) {
          if (info != null) {
            buffer.writeln(
                '💰 *Bilancio Totale:* \$${info.totalEstimatedValueUSDC.toStringAsFixed(2)} USDC');
            buffer.writeln('🏦 *Asset Principali:*');
            // Show top 3 assets by value
            final sortedBalances = List<Balance>.from(info.balances)
              ..sort((a, b) =>
                  b.estimatedValueUSDC.compareTo(a.estimatedValueUSDC));

            for (var b in sortedBalances.take(5)) {
              if (b.estimatedValueUSDC > 0.1) {
                buffer.writeln(
                    '  • ${b.asset}: ${b.free.toStringAsFixed(4)} (\$${b.estimatedValueUSDC.toStringAsFixed(2)})');
              }
            }
          }
        },
      );

      buffer.writeln('\n🤖 *Stato Strategie:*');

      // 2. Strategy States
      final statesResult = await _strategyStateRepo.getAllStrategyStates();
      await statesResult.fold(
        (f) async => buffer.writeln('❌ Errore nel recupero stati strategie'),
        (states) async {
          if (states.isEmpty) {
            buffer.writeln('  • Nessuna strategia attiva.');
          } else {
            for (var entry in states.entries) {
              final symbol = entry.key;
              final state = entry.value;

              String statusIcon = '⚪';
              if (state.status.name == 'STRATEGY_STATUS_RUNNING')
                statusIcon = '🟢';
              if (state.status.name == 'STRATEGY_STATUS_PAUSED')
                statusIcon = '🟡';
              if (state.status.name == 'STRATEGY_STATUS_ERROR')
                statusIcon = '🔴';

              // Get current price for context
              final priceResult = await _priceRepo.getCurrentPrice(symbol);
              final currentPrice = priceResult.getOrElse((_) => 0.0) ?? 0.0;

              buffer.writeln(
                  '$statusIcon *$symbol:* ${state.status.name.split('_').last}');
              buffer.writeln(
                  '  • Round: ${state.currentRoundId} | Trades: ${state.openTrades.length}');
              buffer.writeln(
                  '  • Avg Price: ${state.averagePrice.toStringAsFixed(2)} | Current: ${currentPrice.toStringAsFixed(2)}');
              buffer.writeln(
                  '  • Profit Tot: \$${state.cumulativeProfit.toStringAsFixed(2)} USDC');
            }
          }
        },
      );

      buffer.writeln('------------------------------------------');
      buffer.writeln('✅ Report generato con successo.');

      await _notificationService.sendMessage(buffer.toString());

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
          message: 'Errore durante la generazione del report: $e'));
    }
  }
}
