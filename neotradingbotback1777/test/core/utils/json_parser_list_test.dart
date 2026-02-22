import 'package:neotradingbotback1777/core/utils/json_parser.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:test/test.dart';

void main() {
  group('JsonParser.safeDecodeList', () {
    test('should successfully decode valid JSON array', () {
      // Arrange
      const jsonString = '[1, 2, 3, 4, 5]';

      // Act
      final result = JsonParser.safeDecodeList(jsonString);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (list) {
          expect(list, isA<List>());
          expect(list.length, 5);
          expect(list, [1, 2, 3, 4, 5]);
        },
      );
    });

    test('should decode array of objects', () {
      // Arrange
      const jsonString = '[{"id": 1}, {"id": 2}]';

      // Act
      final result = JsonParser.safeDecodeList(jsonString);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (list) {
          expect(list.length, 2);
          expect(list[0], isA<Map>());
          final firstItem = list[0] as Map<String, dynamic>;
          expect(firstItem['id'], 1);
        },
      );
    });

    test('should decode nested arrays', () {
      // Arrange
      const jsonString = '[[1, 2], [3, 4]]';

      // Act
      final result = JsonParser.safeDecodeList(jsonString);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (list) {
          expect(list.length, 2);
          expect(list[0], [1, 2]);
          expect(list[1], [3, 4]);
        },
      );
    });

    test('should handle empty JSON array', () {
      // Arrange
      const jsonString = '[]';

      // Act
      final result = JsonParser.safeDecodeList(jsonString);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (list) {
          expect(list, isEmpty);
        },
      );
    });

    test('should return failure for empty string', () {
      // Arrange
      const jsonString = '';

      // Act
      final result = JsonParser.safeDecodeList(jsonString);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('empty'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return failure for non-array JSON', () {
      // Arrange
      const jsonString = '{"key": "value"}';

      // Act
      final result = JsonParser.safeDecodeList(jsonString);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Expected JSON list'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return failure for invalid JSON format', () {
      // Arrange
      const jsonString = '[1, 2, invalid]';

      // Act
      final result = JsonParser.safeDecodeList(jsonString);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Invalid JSON format'));
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return failure for malformed JSON', () {
      // Arrange
      const jsonString = '[1, 2,';

      // Act
      final result = JsonParser.safeDecodeList(jsonString);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should decode Binance klines-like structure', () {
      // Arrange
      const jsonString = '''
      [
        [1499040000000, "0.01634790", "0.80000000", "0.01575800", "0.01577100", "148976.11427815", 1499644799999, "2434.19055334", 308, "1756.87402397", "28.46694368", "17928899.62484339"],
        [1500040000000, "0.01634791", "0.81000000", "0.01575801", "0.01577101", "148976.11427816", 1500644799999, "2434.19055335", 309, "1756.87402398", "28.46694369", "17928899.62484340"]
      ]
      ''';

      // Act
      final result = JsonParser.safeDecodeList(jsonString);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (list) {
          expect(list.length, 2);
          expect(list[0], isA<List>());
          final kline = list[0] as List;
          expect(kline.length, 12);
          expect(kline[0], isA<int>()); // openTime
        },
      );
    });
  });
}
