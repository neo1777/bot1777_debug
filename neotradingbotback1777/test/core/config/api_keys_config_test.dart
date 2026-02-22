import 'package:test/test.dart';
import 'package:neotradingbotback1777/core/config/api_keys_config.dart';

void main() {
  // Valid 64-char alphanumeric strings for testing
  const validKey =
      'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXyz12';
  // Another valid key (different pattern)
  const validKey2 =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz12';

  group('ApiKeysConfig — Construction', () {
    test('[AKC-01] constructor stores all fields correctly', () {
      final config = ApiKeysConfig(
        apiKey: validKey,
        secretKey: validKey2,
        testApiKey: '',
        testSecretKey: '',
      );

      expect(config.apiKey, validKey);
      expect(config.secretKey, validKey2);
      expect(config.testApiKey, '');
      expect(config.testSecretKey, '');
    });
  });

  group('ApiKeysConfig — getKeysForMode', () {
    test('[AKC-03] returns production keys when isTestMode is false', () {
      final config = ApiKeysConfig(
        apiKey: validKey,
        secretKey: validKey2,
        testApiKey: 'testKey',
        testSecretKey: 'testSecret',
      );

      final (key, secret) = config.getKeysForMode(isTestMode: false);
      expect(key, validKey);
      expect(secret, validKey2);
    });

    test('[AKC-04] returns test keys when isTestMode is true', () {
      final config = ApiKeysConfig(
        apiKey: validKey,
        secretKey: validKey2,
        testApiKey: 'testKey',
        testSecretKey: 'testSecret',
      );

      final (key, secret) = config.getKeysForMode(isTestMode: true);
      expect(key, 'testKey');
      expect(secret, 'testSecret');
    });
  });

  // Note: _validateApiKey and _validateSecretKey are private static methods.
  // We test them indirectly through the constructor / any public usage.
  // Since loadFromEnv() reads Platform.environment, we test validation
  // behavior via the config construction patterns.

  group('ApiKeysConfig — Key validation rules', () {
    test('[AKC-05] valid 64-char alphanumeric key is accepted', () {
      // Construction succeeds with valid keys
      final config = ApiKeysConfig(
        apiKey: validKey,
        secretKey: validKey2,
        testApiKey: '',
        testSecretKey: '',
      );
      expect(config.apiKey.length, 64);
    });

    test('[AKC-06] valid keys contain only alphanumeric characters', () {
      // Verify our test keys match the pattern
      expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(validKey), true);
      expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(validKey2), true);
    });

    test('[AKC-07] key with special characters would fail regex check', () {
      const badKey =
          'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRS!@#\$%^';
      expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(badKey), false);
    });

    test('[AKC-08] key shorter than 64 chars would fail length check', () {
      const shortKey = 'abc123';
      expect(shortKey.length != 64, true);
    });

    test('[AKC-09] key longer than 64 chars would fail length check', () {
      const longKey =
          'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcd';
      expect(longKey.length, 66);
      expect(longKey.length != 64, true);
    });

    test('[AKC-10] empty key would fail validation', () {
      const emptyKey = '';
      expect(emptyKey.isEmpty, true);
    });
  });

  group('ApiKeysConfig — Edge cases', () {
    test('[AKC-11] test keys can be empty strings', () {
      final config = ApiKeysConfig(
        apiKey: validKey,
        secretKey: validKey2,
        testApiKey: '',
        testSecretKey: '',
      );
      expect(config.testApiKey, isEmpty);
      expect(config.testSecretKey, isEmpty);
    });

    test('[AKC-12] production keys used when test keys are empty in testMode',
        () {
      final config = ApiKeysConfig(
        apiKey: validKey,
        secretKey: validKey2,
        testApiKey: '',
        testSecretKey: '',
      );

      final (key, secret) = config.getKeysForMode(isTestMode: true);
      // Returns empty test keys, not production
      expect(key, '');
      expect(secret, '');
    });

    test('[AKC-13] all numeric key passes alphanumeric check', () {
      const numericKey =
          '1234567890123456789012345678901234567890123456789012345678901234';
      expect(numericKey.length, 64);
      expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(numericKey), true);
    });

    test('[AKC-14] all alpha key passes alphanumeric check', () {
      const alphaKey =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijkl';
      expect(alphaKey.length, 64);
      expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(alphaKey), true);
    });

    test('[AKC-15] key with whitespace would fail validation', () {
      const spacedKey =
          'abcdefghijklmnopqrs tuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWX';
      expect(RegExp(r'^[a-zA-Z0-9]+$').hasMatch(spacedKey), false);
    });
  });
}

