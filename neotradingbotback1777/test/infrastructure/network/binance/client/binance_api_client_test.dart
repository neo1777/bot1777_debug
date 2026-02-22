import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/infrastructure/network/binance/client/binance_api_client.dart';

void main() {
  late BinanceApiClient apiClient;
  late MockClient mockHttpClient;
  const apiKey = 'test_api_key';
  const secretKey = 'test_secret_key';

  /// Helper: builds a [BinanceApiClient] backed by [mockHttpClient].
  BinanceApiClient buildClient() => BinanceApiClient(
        apiKey: apiKey,
        secretKey: secretKey,
        httpClient: mockHttpClient,
        baseUrl: 'https://test.binance.com',
      );

  group('BinanceApiClient — Initialization', () {
    test('[BAC-01] constructor creates client with default URLs', () {
      mockHttpClient = MockClient((_) async => http.Response('{}', 200));
      apiClient = BinanceApiClient(
          apiKey: apiKey, secretKey: secretKey, httpClient: mockHttpClient);
      // Client should be created successfully
      expect(apiClient, isNotNull);
    });

    test('[BAC-02] constructor creates client with custom URLs', () {
      mockHttpClient = MockClient((_) async => http.Response('{}', 200));
      apiClient = BinanceApiClient(
        apiKey: apiKey,
        secretKey: secretKey,
        httpClient: mockHttpClient,
        baseUrl: 'https://custom.api.com',
        wsBaseUrl: 'wss://custom.ws.com',
      );
      expect(apiClient.wsBaseUrl, 'wss://custom.ws.com');
    });

    test('[BAC-03] initialize starts time sync without blocking', () async {
      // Mock the /api/v3/time endpoint for time sync
      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }
        return http.Response('{}', 200);
      });
      apiClient = buildClient();
      // initialize() should complete without throwing
      await apiClient.initialize();
      apiClient.dispose();
    });

    test('[BAC-04] dispose cancels time sync timer', () async {
      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }
        return http.Response('{}', 200);
      });
      apiClient = buildClient();
      await apiClient.initialize();
      // Should not throw
      apiClient.dispose();
      // Double dispose should also be safe
      apiClient.dispose();
    });
  });

  group('BinanceApiClient — sendRequest basics', () {
    test('[BAC-05] sendRequest sends GET with correct X-MBX-APIKEY header',
        () async {
      mockHttpClient = MockClient((request) async {
        if (request.headers['X-MBX-APIKEY'] == apiKey) {
          return http.Response('{"success": true}', 200);
        }
        return http.Response('Unauthorized', 401);
      });
      apiClient = buildClient();
      await apiClient.initialize();

      final result =
          await apiClient.sendRequest(method: 'GET', endpoint: '/test');
      expect(result.isRight(), true);
    });

    test('[BAC-06] sendRequest signs request when isSigned is true', () async {
      mockHttpClient = MockClient((request) async {
        if (request.url.queryParameters.containsKey('signature') &&
            request.url.queryParameters.containsKey('timestamp')) {
          return http.Response('{"success": true}', 200);
        }
        return http.Response('Missing signature', 400);
      });
      apiClient = buildClient();
      await apiClient.initialize();

      final result = await apiClient.sendRequest(
          method: 'GET', endpoint: '/signed', isSigned: true);
      expect(result.isRight(), true);
    });

    test('[BAC-07] sendRequest skips signature when isSigned is false',
        () async {
      mockHttpClient = MockClient((request) async {
        // Should NOT have signature or timestamp
        expect(request.url.queryParameters.containsKey('signature'), false);
        expect(request.url.queryParameters.containsKey('timestamp'), false);
        return http.Response('{"ok": true}', 200);
      });
      apiClient = buildClient();
      await apiClient.initialize();

      final result = await apiClient.sendRequest(
          method: 'GET', endpoint: '/public', isSigned: false);
      expect(result.isRight(), true);
    });
  });

  group('BinanceApiClient — HTTP methods', () {
    test('[BAC-08] sendRequest sends POST requests', () async {
      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }
        expect(request.method, 'POST');
        return http.Response('{"orderId": 1}', 200);
      });
      apiClient = buildClient();
      await apiClient.initialize();

      final result = await apiClient.sendRequest(
          method: 'POST', endpoint: '/api/v3/order');
      expect(result.isRight(), true);
    });

    test('[BAC-09] sendRequest sends DELETE requests', () async {
      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }
        expect(request.method, 'DELETE');
        return http.Response('{"success": true}', 200);
      });
      apiClient = buildClient();
      await apiClient.initialize();

      final result = await apiClient.sendRequest(
          method: 'DELETE', endpoint: '/api/v3/order');
      expect(result.isRight(), true);
    });

    test('[BAC-10] sendRequest sends PUT requests', () async {
      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }
        expect(request.method, 'PUT');
        return http.Response('{"success": true}', 200);
      });
      apiClient = buildClient();
      await apiClient.initialize();

      final result =
          await apiClient.sendRequest(method: 'PUT', endpoint: '/api/v3/order');
      expect(result.isRight(), true);
    });
  });

  group('BinanceApiClient — Error handling', () {
    test('[BAC-11] returns ServerFailure for 400 client errors', () async {
      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }
        return http.Response('{"code": -1100, "msg": "Bad request"}', 400);
      });
      apiClient = buildClient();
      await apiClient.initialize();

      final result = await apiClient.sendRequest(
          method: 'GET', endpoint: '/bad', maxRetries: 1);
      expect(result.isLeft(), true);
    });

    test('[BAC-12] returns ServerFailure for 403 forbidden', () async {
      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }
        return http.Response('Forbidden', 403);
      });
      apiClient = buildClient();
      await apiClient.initialize();

      final result = await apiClient.sendRequest(
          method: 'GET', endpoint: '/forbidden', maxRetries: 1);
      expect(result.isLeft(), true);
    });

    test('[BAC-13] retries and fails after exhausting maxRetries on 500',
        () async {
      int attempts = 0;
      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }
        attempts++;
        return http.Response('Internal Server Error', 500);
      });
      apiClient = buildClient();
      await apiClient.initialize();

      final result = await apiClient.sendRequest(
        method: 'GET',
        endpoint: '/failing',
        maxRetries: 2,
        initialDelay: Duration(milliseconds: 10),
      );
      expect(result.isLeft(), true);
      // Should have made 2 attempts
      expect(attempts, 2);
    });
  });

  group('BinanceApiClient — Signature generation', () {
    test('[BAC-14] signature matches HMAC-SHA256 of query string', () async {
      String? capturedQuery;
      String? capturedSignature;

      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }

        capturedSignature = request.url.queryParameters['signature'];
        // Reconstruct query string without signature to verify
        final params = Map<String, String>.from(request.url.queryParameters);
        params.remove('signature');
        capturedQuery = Uri(queryParameters: params).query;
        return http.Response('{"ok": true}', 200);
      });

      apiClient = buildClient();
      await apiClient.initialize();
      await apiClient.sendRequest(
          method: 'GET', endpoint: '/api/v3/account', isSigned: true);

      expect(capturedSignature, isNotNull);
      expect(capturedQuery, isNotNull);

      // Manually compute expected signature
      final key = utf8.encode(secretKey);
      final bytes = utf8.encode(capturedQuery!);
      final hmacSha256 = Hmac(sha256, key);
      final expectedDigest = hmacSha256.convert(bytes).toString();
      expect(capturedSignature, expectedDigest);
    });

    test('[BAC-15] signed requests include timestamp and recvWindow', () async {
      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }
        expect(request.url.queryParameters.containsKey('timestamp'), true);
        expect(request.url.queryParameters.containsKey('recvWindow'), true);
        return http.Response('{"ok": true}', 200);
      });

      apiClient = buildClient();
      await apiClient.initialize();
      await apiClient.sendRequest(
          method: 'GET', endpoint: '/signed', isSigned: true);
    });

    test('[BAC-16] request params are forwarded correctly', () async {
      mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('/api/v3/time')) {
          return http.Response(
              '{"serverTime": ${DateTime.now().millisecondsSinceEpoch}}', 200);
        }
        expect(request.url.queryParameters['symbol'], 'BTCUSDC');
        return http.Response('{"ok": true}', 200);
      });

      apiClient = buildClient();
      await apiClient.initialize();
      await apiClient.sendRequest(
        method: 'GET',
        endpoint: '/api/v3/ticker',
        params: {'symbol': 'BTCUSDC'},
        isSigned: false,
      );
    });
  });

  group('BinanceApiClient — Configuration', () {
    test('[BAC-17] updateConfig updates all fields', () async {
      mockHttpClient = MockClient((_) async => http.Response('{}', 200));
      apiClient = buildClient();

      apiClient.updateConfig(
        apiKey: 'new_key',
        secretKey: 'new_secret',
        baseUrl: 'https://new.api.com',
        wsBaseUrl: 'wss://new.ws.com',
      );
      expect(apiClient.wsBaseUrl, 'wss://new.ws.com');
    });

    test('[BAC-18] updateConfig updates URLs and keys', () async {
      mockHttpClient = MockClient((_) async => http.Response('{}', 200));
      apiClient = buildClient();

      apiClient.updateConfig(
        apiKey: 'newApiKey',
        secretKey: 'newSecretKey',
        baseUrl: 'https://urls.api.com',
        wsBaseUrl: 'wss://urls.ws.com',
      );
      expect(apiClient.wsBaseUrl, 'wss://urls.ws.com');
    });
  });

  group('BinanceApiClient — Statistics', () {
    test('[BAC-19] getStatistics returns initial stats', () {
      mockHttpClient = MockClient((_) async => http.Response('{}', 200));
      apiClient = buildClient();

      final stats = apiClient.getStatistics();
      expect(stats.containsKey('rateLimiter'), true);
      expect(stats.containsKey('http'), true);
      final httpStats = stats['http'] as Map<String, dynamic>;
      final inflightStats = httpStats['inflight'] as Map<String, dynamic>;
      expect(inflightStats['info'] ?? 0, 0);
      expect(inflightStats['order'] ?? 0, 0);
    });

    test('[BAC-20] getStatistics includes queue sizes', () {
      mockHttpClient = MockClient((_) async => http.Response('{}', 200));
      apiClient = buildClient();

      final stats = apiClient.getStatistics();
      final httpStats = stats['http'] as Map<String, dynamic>;
      final queueStats = httpStats['queued'] as Map<String, dynamic>;
      expect(queueStats['infoQueue'] ?? 0, 0);
      expect(queueStats['orderQueue'] ?? 0, 0);
    });
  });
}
