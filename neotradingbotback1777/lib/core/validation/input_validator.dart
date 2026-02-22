import 'package:neotradingbotback1777/core/config/trading_constants.dart';

/// Centralized input validator for the application.
/// Used by Domain entities, Use Cases, and Presentation layer.
class InputValidator {
  /// Validates a trading symbol.
  static ValidationResult validateSymbol(String symbol) {
    if (symbol.isEmpty) {
      return ValidationResult.failure('Symbol cannot be empty');
    }

    final trimmedSymbol = symbol.trim().toUpperCase();

    // Format validation: letters and numbers only, reasonable length
    final symbolPattern =
        '^[A-Z0-9]{${TradingConstants.symbolMinLength},${TradingConstants.symbolMaxLength}}\$';
    if (!RegExp(symbolPattern).hasMatch(trimmedSymbol)) {
      return ValidationResult.failure(
          'Invalid symbol format. Must be ${TradingConstants.symbolMinLength}-${TradingConstants.symbolMaxLength} characters, letters and numbers only');
    }

    return ValidationResult.success(trimmedSymbol);
  }

  /// Validates a price.
  static ValidationResult validatePrice(double price) {
    if (!price.isFinite) {
      return ValidationResult.failure('Price must be a finite number');
    }

    if (price <= 0) {
      return ValidationResult.failure('Price must be greater than 0');
    }

    // Check for extreme values that could cause overflow
    if (price > TradingConstants.priceMaxValue) {
      return ValidationResult.failure(
          'Price too high (max: ${TradingConstants.priceMaxValue})');
    }

    if (price < TradingConstants.priceMinValue) {
      return ValidationResult.failure(
          'Price too low (min: ${TradingConstants.priceMinValue})');
    }

    return ValidationResult.success(price);
  }

  /// Validates a quantity.
  static ValidationResult validateQuantity(double quantity) {
    if (!quantity.isFinite) {
      return ValidationResult.failure('Quantity must be a finite number');
    }

    if (quantity <= 0) {
      return ValidationResult.failure('Quantity must be greater than 0');
    }

    // Check for extreme values
    if (quantity > TradingConstants.quantityMaxValue) {
      return ValidationResult.failure(
          'Quantity too high (max: ${TradingConstants.quantityMaxValue})');
    }

    if (quantity < TradingConstants.quantityMinValue) {
      return ValidationResult.failure(
          'Quantity too low (min: ${TradingConstants.quantityMinValue})');
    }

    return ValidationResult.success(quantity);
  }

  /// Validates a percentage.
  static ValidationResult validatePercentage(double percentage) {
    if (!percentage.isFinite) {
      return ValidationResult.failure('Percentage must be a finite number');
    }

    // Negative percentages are valid (e.g. for stop loss)
    if (percentage < TradingConstants.percentageMinValue) {
      return ValidationResult.failure(
          'Percentage too low (min: ${TradingConstants.percentageMinValue}%)');
    }

    if (percentage > TradingConstants.percentageMaxValue) {
      return ValidationResult.failure(
          'Percentage too high (max: ${TradingConstants.percentageMaxValue}%)');
    }

    return ValidationResult.success(percentage);
  }

  /// Validates a trade amount.
  static ValidationResult validateTradeAmount(double amount) {
    if (!amount.isFinite) {
      return ValidationResult.failure('Trade amount must be a finite number');
    }

    if (amount <= 0) {
      return ValidationResult.failure('Trade amount must be greater than 0');
    }

    // Safety limits for trade amounts
    if (amount > TradingConstants.tradeAmountMaxValue) {
      return ValidationResult.failure(
          'Trade amount too high (max: ${TradingConstants.tradeAmountMaxValue})');
    }

    if (amount < TradingConstants.tradeAmountMinValue) {
      return ValidationResult.failure(
          'Trade amount too low (min: ${TradingConstants.tradeAmountMinValue})');
    }

    return ValidationResult.success(amount);
  }

  /// Validates a maximum number of trades.
  static ValidationResult validateMaxTrades(int maxTrades) {
    if (maxTrades <= 0) {
      return ValidationResult.failure('Max trades must be greater than 0');
    }

    if (maxTrades > TradingConstants.maxTradesMaxValue) {
      return ValidationResult.failure(
          'Max trades too high (max: ${TradingConstants.maxTradesMaxValue})');
    }

    return ValidationResult.success(maxTrades);
  }

  /// Validates a timeout in seconds.
  static ValidationResult validateTimeout(int timeoutSeconds) {
    if (timeoutSeconds <= 0) {
      return ValidationResult.failure('Timeout must be greater than 0');
    }

    if (timeoutSeconds > TradingConstants.timeoutMaxValue) {
      return ValidationResult.failure(
          'Timeout too high (max: ${TradingConstants.timeoutMaxValue} seconds)');
    }

    return ValidationResult.success(timeoutSeconds);
  }

  /// Validates a log level.
  static ValidationResult validateLogLevel(String logLevel) {
    final validLevels = [
      'trace',
      'debug',
      'info',
      'warning',
      'error',
      'fatal',
      'off'
    ];
    final normalizedLevel = logLevel.toLowerCase().trim();

    if (!validLevels.contains(normalizedLevel)) {
      return ValidationResult.failure(
          'Invalid log level. Valid levels: ${validLevels.join(', ')}');
    }

    return ValidationResult.success(normalizedLevel);
  }

  /// Validates cooldown seconds.
  static ValidationResult validateCooldown(double seconds,
      {String? fieldName}) {
    if (!seconds.isFinite) {
      return ValidationResult.failure(
          '${fieldName ?? 'Cooldown'} must be a finite number');
    }

    if (seconds < 0) {
      return ValidationResult.failure(
          '${fieldName ?? 'Cooldown'} cannot be negative');
    }

    if (seconds > 86400) {
      return ValidationResult.failure(
          '${fieldName ?? 'Cooldown'} too high (max: 86400 seconds)');
    }

    return ValidationResult.success(seconds);
  }

  /// Validates warmup ticks.
  static ValidationResult validateWarmupTicks(int ticks) {
    if (ticks < 0) {
      return ValidationResult.failure('Warmup ticks cannot be negative');
    }

    if (ticks > 10000) {
      return ValidationResult.failure('Warmup ticks too high (max: 10000)');
    }

    return ValidationResult.success(ticks);
  }

  /// Validates cycles count.
  static ValidationResult validateCycles(int cycles) {
    if (cycles < 0) {
      return ValidationResult.failure('Cycles cannot be negative');
    }

    if (cycles > 1000000) {
      return ValidationResult.failure('Cycles too high (max: 1000000)');
    }

    return ValidationResult.success(cycles);
  }

  /// Validates generic percentage (0-100 range strict).
  static ValidationResult validateStrictPercentage(double percentage,
      {String? fieldName}) {
    if (!percentage.isFinite) {
      return ValidationResult.failure(
          '${fieldName ?? 'Percentage'} must be a finite number');
    }

    if (percentage < 0) {
      return ValidationResult.failure(
          '${fieldName ?? 'Percentage'} cannot be negative');
    }

    if (percentage > 100.0) {
      return ValidationResult.failure(
          '${fieldName ?? 'Percentage'} cannot exceed 100%');
    }

    return ValidationResult.success(percentage);
  }

  /// Validates a Unix timestamp.
  static ValidationResult validateTimestamp(int timestamp) {
    if (timestamp <= 0) {
      return ValidationResult.failure('Timestamp must be positive');
    }

    // Check for unrealistic future timestamps (100 years in the future)
    final maxTimestamp =
        DateTime.now().add(Duration(days: 365 * 100)).millisecondsSinceEpoch;
    if (timestamp > maxTimestamp) {
      return ValidationResult.failure('Timestamp too far in the future');
    }

    // Check for timestamps too old (100 years in the past)
    final minTimestamp = DateTime.now()
        .subtract(Duration(days: 365 * 100))
        .millisecondsSinceEpoch;
    if (timestamp < minTimestamp) {
      return ValidationResult.failure('Timestamp too old');
    }

    return ValidationResult.success(timestamp);
  }

  /// Combines multiple validations.
  static ValidationResult combineValidations(List<ValidationResult> results) {
    final failures = results.where((r) => !r.isValid).toList();

    if (failures.isNotEmpty) {
      final messages = failures.map((f) => f.error).join('; ');
      return ValidationResult.failure(messages);
    }

    return ValidationResult.success(null);
  }
}

/// Result of a validation.
class ValidationResult {
  final bool isValid;
  final String? error;
  final dynamic value;

  ValidationResult._({
    required this.isValid,
    this.error,
    this.value,
  });

  factory ValidationResult.success(dynamic value) {
    return ValidationResult._(isValid: true, value: value);
  }

  factory ValidationResult.failure(String error) {
    return ValidationResult._(isValid: false, error: error);
  }

  /// Gets the validated value or throws an exception.
  T getValue<T>() {
    if (!isValid) {
      throw ValidationException(error ?? 'Validation failed');
    }
    return value as T;
  }

  /// Gets the validated value with a fallback.
  T getValueOrDefault<T>(T defaultValue) {
    if (!isValid) {
      return defaultValue;
    }
    return value as T;
  }
}

/// Validation exception.
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
