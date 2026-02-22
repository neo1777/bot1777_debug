import 'package:neotradingbotfront1777/data/mappers/settings_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;
import 'package:test/test.dart';

void main() {
  group('SettingsMapper — settingsFromProto', () {
    test('[SM-01] maps all fields from proto to domain', () {
      final proto = grpc.Settings(
        tradeAmount: 100.0,
        profitTargetPercentage: 2.5,
        stopLossPercentage: 5.0,
        dcaDecrementPercentage: 1.0,
        maxOpenTrades: 3,
        isTestMode: true,
        buyOnStart: false,
        initialWarmupTicks: 10,
        strictBudget: true,
        buyOnStartRespectWarmup: false,
        dcaCompareAgainstAverage: true,
        maxCycles: 5,
        enableFeeAwareTrading: true,
        tradeAmountStr: '100.0',
        profitTargetPercentageStr: '2.5',
        stopLossPercentageStr: '5.0',
        dcaDecrementPercentageStr: '1.0',
      );

      final result = settingsFromProto(proto);

      expect(result, isA<AppSettings>());
      expect(result.tradeAmount, 100.0);
      expect(result.profitTargetPercentage, 2.5);
      expect(result.stopLossPercentage, 5.0);
      expect(result.maxOpenTrades, 3);
      expect(result.isTestMode, true);
      expect(result.buyOnStart, false);
      expect(result.strictBudget, true);
      expect(result.maxCycles, 5);
      expect(result.enableFeeAwareTrading, true);
    });

    test('[SM-02] prefers string fields over legacy doubles', () {
      final proto = grpc.Settings(
        tradeAmount: 1.0, // Legacy
        tradeAmountStr: '200.0', // New string → should win
      );

      final result = settingsFromProto(proto);
      expect(result.tradeAmount, 200.0);
    });
  });

  group('SettingsMapper — settingsToProto', () {
    test('[SM-03] maps all fields from domain to proto', () {
      final settings = AppSettings(
        tradeAmount: 100.0,
        profitTargetPercentage: 2.5,
        stopLossPercentage: 5.0,
        dcaDecrementPercentage: 1.0,
        maxOpenTrades: 3,
        isTestMode: true,
        buyOnStart: false,
        initialWarmupTicks: 10,
        initialWarmupSeconds: 60.0,
        initialSignalThresholdPct: 0.5,
        dcaCooldownSeconds: 30.0,
        dustRetryCooldownSeconds: 10.0,
        maxTradeAmountCap: 1000.0,
        maxBuyOveragePct: 0.01,
        strictBudget: true,
        buyOnStartRespectWarmup: false,
        buyCooldownSeconds: 15.0,
        dcaCompareAgainstAverage: true,
        maxCycles: 5,
        enableFeeAwareTrading: true,
      );

      final result = settingsToProto(settings);

      expect(result, isA<grpc.Settings>());
      expect(result.tradeAmount, 100.0);
      expect(result.maxOpenTrades, 3);
      expect(result.isTestMode, true);
      expect(result.tradeAmountStr, '100.0');
    });
  });

  group('SettingsMapper — round-trip', () {
    test('[SM-04] domain → proto → domain preserves key values', () {
      final original = AppSettings(
        tradeAmount: 150.0,
        profitTargetPercentage: 3.0,
        stopLossPercentage: 7.0,
        dcaDecrementPercentage: 2.0,
        maxOpenTrades: 5,
        isTestMode: false,
        buyOnStart: true,
        initialWarmupTicks: 20,
        initialWarmupSeconds: 120.0,
        initialSignalThresholdPct: 1.0,
        dcaCooldownSeconds: 60.0,
        dustRetryCooldownSeconds: 20.0,
        maxTradeAmountCap: 2000.0,
        maxBuyOveragePct: 0.02,
        strictBudget: false,
        buyOnStartRespectWarmup: true,
        buyCooldownSeconds: 30.0,
        dcaCompareAgainstAverage: false,
        maxCycles: 10,
        enableFeeAwareTrading: false,
      );

      final proto = settingsToProto(original);
      final restored = settingsFromProto(proto);

      expect(restored.tradeAmount, original.tradeAmount);
      expect(restored.profitTargetPercentage, original.profitTargetPercentage);
      expect(restored.maxOpenTrades, original.maxOpenTrades);
      expect(restored.isTestMode, original.isTestMode);
      expect(restored.maxCycles, original.maxCycles);
    });

    test('[SM-05] fixedQuantity null is mapped to empty string in proto', () {
      final settings = AppSettings(
        tradeAmount: 100.0,
        profitTargetPercentage: 2.5,
        stopLossPercentage: 5.0,
        dcaDecrementPercentage: 1.0,
        maxOpenTrades: 3,
        isTestMode: false,
        buyOnStart: false,
        initialWarmupTicks: 10,
        fixedQuantity: null,
      );

      final proto = settingsToProto(settings);
      expect(proto.fixedQuantityStr, '');
    });
  });
}

