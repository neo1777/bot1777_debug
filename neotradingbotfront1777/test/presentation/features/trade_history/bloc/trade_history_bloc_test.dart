import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trade_history_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_event.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_state.dart';

class MockTradeHistoryRepository extends Mock
    implements ITradeHistoryRepository {}

void main() {
  late MockTradeHistoryRepository mockRepository;
  late TradeHistoryBloc bloc;
  late StreamController<AppTrade> streamController;

  final tTrade = AppTrade(
    symbol: 'BTCUSDC',
    price: 50000.0,
    quantity: 0.001,
    isBuy: true,
    timestamp: DateTime(2023, 1, 1),
    orderStatus: 'FILLED',
  );

  final tTrades = [tTrade];

  setUpAll(() {
    registerFallbackValue(tTrade);
  });

  setUp(() {
    mockRepository = MockTradeHistoryRepository();
    streamController = StreamController<AppTrade>();
    bloc = TradeHistoryBloc(tradeHistoryRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
    streamController.close();
  });

  test('initial state should be TradeHistoryInitial', () {
    expect(bloc.state, const TradeHistoryInitial());
  });

  group('LoadTradeHistory', () {
    blocTest<TradeHistoryBloc, TradeHistoryState>(
      'emits [Loading, Loaded] when repository succeeds and triggers subscription',
      build: () {
        when(
          () => mockRepository.getTradeHistory(),
        ).thenAnswer((_) async => Right(tTrades));
        when(
          () => mockRepository.subscribeToTradeHistory(),
        ).thenReturn(Right(streamController.stream));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadTradeHistory()),
      expect:
          () => [
            const TradeHistoryLoading(),
            TradeHistoryLoaded(trades: tTrades, filteredTrades: tTrades),
            TradeHistoryLoaded(
              trades: tTrades,
              filteredTrades: tTrades,
              isStreaming: true,
            ),
          ],
      verify: (_) {
        verify(() => mockRepository.getTradeHistory()).called(1);
        verify(() => mockRepository.subscribeToTradeHistory()).called(1);
      },
    );

    blocTest<TradeHistoryBloc, TradeHistoryState>(
      'emits [Loading, Error] when repository fails',
      build: () {
        when(
          () => mockRepository.getTradeHistory(),
        ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadTradeHistory()),
      expect:
          () => [const TradeHistoryLoading(), const TradeHistoryError('Error')],
    );
  });

  group('TradeHistoryUpdated', () {
    final newTrade = tTrade.copyWith(
      price: 51000.0,
      timestamp: DateTime(2023, 1, 2),
    );

    blocTest<TradeHistoryBloc, TradeHistoryState>(
      'updates trades and filteredTrades when a new trade is received',
      build: () => bloc,
      seed: () => TradeHistoryLoaded(trades: tTrades, filteredTrades: tTrades),
      act: (bloc) => bloc.add(TradeHistoryUpdated(newTrade)),
      expect:
          () => [
            TradeHistoryLoaded(
              trades: [newTrade, ...tTrades],
              filteredTrades: [newTrade, ...tTrades],
            ),
          ],
    );
  });

  group('Filtering', () {
    final buyTrade = tTrade;
    final sellTrade = tTrade.copyWith(
      isBuy: false,
      price: 52000.0,
      timestamp: DateTime(2023, 1, 3),
    );
    final trades = [sellTrade, buyTrade];

    blocTest<TradeHistoryBloc, TradeHistoryState>(
      'filters by symbol',
      build: () => bloc,
      seed: () => TradeHistoryLoaded(trades: trades, filteredTrades: trades),
      act: (bloc) => bloc.add(const FilterTradesBySymbol('BTCUSDC')),
      expect:
          () => [
            TradeHistoryLoaded(
              trades: trades,
              filteredTrades: trades,
              symbolFilter: 'BTCUSDC',
            ),
          ],
    );

    blocTest<TradeHistoryBloc, TradeHistoryState>(
      'filters by type (BUY)',
      build: () => bloc,
      seed: () => TradeHistoryLoaded(trades: trades, filteredTrades: trades),
      act: (bloc) => bloc.add(const FilterTradesByType(true)),
      expect:
          () => [
            TradeHistoryLoaded(
              trades: trades,
              filteredTrades: [buyTrade],
              typeFilter: true,
            ),
          ],
    );

    blocTest<TradeHistoryBloc, TradeHistoryState>(
      'clears filters',
      build: () => bloc,
      seed:
          () => TradeHistoryLoaded(
            trades: trades,
            filteredTrades: [buyTrade],
            typeFilter: true,
          ),
      act: (bloc) => bloc.add(const ClearFilters()),
      expect:
          () => [
            TradeHistoryLoaded(
              trades: trades,
              filteredTrades: trades,
              typeFilter: null,
              symbolFilter: null,
              startDateFilter: null,
              endDateFilter: null,
            ),
          ],
    );
  });
}
