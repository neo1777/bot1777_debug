/// Input sanitizer for security and data consistency
class Sanitizer {
  // Private constructor to prevent instantiation
  Sanitizer._();

  /// Sanitize numeric input by removing non-numeric characters except decimal point
  static String sanitizeNumeric(String input) {
    if (input.isEmpty) return '';

    // Remove all characters except digits, decimal point, and minus sign
    final cleaned = input.replaceAll(RegExp(r'[^0-9.-]'), '');

    // Ensure only one decimal point
    final parts = cleaned.split('.');
    if (parts.length > 2) {
      return '${parts[0]}.${parts.sublist(1).join('')}';
    }

    // Ensure minus sign is only at the beginning
    if (cleaned.contains('-')) {
      final withoutMinus = cleaned.replaceAll('-', '');
      return '-$withoutMinus';
    }

    return cleaned;
  }

  /// Sanitize symbol input by removing invalid characters
  static String sanitizeSymbol(String input) {
    if (input.isEmpty) return '';

    // Convert to uppercase and remove invalid characters
    return input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Sanitize boolean input
  static String sanitizeBoolean(String input) {
    if (input.isEmpty) return '';

    final cleaned = input.toLowerCase().trim();

    // Map common boolean representations
    switch (cleaned) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
      case 'on':
      case 'enabled':
        return 'true';
      case 'false':
      case '0':
      case 'no':
      case 'n':
      case 'off':
      case 'disabled':
        return 'false';
      default:
        return cleaned;
    }
  }

  /// Sanitize email input
  static String sanitizeEmail(String input) {
    if (input.isEmpty) return '';

    // Remove whitespace and convert to lowercase
    return input.trim().toLowerCase();
  }

  /// Sanitize API key input
  static String sanitizeApiKey(String input) {
    if (input.isEmpty) return '';

    // Remove whitespace and invalid characters
    return input.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  /// Sanitize text input by removing potentially dangerous characters
  static String sanitizeText(String input) {
    if (input.isEmpty) return '';

    // Remove HTML tags and script content
    String cleaned = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove script and style content
    cleaned = cleaned.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false),
      '',
    );

    // Remove potentially dangerous characters
    cleaned = cleaned.replaceAll(RegExp(r'[<>"\'\\\]]'), '');

    // Trim whitespace
    return cleaned.trim();
  }

  /// Sanitize URL input
  static String sanitizeUrl(String input) {
    if (input.isEmpty) return '';

    // Remove whitespace
    final cleaned = input.trim();

    // Basic URL validation
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      return 'https://$cleaned';
    }

    return cleaned;
  }

  /// Sanitize file path input
  static String sanitizeFilePath(String input) {
    if (input.isEmpty) return '';

    // Remove potentially dangerous characters
    return input.replaceAll(RegExp(r'[<>:"|?*]'), '');
  }

  /// Sanitize JSON input
  static String sanitizeJson(String input) {
    if (input.isEmpty) return '';

    // Remove potential JSON injection characters
    return input.replaceAll(RegExp(r'[<>"\'\\\]]'), '');
  }

  /// Sanitize SQL input (basic protection)
  static String sanitizeSql(String input) {
    if (input.isEmpty) return '';

    // Remove common SQL injection patterns
    String cleaned = input;

    // Remove SQL keywords
    final sqlKeywords = [
      'SELECT',
      'INSERT',
      'UPDATE',
      'DELETE',
      'DROP',
      'CREATE',
      'ALTER',
      'EXEC',
      'EXECUTE',
      'UNION',
      'OR',
      'AND',
      'WHERE',
      'FROM',
      'INTO',
    ];

    for (final keyword in sqlKeywords) {
      cleaned = cleaned.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }

    // Remove semicolons and quotes
    cleaned = cleaned.replaceAll(RegExp(r'[;\x27"`]'), '');

    return cleaned;
  }

  /// Sanitize HTML input
  static String sanitizeHtml(String input) {
    if (input.isEmpty) return '';

    // Remove all HTML tags
    String cleaned = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode HTML entities
    cleaned = cleaned
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/');

    return cleaned;
  }

  /// Sanitize XML input
  static String sanitizeXml(String input) {
    if (input.isEmpty) return '';

    // Remove XML tags
    String cleaned = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove XML entities
    cleaned = cleaned
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");

    return cleaned;
  }

  /// Sanitize input based on type
  static String sanitizeByType(String input, SanitizationType type) {
    switch (type) {
      case SanitizationType.numeric:
        return sanitizeNumeric(input);
      case SanitizationType.symbol:
        return sanitizeSymbol(input);
      case SanitizationType.boolean:
        return sanitizeBoolean(input);
      case SanitizationType.email:
        return sanitizeEmail(input);
      case SanitizationType.apiKey:
        return sanitizeApiKey(input);
      case SanitizationType.text:
        return sanitizeText(input);
      case SanitizationType.url:
        return sanitizeUrl(input);
      case SanitizationType.filePath:
        return sanitizeFilePath(input);
      case SanitizationType.json:
        return sanitizeJson(input);
      case SanitizationType.sql:
        return sanitizeSql(input);
      case SanitizationType.html:
        return sanitizeHtml(input);
      case SanitizationType.xml:
        return sanitizeXml(input);
    }
  }

  /// Validate and sanitize input
  static String validateAndSanitize(String input, SanitizationType type) {
    if (input.isEmpty) return '';

    final sanitized = sanitizeByType(input, type);

    // Additional validation based on type
    switch (type) {
      case SanitizationType.numeric:
        if (sanitized.isEmpty ||
            !RegExp(r'^-?\d*\.?\d+$').hasMatch(sanitized)) {
          return '';
        }
        break;
      case SanitizationType.symbol:
        if (sanitized.isEmpty || !RegExp(r'^[A-Z0-9]+$').hasMatch(sanitized)) {
          return '';
        }
        break;
      case SanitizationType.email:
        if (sanitized.isEmpty ||
            !RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            ).hasMatch(sanitized)) {
          return '';
        }
        break;
      case SanitizationType.apiKey:
        if (sanitized.isEmpty ||
            !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(sanitized)) {
          return '';
        }
        break;
      default:
        break;
    }

    return sanitized;
  }
}

/// Types of sanitization available
enum SanitizationType {
  numeric,
  symbol,
  boolean,
  email,
  apiKey,
  text,
  url,
  filePath,
  json,
  sql,
  html,
  xml,
}
