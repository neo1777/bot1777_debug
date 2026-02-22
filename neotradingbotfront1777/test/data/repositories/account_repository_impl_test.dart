import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/repositories/account_repository_impl.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart';

import '../../mocks/mocks.dart';

void main() {
  late AccountRepositoryImpl repository;
  late MockTradingRemoteDatasource mockRemoteDatasource;

  setUp(() {
    mockRemoteDatasource = MockTradingRemoteDatasource();
    repository = AccountRepositoryImpl(remoteDatasource: mockRemoteDatasource);
  });

  group('AccountRepositoryImpl - getAccountInfo', () {
    final tAccountResponse =
        AccountInfoResponse()
          ..totalEstimatedValueUSDC = 1000.0
          ..balances.add(
            BalanceProto()
              ..asset = 'BTC'
              ..free = 1.0
              ..locked = 0.0,
          );

    test(
      'should return AccountInfo when remote datasource call is successful',
      () async {
        // arrange
        when(
          () => mockRemoteDatasource.getAccountInfo(),
        ).thenAnswer((_) async => Right(tAccountResponse));

        // act
        final result = await repository.getAccountInfo();

        // assert
        expect(result.isRight(), true);
        final accountInfo = result.getOrElse((_) => throw Exception());
        expect(accountInfo.totalEstimatedValueUSDC, 1000.0);
        expect(accountInfo.balances.first.asset, 'BTC');
        verify(() => mockRemoteDatasource.getAccountInfo()).called(1);
      },
    );

    test('should return Failure when remote datasource call fails', () async {
      // arrange
      final tFailure = ServerFailure(message: 'Server Error');
      when(
        () => mockRemoteDatasource.getAccountInfo(),
      ).thenAnswer((_) async => Left(tFailure));

      // act
      final result = await repository.getAccountInfo();

      // assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), equals(tFailure));
      verify(() => mockRemoteDatasource.getAccountInfo()).called(1);
    });

    test('should return UnexpectedFailure when an exception occurs', () async {
      // arrange
      when(
        () => mockRemoteDatasource.getAccountInfo(),
      ).thenThrow(Exception('Unexpected'));

      // act
      final result = await repository.getAccountInfo();

      // assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<UnexpectedFailure>());
    });
    group('AccountRepositoryImpl - subscribeAccountInfo', () {
      final tAccountResponse =
          AccountInfoResponse()..totalEstimatedValueUSDC = 1000.0;

      test(
        'should emit AccountInfo when stream provides success results',
        () async {
          // arrange
          when(
            () => mockRemoteDatasource.subscribeAccountInfo(),
          ).thenAnswer((_) => Stream.value(Right(tAccountResponse)));

          // act
          final stream = repository.subscribeAccountInfo();

          // assert
          expect(
            stream,
            emitsInOrder([
              predicate<Either<Failure, dynamic>>((r) => r.isRight()),
            ]),
          );
        },
      );

      test('should emit Failure when stream provides error results', () async {
        // arrange
        final tFailure = ServerFailure(message: 'Stream Error');
        when(
          () => mockRemoteDatasource.subscribeAccountInfo(),
        ).thenAnswer((_) => Stream.value(Left(tFailure)));

        // act
        final stream = repository.subscribeAccountInfo();

        // assert
        expect(
          stream,
          emitsInOrder([
            predicate<Either<Failure, dynamic>>((r) => r.isLeft()),
          ]),
        );
      });
    });
  });
}
