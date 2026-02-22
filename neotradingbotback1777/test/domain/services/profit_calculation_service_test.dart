import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/services/profit_calculation_service.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';
import 'package:test/test.dart';

void main() {
  late ProfitCalculationService service;

  setUp(() {
    service = ProfitCalculationService();
  });

  // Helper per creare un trade
  AppTrade createTrade({
    required String symbol,
    required bool isBuy,
    required double price,
    required double quantity,
    required int timestamp,
  }) {
    return AppTrade(
      symbol: symbol,
      isBuy: isBuy,
      price: MoneyAmount.fromDouble(price),
      quantity: QuantityAmount.fromDouble(quantity),
      timestamp: timestamp,
      orderStatus: 'FILLED',
    );
  }

  group('ProfitCalculationService', () {
    test('should calculate profit correctly for a simple buy-sell scenario',
        () {
      // ARRANGE
      final trades = [
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: true,
            price: 100,
            quantity: 1,
            timestamp: 1),
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: false,
            price: 120,
            quantity: 1,
            timestamp: 2),
      ];

      // ACT
      final result = service.calculateFifoProfit(trades);
      final sellTrade = result.firstWhere((t) => !t.isBuy);

      // ASSERT
      expect(sellTrade.profit?.toDouble(), 20.0);
    });

    test('should calculate loss correctly for a simple buy-sell scenario', () {
      // ARRANGE
      final trades = [
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: true,
            price: 100,
            quantity: 1,
            timestamp: 1),
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: false,
            price: 80,
            quantity: 1,
            timestamp: 2),
      ];

      // ACT
      final result = service.calculateFifoProfit(trades);
      final sellTrade = result.firstWhere((t) => !t.isBuy);

      // ASSERT
      expect(sellTrade.profit?.toDouble(), -20.0);
    });

    test('should calculate profit correctly with multiple buys (DCA)', () {
      // ARRANGE
      final trades = [
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: true,
            price: 100,
            quantity: 1,
            timestamp: 1),
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: true,
            price: 80,
            quantity: 1,
            timestamp: 2),
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: false,
            price: 110,
            quantity: 2,
            timestamp: 3),
      ];
      // Costo totale = (1*100) + (1*80) = 180. Ricavo = 2*110 = 220. Profitto = 40.

      // ACT
      final result = service.calculateFifoProfit(trades);
      final sellTrade = result.firstWhere((t) => !t.isBuy);

      // ASSERT
      expect(sellTrade.profit?.toDouble(), 40.0);
    });

    test('should handle partial sells correctly according to FIFO', () {
      // ARRANGE
      final trades = [
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: true,
            price: 100,
            quantity: 1,
            timestamp: 1), // Consumato da prima vendita
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: true,
            price: 150,
            quantity: 1,
            timestamp: 2), // Consumato da seconda vendita
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: false,
            price: 120,
            quantity: 1,
            timestamp: 3), // Prima vendita
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: false,
            price: 160,
            quantity: 1,
            timestamp: 4), // Seconda vendita
      ];
      // Profitto 1 = (1*120) - (1*100) = 20
      // Profitto 2 = (1*160) - (1*150) = 10

      // ACT
      final result = service.calculateFifoProfit(trades);
      final sell1 = result.firstWhere((t) => t.timestamp == 3);
      final sell2 = result.firstWhere((t) => t.timestamp == 4);

      // ASSERT
      expect(sell1.profit?.toDouble(), 20.0);
      expect(sell2.profit?.toDouble(), 10.0);
    });

    test('should calculate profits independently for multiple symbols', () {
      // ARRANGE
      final trades = [
        // BTC: profitto 20
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: true,
            price: 100,
            quantity: 1,
            timestamp: 1),
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: false,
            price: 120,
            quantity: 1,
            timestamp: 2),
        // ETH: perdita 50
        createTrade(
            symbol: 'ETHUSDC',
            isBuy: true,
            price: 200,
            quantity: 1,
            timestamp: 3),
        createTrade(
            symbol: 'ETHUSDC',
            isBuy: false,
            price: 150,
            quantity: 1,
            timestamp: 4),
      ];

      // ACT
      final result = service.calculateFifoProfit(trades);
      final btcSell =
          result.firstWhere((t) => t.symbol == 'BTCUSDC' && !t.isBuy);
      final ethSell =
          result.firstWhere((t) => t.symbol == 'ETHUSDC' && !t.isBuy);

      // ASSERT
      expect(btcSell.profit?.toDouble(), 20.0);
      expect(ethSell.profit?.toDouble(), -50.0);
    });

    test('should return an empty list if no trades are provided', () {
      // ARRANGE
      final List<AppTrade> trades = [];

      // ACT
      final result = service.calculateFifoProfit(trades);

      // ASSERT
      expect(result, isEmpty);
    });

    test('should return trades without profit if there are only buys', () {
      // ARRANGE
      final trades = [
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: true,
            price: 100,
            quantity: 1,
            timestamp: 1),
        createTrade(
            symbol: 'BTCUSDC',
            isBuy: true,
            price: 110,
            quantity: 1,
            timestamp: 2),
      ];

      // ACT
      final result = service.calculateFifoProfit(trades);

      // ASSERT
      expect(result.length, 2);
      expect(result.every((t) => t.profit == null), isTrue);
    });
  });
}

