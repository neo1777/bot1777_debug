import 'package:mockito/mockito.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Helper semplice per configurare mock comuni
class SimpleMockHelper {
  /// Configura mock per gestire chiamate generiche GetIt
  static void setupGetItMock<T>(Mock mockGetIt, T mockService) {
    // Mock per _sl<T>()
    when((mockGetIt as dynamic).call<T>()).thenReturn(mockService);
  }

  /// Configura mock per fallimenti comuni
  static void setupFailureMock<T extends Mock>(
      T mock, String methodName, String failureType) {
    final failure = _createFailure(failureType);

    switch (methodName) {
      case 'getLatestPrice':
        when((mock as dynamic).getLatestPrice(any))
            .thenAnswer((_) async => Left(failure));
        break;
      case 'getExchangeInfo':
        when((mock as dynamic).getExchangeInfo())
            .thenAnswer((_) async => Left(failure));
        break;
      case 'getCurrentPrice':
        when((mock as dynamic).getCurrentPrice(any))
            .thenAnswer((_) async => Left(failure));
        break;
      case 'getSymbolInfo':
        when((mock as dynamic).getSymbolInfo(any))
            .thenAnswer((_) async => Left(failure));
        break;
      case 'getAccountInfo':
        when((mock as dynamic).getAccountInfo())
            .thenAnswer((_) async => Left(failure));
        break;
    }
  }

  /// Crea fallimenti comuni
  static Failure _createFailure(String failureType) {
    switch (failureType) {
      case 'network_error':
        return ServerFailure(message: 'Network error');
      case 'timeout':
        return ServerFailure(message: 'Timeout', statusCode: 408);
      case 'service_unavailable':
        return ServerFailure(message: 'Service unavailable', statusCode: 503);
      case 'validation_error':
        return ValidationFailure(message: 'Validation error');
      case 'cache_error':
        return CacheFailure(message: 'Cache error');
      default:
        return ServerFailure(message: 'Unknown error');
    }
  }
}
