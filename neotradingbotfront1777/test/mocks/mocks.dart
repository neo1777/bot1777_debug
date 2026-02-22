import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';
import 'package:neotradingbotfront1777/presentation/blocs/strategy_control/strategy_control_bloc.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart';

/// Centralized Mocking Hub for Frontend
class MockTradingRepository extends Mock implements ITradingRepository {}

class MockStrategyControlBloc extends Mock implements StrategyControlBloc {}

class MockTradingRemoteDatasource extends Mock
    implements ITradingRemoteDatasource {}

/// Protobuf Mocks (if needed, otherwise use real instances)
class MockAccountInfoResponse extends Mock implements AccountInfoResponse {}

class MockStrategyResponse extends Mock implements StrategyResponse {}

/// Register common fallback values for Mocktail
void registerDefaultFallbackValues() {
  // registerFallbackValue(Right<Failure, Unit>(unit));
  // Note: registerFallbackValue should be called in setUpAll of the test suite
}
