import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/core/validation/input_validator.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';

/// Servizio di dominio per la validazione delle impostazioni di trading.
/// Centralizza tutte le regole di validazione business per garantire
/// coerenza e manutenibilità.
class SettingsValidationService {
  final UnifiedErrorHandler _errorHandler;

  SettingsValidationService({UnifiedErrorHandler? errorHandler})
      : _errorHandler = errorHandler ?? UnifiedErrorHandler();

  /// Valida le impostazioni di trading e restituisce
  /// le impostazioni o un errore di validazione.
  Either<Failure, AppSettings> validateSettings(AppSettings settings) {
    return _errorHandler.handleSyncOperation(
      () {
        final results = <ValidationResult>[];

        // Trade Amount
        results.add(InputValidator.validateTradeAmount(settings.tradeAmount));
        if (settings.tradeAmount > 1000000.0) {
          results.add(
              ValidationResult.failure('Trade amount too high (max: 1000000)'));
        }

        // Percentages
        results.add(
            InputValidator.validatePercentage(settings.profitTargetPercentage));
        results.add(InputValidator.validateStrictPercentage(
            settings.stopLossPercentage,
            fieldName: 'stopLossPercentage'));
        results.add(
            InputValidator.validatePercentage(settings.dcaDecrementPercentage));

        // Open Trades
        results.add(InputValidator.validateMaxTrades(settings.maxOpenTrades));

        // Warmup
        results.add(
            InputValidator.validateWarmupTicks(settings.initialWarmupTicks));
        results.add(InputValidator.validateCooldown(
            settings.initialWarmupSeconds,
            fieldName: 'initialWarmupSeconds'));

        // Signal Threshold
        results.add(InputValidator.validateStrictPercentage(
            settings.initialSignalThresholdPct,
            fieldName: 'initialSignalThresholdPct'));

        // Cooldowns
        results.add(InputValidator.validateCooldown(settings.buyCooldownSeconds,
            fieldName: 'buyCooldownSeconds'));
        results.add(InputValidator.validateCooldown(settings.dcaCooldownSeconds,
            fieldName: 'dcaCooldownSeconds'));

        // Overage
        if (settings.maxBuyOveragePct < 0 || settings.maxBuyOveragePct > 50.0) {
          results.add(ValidationResult.failure(
              'maxBuyOveragePct must be between 0% and 50%'));
        }

        // Cycles
        results.add(InputValidator.validateCycles(settings.maxCycles));

        final combined = InputValidator.combineValidations(results);
        if (!combined.isValid) {
          throw ValidationFailure(
            message: combined.error!,
            code: 'VALIDATION_ERROR',
            details: {'errors': combined.error},
          );
        }

        return settings;
      },
      operationName: 'validateSettings',
    );
  }

  /// Applica limiti di sicurezza alle impostazioni validate.
  /// Restituisce le impostazioni con valori clampati se necessario.
  AppSettings applySecurityLimits(AppSettings settings) {
    final absoluteMaxTradeAmount = 100.0; // $100 hard limit
    final effectiveCap = settings.maxTradeAmountCap > 0
        ? settings.maxTradeAmountCap
        : absoluteMaxTradeAmount;

    final adjustedTradeAmount = settings.tradeAmount > effectiveCap
        ? effectiveCap
        : settings.tradeAmount;

    if (adjustedTradeAmount != settings.tradeAmount) {
      return settings.copyWith(tradeAmount: adjustedTradeAmount);
    }

    return settings;
  }
}
