import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/backtest_result.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_backtest_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_event.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_state.dart';

class MockBacktestRepository extends Mock implements IBacktestRepository {}

void main() {
  late MockBacktestRepository mockRepository;
  late BacktestBloc bloc;

  const tBacktestId = 'test-id';
  const tBacktestResult = BacktestResult(
    backtestId: tBacktestId,
    totalProfit: 100.0,
    profitPercentage: 1.0,
    tradesCount: 10,
    dcaTradesCount: 2,
    totalFees: 5.0,
    totalProfitStr: '100.00',
    profitPercentageStr: '1.00%',
    totalFeesStr: '5.00',
    trades: [],
  );

  setUp(() {
    mockRepository = MockBacktestRepository();
    bloc = BacktestBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be BacktestInitial', () {
    expect(bloc.state, isA<BacktestInitial>());
  });

  group('StartBacktest', () {
    blocTest<BacktestBloc, BacktestState>(
      'emits [Loading, Running, Loaded] when repository succeeds',
      build: () {
        when(
          () => mockRepository.startBacktest(
            symbol: any(named: 'symbol'),
            interval: any(named: 'interval'),
            period: any(named: 'period'),
            strategyName: any(named: 'strategyName'),
          ),
        ).thenAnswer((_) async => const Right(tBacktestId));
        when(
          () => mockRepository.getBacktestResults(any()),
        ).thenAnswer((_) async => const Right(tBacktestResult));
        return bloc;
      },
      act:
          (bloc) => bloc.add(
            const StartBacktest(
              symbol: 'BTCUSDC',
              interval: '1h',
              period: 24,
              strategyName: 'default',
            ),
          ),
      expect:
          () => [
            isA<BacktestLoading>(),
            const BacktestRunning(tBacktestId),
            const BacktestLoaded(tBacktestResult),
          ],
    );

    blocTest<BacktestBloc, BacktestState>(
      'emits [Loading, Error] when startBacktest fails',
      build: () {
        when(
          () => mockRepository.startBacktest(
            symbol: any(named: 'symbol'),
            interval: any(named: 'interval'),
            period: any(named: 'period'),
            strategyName: any(named: 'strategyName'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Start Error')),
        );
        return bloc;
      },
      act:
          (bloc) => bloc.add(
            const StartBacktest(
              symbol: 'BTCUSDC',
              interval: '1h',
              period: 24,
              strategyName: 'default',
            ),
          ),
      expect:
          () => [isA<BacktestLoading>(), const BacktestError('Start Error')],
    );

    blocTest<BacktestBloc, BacktestState>(
      'emits [Loading, Running, Error] when getBacktestResults fails',
      build: () {
        when(
          () => mockRepository.startBacktest(
            symbol: any(named: 'symbol'),
            interval: any(named: 'interval'),
            period: any(named: 'period'),
            strategyName: any(named: 'strategyName'),
          ),
        ).thenAnswer((_) async => const Right(tBacktestId));
        when(() => mockRepository.getBacktestResults(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Fetch Error')),
        );
        return bloc;
      },
      act:
          (bloc) => bloc.add(
            const StartBacktest(
              symbol: 'BTCUSDC',
              interval: '1h',
              period: 24,
              strategyName: 'default',
            ),
          ),
      expect:
          () => [
            isA<BacktestLoading>(),
            const BacktestRunning(tBacktestId),
            const BacktestError('Fetch Error'),
          ],
    );
  });
}

