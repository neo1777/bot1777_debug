import 'sanitizer.dart';

/// Result of input validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final dynamic value;

  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.value,
  });

  factory ValidationResult.success(dynamic value) {
    return ValidationResult._(isValid: true, value: value);
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(isValid: false, errorMessage: message);
  }
}

/// Input validator for trading application
class InputValidator {
  // Private constructor to prevent instantiation
  InputValidator._();

  /// Validate trading amount input
  static ValidationResult validateTradingAmount(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Amount cannot be empty');
    }

    final sanitized = Sanitizer.sanitizeNumeric(input);
    final amount = double.tryParse(sanitized);

    if (amount == null) {
      return ValidationResult.error('Invalid numeric format');
    }

    if (amount <= 0) {
      return ValidationResult.error('Amount must be positive');
    }

    if (amount < 10.0) {
      return ValidationResult.error('Minimum amount is 10.0');
    }

    if (amount > 100000.0) {
      return ValidationResult.error('Maximum amount is 100,000.0');
    }

    return ValidationResult.success(amount);
  }

  /// Validate percentage input (for profit target, stop loss, etc.)
  static ValidationResult validatePercentage(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Percentage cannot be empty');
    }

    final sanitized = Sanitizer.sanitizeNumeric(input);
    final percentage = double.tryParse(sanitized);

    if (percentage == null) {
      return ValidationResult.error('Invalid numeric format');
    }

    if (percentage < 0) {
      return ValidationResult.error('Percentage must be positive');
    }

    if (percentage > 1000) {
      return ValidationResult.error('Percentage cannot exceed 1000%');
    }

    return ValidationResult.success(percentage);
  }

  /// Validate symbol input
  static ValidationResult validateSymbol(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Symbol cannot be empty');
    }

    final sanitized = Sanitizer.sanitizeSymbol(input);

    if (sanitized.length < 6) {
      return ValidationResult.error('Symbol must be at least 6 characters');
    }

    if (sanitized.length > 20) {
      return ValidationResult.error('Symbol cannot exceed 20 characters');
    }

    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(sanitized)) {
      return ValidationResult.error(
        'Symbol must contain only uppercase letters and numbers',
      );
    }

    return ValidationResult.success(sanitized);
  }

  /// Validate quantity input
  static ValidationResult validateQuantity(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Quantity cannot be empty');
    }

    final sanitized = Sanitizer.sanitizeNumeric(input);
    final quantity = double.tryParse(sanitized);

    if (quantity == null) {
      return ValidationResult.error('Invalid numeric format');
    }

    if (quantity <= 0) {
      return ValidationResult.error('Quantity must be positive');
    }

    if (quantity < 0.00000001) {
      return ValidationResult.error('Quantity too small (minimum: 0.00000001)');
    }

    if (quantity > 1000000) {
      return ValidationResult.error('Quantity too large (maximum: 1,000,000)');
    }

    return ValidationResult.success(quantity);
  }

  /// Validate price input
  static ValidationResult validatePrice(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Price cannot be empty');
    }

    final sanitized = Sanitizer.sanitizeNumeric(input);
    final price = double.tryParse(sanitized);

    if (price == null) {
      return ValidationResult.error('Invalid numeric format');
    }

    if (price <= 0) {
      return ValidationResult.error('Price must be positive');
    }

    if (price < 0.00000001) {
      return ValidationResult.error('Price too small (minimum: 0.00000001)');
    }

    if (price > 1000000) {
      return ValidationResult.error('Price too large (maximum: 1,000,000)');
    }

    return ValidationResult.success(price);
  }

  /// Validate integer input
  static ValidationResult validateInteger(
    String input, {
    int? min,
    int? max,
    String? fieldName,
  }) {
    if (input.isEmpty) {
      return ValidationResult.error('${fieldName ?? 'Value'} cannot be empty');
    }

    final sanitized = Sanitizer.sanitizeNumeric(input);
    final value = int.tryParse(sanitized);

    if (value == null) {
      return ValidationResult.error('Invalid integer format');
    }

    if (min != null && value < min) {
      return ValidationResult.error(
        '${fieldName ?? 'Value'} must be at least $min',
      );
    }

    if (max != null && value > max) {
      return ValidationResult.error(
        '${fieldName ?? 'Value'} cannot exceed $max',
      );
    }

    return ValidationResult.success(value);
  }

  /// Validate boolean input
  static ValidationResult validateBoolean(String input) {
    final sanitized = Sanitizer.sanitizeBoolean(input);

    if (sanitized == 'true' || sanitized == '1' || sanitized == 'yes') {
      return ValidationResult.success(true);
    }

    if (sanitized == 'false' || sanitized == '0' || sanitized == 'no') {
      return ValidationResult.success(false);
    }

    return ValidationResult.error('Invalid boolean value');
  }

  /// Validate email input
  static ValidationResult validateEmail(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('Email cannot be empty');
    }

    final sanitized = Sanitizer.sanitizeEmail(input);

    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(sanitized)) {
      return ValidationResult.error('Invalid email format');
    }

    if (sanitized.length > 254) {
      return ValidationResult.error('Email too long');
    }

    return ValidationResult.success(sanitized);
  }

  /// Validate API key input
  static ValidationResult validateApiKey(String input) {
    if (input.isEmpty) {
      return ValidationResult.error('API key cannot be empty');
    }

    final sanitized = Sanitizer.sanitizeApiKey(input);

    if (sanitized.length < 20) {
      return ValidationResult.error('API key too short');
    }

    if (sanitized.length > 100) {
      return ValidationResult.error('API key too long');
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(sanitized)) {
      return ValidationResult.error(
        'API key must contain only alphanumeric characters',
      );
    }

    return ValidationResult.success(sanitized);
  }

  /// Validate multiple inputs at once
  static Map<String, ValidationResult> validateMultiple(
    Map<String, String> inputs,
  ) {
    final results = <String, ValidationResult>{};

    for (final entry in inputs.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key.toLowerCase()) {
        case 'amount':
        case 'tradingamount':
          results[key] = validateTradingAmount(value);
          break;
        case 'percentage':
        case 'profit':
        case 'stoploss':
          results[key] = validatePercentage(value);
          break;
        case 'symbol':
          results[key] = validateSymbol(value);
          break;
        case 'quantity':
          results[key] = validateQuantity(value);
          break;
        case 'price':
          results[key] = validatePrice(value);
          break;
        case 'email':
          results[key] = validateEmail(value);
          break;
        case 'apikey':
          results[key] = validateApiKey(value);
          break;
        default:
          results[key] = ValidationResult.success(value);
      }
    }

    return results;
  }

  /// Check if all validation results are valid
  static bool areAllValid(Map<String, ValidationResult> results) {
    return results.values.every((result) => result.isValid);
  }

  /// Get all error messages from validation results
  static List<String> getAllErrors(Map<String, ValidationResult> results) {
    return results.values
        .where((result) => !result.isValid)
        .map((result) => result.errorMessage!)
        .toList();
  }
}
