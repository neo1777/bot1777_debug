import 'package:decimal/decimal.dart';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/services/notification_formatter.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';

void main() {
  group('NotificationFormatter', () {
    final trade = AppTrade(
      symbol: 'BTCUSDC',
      price: MoneyAmount.fromDecimal(Decimal.parse('42000.50')),
      quantity: QuantityAmount.fromDecimal(Decimal.parse('0.001')),
      isBuy: true,
      timestamp: 1700000000000,
      orderStatus: 'FILLED',
    );

    final state = AppStrategyState(
      symbol: 'BTCUSDC',
      status: StrategyState.MONITORING_FOR_BUY,
      openTrades: [],
      currentRoundId: 3,
      cumulativeProfit: 12.5,
      successfulRounds: 2,
      failedRounds: 1,
    );

    final stateWithTrades = AppStrategyState(
      symbol: 'BTCUSDC',
      status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
      openTrades: [
        FifoAppTrade(
          price: Decimal.parse('41000'),
          quantity: Decimal.parse('0.001'),
          timestamp: 1700000000000,
          roundId: 3,
        ),
        FifoAppTrade(
          price: Decimal.parse('40000'),
          quantity: Decimal.parse('0.001'),
          timestamp: 1700000100000,
          roundId: 3,
        ),
      ],
      currentRoundId: 3,
    );

    test('formatBuy should include symbol, price, quantity, round', () {
      final msg = NotificationFormatter.formatBuy(
        symbol: 'BTCUSDC',
        trade: trade,
        state: state,
      );

      expect(msg, contains('🟢'));
      expect(msg, contains('BUY'));
      expect(msg, contains('BTCUSDC'));
      expect(msg, contains('42000.5'));
      expect(msg, contains('0.00100000'));
      expect(msg, contains('3')); // round
    });

    test('formatSell should include P/L info', () {
      final sellTrade = AppTrade(
        symbol: 'BTCUSDC',
        price: MoneyAmount.fromDecimal(Decimal.parse('43000')),
        quantity: QuantityAmount.fromDecimal(Decimal.parse('0.002')),
        isBuy: false,
        timestamp: 1700000200000,
        orderStatus: 'FILLED',
        profit: MoneyAmount.fromDecimal(Decimal.parse('2.0')),
      );

      final msg = NotificationFormatter.formatSell(
        symbol: 'BTCUSDC',
        trade: sellTrade,
        state: state,
        profitPercent: 2.38,
      );

      expect(msg, contains('🔴'));
      expect(msg, contains('SELL'));
      expect(msg, contains('📈'));
      expect(msg, contains('+2.38%'));
      expect(msg, contains('12.5'));
      expect(msg, contains('2')); // successful rounds
    });

    test('formatSell with negative profit shows 📉 and negative %', () {
      final sellTrade = AppTrade(
        symbol: 'BTCUSDC',
        price: MoneyAmount.fromDecimal(Decimal.parse('40000')),
        quantity: QuantityAmount.fromDecimal(Decimal.parse('0.001')),
        isBuy: false,
        timestamp: 1700000200000,
        orderStatus: 'FILLED',
      );

      final msg = NotificationFormatter.formatSell(
        symbol: 'BTCUSDC',
        trade: sellTrade,
        state: state,
        profitPercent: -4.76,
      );

      expect(msg, contains('📉'));
      expect(msg, contains('-4.76%'));
    });

    test('formatDca should include open positions and average price', () {
      final msg = NotificationFormatter.formatDca(
        symbol: 'BTCUSDC',
        trade: trade,
        state: stateWithTrades,
      );

      expect(msg, contains('🔵'));
      expect(msg, contains('DCA BUY'));
      expect(msg, contains('2')); // open positions
      expect(msg, contains('BTCUSDC'));
    });

    test('formatError should include action and error message', () {
      final msg = NotificationFormatter.formatError(
        symbol: 'BTCUSDC',
        action: 'BUY',
        errorMessage: 'Insufficient balance',
      );

      expect(msg, contains('⚠️'));
      expect(msg, contains('ERRORE'));
      expect(msg, contains('BUY'));
      expect(msg, contains('Insufficient balance'));
    });

    test('formatDustDiscard should include symbol and price', () {
      final msg = NotificationFormatter.formatDustDiscard(
        symbol: 'BTCUSDC',
        price: 42000.50,
      );

      expect(msg, contains('🧹'));
      expect(msg, contains('DUST DISCARD'));
      expect(msg, contains('BTCUSDC'));
      expect(msg, contains('42000.5'));
    });
  });
}
