import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/validation/input_validator.dart';
import 'package:logger/logger.dart';

export 'package:neotradingbotback1777/core/validation/input_validator.dart';

/// Middleware di validazione centralizzato per endpoint gRPC
class ValidationInterceptor {
  final Logger _log = LogManager.getLogger();

  /// Valida un simbolo di trading
  ValidationResult validateSymbol(String symbol) {
    return InputValidator.validateSymbol(symbol);
  }

  /// Valida un prezzo
  ValidationResult validatePrice(double price) {
    return InputValidator.validatePrice(price);
  }

  /// Valida una quantità
  ValidationResult validateQuantity(double quantity) {
    return InputValidator.validateQuantity(quantity);
  }

  /// Valida una percentuale
  ValidationResult validatePercentage(double percentage) {
    return InputValidator.validatePercentage(percentage);
  }

  /// Valida un importo di trading
  ValidationResult validateTradeAmount(double amount) {
    return InputValidator.validateTradeAmount(amount);
  }

  /// Valida un numero di trade massimi
  ValidationResult validateMaxTrades(int maxTrades) {
    return InputValidator.validateMaxTrades(maxTrades);
  }

  /// Valida un timeout in secondi
  ValidationResult validateTimeout(int timeoutSeconds) {
    return InputValidator.validateTimeout(timeoutSeconds);
  }

  /// Valida un livello di log
  ValidationResult validateLogLevel(String logLevel) {
    return InputValidator.validateLogLevel(logLevel);
  }

  /// Valida un booleano
  ValidationResult validateBoolean(bool value) {
    return ValidationResult.success(value);
  }

  /// Valida una stringa generica
  ValidationResult validateString(
    String value, {
    int? minLength,
    int? maxLength,
    String? pattern,
    String? fieldName,
  }) {
    if (value.isEmpty && minLength != null && minLength > 0) {
      return ValidationResult.failure(
          '${fieldName ?? 'String'} cannot be empty');
    }

    if (minLength != null && value.length < minLength) {
      return ValidationResult.failure(
          '${fieldName ?? 'String'} too short (min: $minLength characters)');
    }

    if (maxLength != null && value.length > maxLength) {
      return ValidationResult.failure(
          '${fieldName ?? 'String'} too long (max: $maxLength characters)');
    }

    if (pattern != null && !RegExp(pattern).hasMatch(value)) {
      return ValidationResult.failure(
          '${fieldName ?? 'String'} format is invalid');
    }

    return ValidationResult.success(value);
  }

  /// Valida un numero intero
  ValidationResult validateInteger(
    int value, {
    int? minValue,
    int? maxValue,
    String? fieldName,
  }) {
    if (minValue != null && value < minValue) {
      return ValidationResult.failure(
          '${fieldName ?? 'Integer'} too low (min: $minValue)');
    }

    if (maxValue != null && value > maxValue) {
      return ValidationResult.failure(
          '${fieldName ?? 'Integer'} too high (max: $maxValue)');
    }

    return ValidationResult.success(value);
  }

  /// Valida un numero intero positivo
  ValidationResult validatePositiveInteger(int value, {String? fieldName}) {
    return validateInteger(value, minValue: 1, fieldName: fieldName);
  }

  /// Valida un numero intero non negativo
  ValidationResult validateNonNegativeInteger(int value, {String? fieldName}) {
    return validateInteger(value, minValue: 0, fieldName: fieldName);
  }

  /// Valida un timestamp Unix
  ValidationResult validateTimestamp(int timestamp) {
    return InputValidator.validateTimestamp(timestamp);
  }

  /// Valida un array di elementi
  ValidationResult validateArray<T>(
    List<T> array, {
    int? minLength,
    int? maxLength,
    String? fieldName,
  }) {
    if (minLength != null && array.length < minLength) {
      return ValidationResult.failure(
          '${fieldName ?? 'Array'} too short (min: $minLength items)');
    }

    if (maxLength != null && array.length > maxLength) {
      return ValidationResult.failure(
          '${fieldName ?? 'Array'} too long (max: $maxLength items)');
    }

    return ValidationResult.success(array);
  }

  /// Valida un oggetto non null
  ValidationResult validateNotNull<T>(T? value, {String? fieldName}) {
    if (value == null) {
      return ValidationResult.failure('${fieldName ?? 'Value'} cannot be null');
    }

    return ValidationResult.success(value);
  }

  /// Combina più validazioni
  ValidationResult combineValidations(List<ValidationResult> results) {
    return InputValidator.combineValidations(results);
  }

  /// Logga una validazione fallita
  void logValidationFailure(String operation, String error) {
    _log.w('Validation failed for $operation: $error');
  }

  /// Logga una validazione riuscita
  void logValidationSuccess(String operation) {
    _log.d('Validation successful for $operation');
  }
}

/// Singleton per il validatore globale
class GlobalValidator {
  static final ValidationInterceptor _instance = ValidationInterceptor();

  static ValidationInterceptor get instance => _instance;

  /// Valida un simbolo globalmente
  static ValidationResult validateSymbol(String symbol) {
    return _instance.validateSymbol(symbol);
  }

  /// Valida un prezzo globalmente
  static ValidationResult validatePrice(double price) {
    return _instance.validatePrice(price);
  }

  /// Valida una quantità globalmente
  static ValidationResult validateQuantity(double quantity) {
    return _instance.validateQuantity(quantity);
  }

  /// Valida una percentuale globalmente
  static ValidationResult validatePercentage(double percentage) {
    return _instance.validatePercentage(percentage);
  }

  /// Valida un importo di trading globalmente
  static ValidationResult validateTradeAmount(double amount) {
    return _instance.validateTradeAmount(amount);
  }

  /// Valida un numero di trade massimi globalmente
  static ValidationResult validateMaxTrades(int maxTrades) {
    return _instance.validateMaxTrades(maxTrades);
  }

  /// Valida un timeout globalmente
  static ValidationResult validateTimeout(int timeoutSeconds) {
    return _instance.validateTimeout(timeoutSeconds);
  }

  /// Valida un livello di log globalmente
  static ValidationResult validateLogLevel(String logLevel) {
    return _instance.validateLogLevel(logLevel);
  }
}
