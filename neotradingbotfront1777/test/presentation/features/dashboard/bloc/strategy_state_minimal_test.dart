import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';
import 'package:neotradingbotfront1777/domain/usecases/manage_strategy_run_control_use_case.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/bloc/strategy_state_bloc.dart';

class MockTradingRepository extends Mock implements ITradingRepository {}

class MockManageUseCase extends Mock
    implements ManageStrategyRunControlUseCase {}

class MockSymbolContext extends Mock implements SymbolContext {}

void main() {
  setUp(() {
    sl.allowReassignment = true;
    sl.registerSingleton<SymbolContext>(MockSymbolContext());
  });

  blocTest<StrategyStateBloc, StrategyStateState>(
    'minimal bloc test',
    build:
        () => StrategyStateBloc(
          tradingRepository: MockTradingRepository(),
          manageStrategyRunControlUseCase: MockManageUseCase(),
        ),
    expect: () => [],
  );
}

