import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Utility class for robust JSON parsing with comprehensive error handling
class JsonParser {
  /// Safely decodes JSON string with proper error handling
  static Either<Failure, Map<String, dynamic>> safeDecode(String jsonString) {
    try {
      if (jsonString.isEmpty) {
        return Left(ValidationFailure(message: 'JSON string is empty'));
      }

      final decoded = jsonDecode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        return Left(ValidationFailure(
            message: 'Expected JSON object but got ${decoded.runtimeType}'));
      }

      return Right(decoded);
    } on FormatException catch (_) {
      return Left(
          ValidationFailure(message: 'Invalid JSON format: $jsonString'));
    } catch (e, stackTrace) {
      UnifiedErrorHandler.handleError(
          'JsonParser.safeDecode (Generic)', e, stackTrace);
      return Left(ValidationFailure(message: 'JSON parsing failed: $e'));
    }
  }

  /// Safely decodes JSON string expecting a List
  static Either<Failure, List<dynamic>> safeDecodeList(String jsonString) {
    try {
      if (jsonString.isEmpty) {
        return Left(ValidationFailure(message: 'JSON string is empty'));
      }

      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        return Left(ValidationFailure(
            message: 'Expected JSON list but got ${decoded.runtimeType}'));
      }

      return Right(decoded);
    } on FormatException catch (_) {
      return Left(
          ValidationFailure(message: 'Invalid JSON format: $jsonString'));
    } catch (e, stackTrace) {
      UnifiedErrorHandler.handleError(
          'JsonParser.safeDecodeList (Generic)', e, stackTrace);
      return Left(ValidationFailure(message: 'JSON parsing failed: $e'));
    }
  }

  /// Safely extracts a required field from JSON with type checking
  static Either<Failure, T> safeExtract<T>(
    Map<String, dynamic> json,
    String field,
    T Function(dynamic) converter,
  ) {
    try {
      if (!json.containsKey(field)) {
        return Left(ValidationFailure(
            message: 'Required field "$field" is missing from JSON'));
      }

      final rawFieldValue = json[field];
      if (rawFieldValue == null) {
        return Left(ValidationFailure(message: 'Field "$field" is null'));
      }

      final convertedValue = converter(rawFieldValue);
      return Right(convertedValue);
    } catch (e, stackTrace) {
      UnifiedErrorHandler.handleError('JsonParser.safeExtract', e, stackTrace);
      return Left(
          ValidationFailure(message: 'Failed to extract field "$field": $e'));
    }
  }

  /// Safely extracts an optional field from JSON with default value
  static T safeExtractOptional<T>(
    Map<String, dynamic> json,
    String field,
    T defaultValue,
    T Function(dynamic) converter,
  ) {
    try {
      if (!json.containsKey(field) || json[field] == null) {
        return defaultValue;
      }

      return converter(json[field]);
    } catch (e, stackTrace) {
      UnifiedErrorHandler.handleError(
          'JsonParser.safeExtractOptional', e, stackTrace);
      return defaultValue;
    }
  }

  /// Safely parses a double from dynamic value
  static Either<Failure, double> safeParseDouble(
      dynamic rawInput, String fieldName) {
    try {
      if (rawInput == null) {
        return Left(ValidationFailure(
            message:
                'Cannot parse null value as double for field "$fieldName"'));
      }

      if (rawInput is double) {
        return Right(rawInput);
      }

      if (rawInput is int) {
        return Right(rawInput.toDouble());
      }

      if (rawInput is String) {
        final parsed = double.tryParse(rawInput);
        if (parsed == null) {
          return Left(ValidationFailure(
              message:
                  'Cannot parse "$rawInput" as double for field "$fieldName"'));
        }
        return Right(parsed);
      }

      return Left(ValidationFailure(
          message:
              'Unsupported type ${rawInput.runtimeType} for double field "$fieldName"'));
    } catch (e, stackTrace) {
      UnifiedErrorHandler.handleError(
          'JsonParser.safeParseDouble', e, stackTrace);
      return Left(ValidationFailure(
          message: 'Error parsing double for field "$fieldName": $e'));
    }
  }

  /// Safely parses an integer from dynamic value
  static Either<Failure, int> safeParseInt(dynamic rawInput, String fieldName) {
    try {
      if (rawInput == null) {
        return Left(ValidationFailure(
            message: 'Cannot parse null value as int for field "$fieldName"'));
      }

      if (rawInput is int) {
        return Right(rawInput);
      }

      if (rawInput is double) {
        return Right(rawInput.toInt());
      }

      if (rawInput is String) {
        final parsed = int.tryParse(rawInput);
        if (parsed == null) {
          return Left(ValidationFailure(
              message:
                  'Cannot parse "$rawInput" as int for field "$fieldName"'));
        }
        return Right(parsed);
      }

      return Left(ValidationFailure(
          message:
              'Unsupported type ${rawInput.runtimeType} for int field "$fieldName"'));
    } catch (e, stackTrace) {
      UnifiedErrorHandler.handleError('JsonParser.safeParseInt', e, stackTrace);
      return Left(ValidationFailure(
          message: 'Error parsing int for field "$fieldName": $e'));
    }
  }

  /// Safely extracts a list from JSON with type validation
  static Either<Failure, List<T>> safeExtractList<T>(
    Map<String, dynamic> json,
    String field,
    T Function(dynamic) converter,
  ) {
    try {
      if (!json.containsKey(field)) {
        return Left(ValidationFailure(
            message: 'Required list field "$field" is missing from JSON'));
      }

      final rawListValue = json[field];
      if (rawListValue == null) {
        return Left(ValidationFailure(message: 'List field "$field" is null'));
      }

      if (rawListValue is! List) {
        return Left(ValidationFailure(
            message:
                'Field "$field" is not a list, got ${rawListValue.runtimeType}'));
      }

      final List<T> result = [];
      for (int i = 0; i < rawListValue.length; i++) {
        try {
          result.add(converter(rawListValue[i]));
        } catch (e) {
          return Left(ValidationFailure(
              message:
                  'Failed to convert list item at index $i in field "$field": $e'));
        }
      }

      return Right(result);
    } catch (e, stackTrace) {
      UnifiedErrorHandler.handleError(
          'JsonParser.safeExtractList', e, stackTrace);
      return Left(ValidationFailure(
          message: 'Failed to extract list field "$field": $e'));
    }
  }

  /// Safely finds an item in a list by predicate
  static Either<Failure, T> safeFindInList<T>(
    List<T> list,
    bool Function(T) predicate,
    String description,
  ) {
    try {
      final item = list.where(predicate).firstOrNull;
      if (item == null) {
        return Left(
            ValidationFailure(message: 'Could not find $description in list'));
      }
      return Right(item);
    } catch (e, stackTrace) {
      UnifiedErrorHandler.handleError(
          'JsonParser.safeFindInList', e, stackTrace);
      return Left(
          ValidationFailure(message: 'Error finding $description in list: $e'));
    }
  }
}

/// Extension for List to add firstOrNull method if not available
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
