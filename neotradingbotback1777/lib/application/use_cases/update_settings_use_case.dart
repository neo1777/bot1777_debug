import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/settings_repository.dart';
import 'package:neotradingbotback1777/core/config/trading_constants.dart';

class UpdateSettings {
  final SettingsRepository _repository;
  UpdateSettings(this._repository);

  Future<Either<Failure, void>> call(AppSettings settings) {
    // Validazioni estese e difensive
    if (settings.tradeAmount <= 0) {
      return Future.value(
        const Left(ValidationFailure(message: 'Trade Amount deve essere > 0.')),
      );
    }

    // Percentuali: range ragionevoli
    if (settings.profitTargetPercentage <= 0 ||
        settings.profitTargetPercentage >=
            TradingConstants.percentageBoundary) {
      return Future.value(
        Left(ValidationFailure(
            message:
                'Profit Target deve essere compreso tra 0 e ${TradingConstants.percentageBoundary.toInt()} (esclusi).')),
      );
    }

    if (settings.stopLossPercentage <= 0 ||
        settings.stopLossPercentage >= TradingConstants.percentageBoundary) {
      return Future.value(
        Left(ValidationFailure(
            message:
                'Stop Loss deve essere compreso tra 0 e ${TradingConstants.percentageBoundary.toInt()} (esclusi).')),
      );
    }

    if (settings.dcaDecrementPercentage < 0 ||
        settings.dcaDecrementPercentage >
            TradingConstants.maxDcaDecrementPercentage) {
      return Future.value(
        Left(ValidationFailure(
            message:
                'DCA Decrement deve essere tra 0 e ${TradingConstants.maxDcaDecrementPercentage.toInt()}.')),
      );
    }

    if (settings.maxOpenTrades <= 0) {
      return Future.value(
        const Left(ValidationFailure(
            message: 'Max Open Trades deve essere almeno 1.')),
      );
    }

    // Warm-up e soglie: non negativi
    if (settings.initialWarmupTicks < 0) {
      return Future.value(
        const Left(ValidationFailure(
            message: 'Warm-up ticks non può essere negativo.')),
      );
    }
    if (settings.initialWarmupSeconds < 0) {
      return Future.value(
        const Left(ValidationFailure(
            message: 'Warm-up seconds non può essere negativo.')),
      );
    }
    if (settings.initialSignalThresholdPct < 0 ||
        settings.initialSignalThresholdPct >=
            TradingConstants.percentageBoundary) {
      return Future.value(
        Left(ValidationFailure(
            message:
                'Soglia segnale iniziale deve essere tra 0 e ${TradingConstants.percentageBoundary.toInt()} (0 disattiva).')),
      );
    }

    // Coerenza policy primo acquisto: se buyOnStart=false, richiedi almeno uno tra warmupTicks, warmupSeconds, signalThreshold
    if (!settings.buyOnStart &&
        settings.initialWarmupTicks == 0 &&
        settings.initialWarmupSeconds == 0 &&
        settings.initialSignalThresholdPct == 0) {
      return Future.value(
        const Left(ValidationFailure(
            message:
                'Per buyOnStart=false è richiesto almeno uno tra: initialWarmupTicks > 0, initialWarmupSeconds > 0, initialSignalThresholdPct > 0.')),
      );
    }

    return _repository.saveSettings(settings);
  }
}
