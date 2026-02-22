import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/price_data.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_price_repository.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_bloc_real.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_event.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_state.dart';

// ─── Mocks ───────────────────────────────────────────────────────────
class MockPriceRepository extends Mock implements IPriceRepository {}

// ─── Helpers ─────────────────────────────────────────────────────────
PriceData _makePriceData({String symbol = 'BTCUSDC', double price = 45000.0}) {
  return PriceData(
    symbol: symbol,
    price: price,
    timestamp: DateTime(2026, 2, 15),
  );
}

void main() {
  late MockPriceRepository mockPriceRepository;
  late PriceBlocReal bloc;

  setUp(() {
    mockPriceRepository = MockPriceRepository();
    bloc = PriceBlocReal(priceRepository: mockPriceRepository);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('[FRONTEND-TEST-001] PriceBlocReal', () {
    test('initial state is PriceInitial', () {
      expect(bloc.state, const PriceInitial());
    });

    // ──────────────────────────────────────
    // SubscribeToPriceUpdates
    // ──────────────────────────────────────
    group('SubscribeToPriceUpdates', () {
      late StreamController<Either<Failure, PriceData>> controller;

      blocTest<PriceBlocReal, PriceState>(
        'emits [PriceLoading, PriceLoaded] when stream emits a Right(PriceData)',
        setUp: () {
          controller = StreamController<Either<Failure, PriceData>>();
        },
        build: () {
          when(
            () => mockPriceRepository.streamCurrentPrice('BTCUSDC'),
          ).thenAnswer((_) => controller.stream);

          // Schedule emitting data after listen is established
          Future.delayed(const Duration(milliseconds: 50), () {
            controller.add(Right(_makePriceData()));
          });

          return PriceBlocReal(priceRepository: mockPriceRepository);
        },
        act: (bloc) => bloc.add(const SubscribeToPriceUpdates('BTCUSDC')),
        wait: const Duration(milliseconds: 200),
        expect: () => [const PriceLoading(), PriceLoaded(_makePriceData())],
        verify: (_) {
          verify(
            () => mockPriceRepository.streamCurrentPrice('BTCUSDC'),
          ).called(1);
        },
        tearDown: () => controller.close(),
      );

      // NOTE: The error paths in PriceBlocReal call emit from stream
      // callbacks that fire after the event handler completes. This is a
      // known BLoC pattern limitation: _onSubscribeToPriceUpdates sets up
      // a .listen() whose fold/onError callbacks invoke emit(), but the
      // handler itself returns synchronously. The bloc_test framework (and
      // the BLoC library itself) asserts that emit is not called after
      // completion. These tests document the design issue.
      blocTest<PriceBlocReal, PriceState>(
        'emits PriceError when stream emits a Left(Failure)',
        setUp: () {
          controller = StreamController<Either<Failure, PriceData>>();
        },
        build: () {
          when(
            () => mockPriceRepository.streamCurrentPrice('BTCUSDC'),
          ).thenAnswer((_) => controller.stream);

          Future.delayed(const Duration(milliseconds: 50), () {
            controller.add(Left(ServerFailure(message: 'Stream Error')));
          });

          return PriceBlocReal(priceRepository: mockPriceRepository);
        },
        act: (bloc) => bloc.add(const SubscribeToPriceUpdates('BTCUSDC')),
        wait: const Duration(milliseconds: 200),
        expect: () => [const PriceLoading(), const PriceError('Stream Error')],
        tearDown: () => controller.close(),
      );

      blocTest<PriceBlocReal, PriceState>(
        'emits PriceError when stream emits an error',
        setUp: () {
          controller = StreamController<Either<Failure, PriceData>>();
        },
        build: () {
          when(
            () => mockPriceRepository.streamCurrentPrice('BTCUSDC'),
          ).thenAnswer((_) => controller.stream);

          Future.delayed(const Duration(milliseconds: 50), () {
            controller.addError('Network error');
          });

          return PriceBlocReal(priceRepository: mockPriceRepository);
        },
        act: (bloc) => bloc.add(const SubscribeToPriceUpdates('BTCUSDC')),
        wait: const Duration(milliseconds: 200),
        expect: () => [const PriceLoading(), const PriceError('Network error')],
        tearDown: () => controller.close(),
      );

      blocTest<PriceBlocReal, PriceState>(
        'emits PriceError when repository throws synchronously',
        build: () {
          when(
            () => mockPriceRepository.streamCurrentPrice('BTCUSDC'),
          ).thenThrow(Exception('Repository init failed'));
          return PriceBlocReal(priceRepository: mockPriceRepository);
        },
        act: (bloc) => bloc.add(const SubscribeToPriceUpdates('BTCUSDC')),
        expect: () => [const PriceLoading(), isA<PriceError>()],
      );

      late StreamController<Either<Failure, PriceData>> seqController;

      blocTest<PriceBlocReal, PriceState>(
        'receives multiple sequential price updates',
        setUp: () {
          seqController = StreamController<Either<Failure, PriceData>>();
        },
        build: () {
          when(
            () => mockPriceRepository.streamCurrentPrice('BTCUSDC'),
          ).thenAnswer((_) => seqController.stream);

          Future.delayed(const Duration(milliseconds: 50), () {
            seqController.add(Right(_makePriceData(price: 45000.0)));
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            seqController.add(Right(_makePriceData(price: 45500.0)));
          });
          Future.delayed(const Duration(milliseconds: 150), () {
            seqController.add(Right(_makePriceData(price: 44800.0)));
          });

          return PriceBlocReal(priceRepository: mockPriceRepository);
        },
        act: (bloc) => bloc.add(const SubscribeToPriceUpdates('BTCUSDC')),
        wait: const Duration(milliseconds: 300),
        expect:
            () => [
              const PriceLoading(),
              PriceLoaded(_makePriceData(price: 45000.0)),
              PriceLoaded(_makePriceData(price: 45500.0)),
              PriceLoaded(_makePriceData(price: 44800.0)),
            ],
        tearDown: () => seqController.close(),
      );

      late StreamController<Either<Failure, PriceData>> resubController1;
      late StreamController<Either<Failure, PriceData>> resubController2;

      blocTest<PriceBlocReal, PriceState>(
        'cancels previous subscription when subscribing again',
        setUp: () {
          resubController1 = StreamController<Either<Failure, PriceData>>();
          resubController2 = StreamController<Either<Failure, PriceData>>();
        },
        build: () {
          var callCount = 0;
          when(() => mockPriceRepository.streamCurrentPrice(any())).thenAnswer((
            _,
          ) {
            callCount++;
            return callCount == 1
                ? resubController1.stream
                : resubController2.stream;
          });

          // Emit on first stream to break PriceLoading dedup,
          // then emit on second after resubscribe
          Future.delayed(const Duration(milliseconds: 30), () {
            resubController1.add(
              Right(_makePriceData(symbol: 'BTCUSDC', price: 45000.0)),
            );
          });
          Future.delayed(const Duration(milliseconds: 150), () {
            resubController2.add(
              Right(_makePriceData(symbol: 'ETHUSDC', price: 3000.0)),
            );
          });

          return PriceBlocReal(priceRepository: mockPriceRepository);
        },
        act: (bloc) async {
          bloc.add(const SubscribeToPriceUpdates('BTCUSDC'));
          await Future.delayed(const Duration(milliseconds: 70));
          bloc.add(const SubscribeToPriceUpdates('ETHUSDC'));
        },
        wait: const Duration(milliseconds: 300),
        expect:
            () => [
              // First subscribe: PriceLoading → PriceLoaded(BTC)
              const PriceLoading(),
              PriceLoaded(_makePriceData(symbol: 'BTCUSDC', price: 45000.0)),
              // Second subscribe: PriceLoading → PriceLoaded(ETH)
              const PriceLoading(),
              PriceLoaded(_makePriceData(symbol: 'ETHUSDC', price: 3000.0)),
            ],
        tearDown: () async {
          await resubController1.close();
          await resubController2.close();
        },
      );
    });

    // ──────────────────────────────────────
    // UnsubscribeFromPriceUpdates
    // ──────────────────────────────────────
    group('UnsubscribeFromPriceUpdates', () {
      blocTest<PriceBlocReal, PriceState>(
        'emits PriceInitial and cancels subscription',
        build: () {
          // ignore: close_sinks — only used as a mock return, never listened to
          final controller = StreamController<Either<Failure, PriceData>>();
          when(
            () => mockPriceRepository.streamCurrentPrice('BTCUSDC'),
          ).thenAnswer((_) => controller.stream);
          return PriceBlocReal(priceRepository: mockPriceRepository);
        },
        seed: () => PriceLoaded(_makePriceData()),
        act: (bloc) => bloc.add(const UnsubscribeFromPriceUpdates()),
        expect: () => [const PriceInitial()],
      );
    });

    // ──────────────────────────────────────
    // PriceUpdateReceived
    // ──────────────────────────────────────
    group('PriceUpdateReceived', () {
      blocTest<PriceBlocReal, PriceState>(
        'emits PriceLoaded when receiving valid PriceData',
        build: () => PriceBlocReal(priceRepository: mockPriceRepository),
        act:
            (bloc) =>
                bloc.add(PriceUpdateReceived(_makePriceData(price: 50000.0))),
        expect: () => [PriceLoaded(_makePriceData(price: 50000.0))],
      );

      blocTest<PriceBlocReal, PriceState>(
        'does not emit when receiving non-PriceData dynamic type',
        build: () => PriceBlocReal(priceRepository: mockPriceRepository),
        act: (bloc) => bloc.add(const PriceUpdateReceived('not_price_data')),
        expect: () => [],
      );
    });

    // ──────────────────────────────────────
    // ResetPriceState
    // ──────────────────────────────────────
    group('ResetPriceState', () {
      blocTest<PriceBlocReal, PriceState>(
        'emits PriceInitial and cancels active subscription',
        build: () => PriceBlocReal(priceRepository: mockPriceRepository),
        seed: () => PriceLoaded(_makePriceData()),
        act: (bloc) => bloc.add(const ResetPriceState()),
        expect: () => [const PriceInitial()],
      );
    });
  });
}

