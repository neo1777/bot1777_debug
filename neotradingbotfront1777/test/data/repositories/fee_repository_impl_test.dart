@Timeout(Duration(seconds: 60))
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/repositories/fee_repository_impl.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';

import '../../mocks/mocks.dart';

void main() {
  late FeeRepositoryImpl repository;
  late MockTradingRemoteDatasource mockRemoteDatasource;

  setUpAll(() {
    registerFallbackValue(GetSymbolFeesRequest(symbol: 'test'));
  });

  setUp(() {
    mockRemoteDatasource = MockTradingRemoteDatasource();
    repository = FeeRepositoryImpl(datasource: mockRemoteDatasource);
  });

  group('FeeRepositoryImpl - getSymbolFees', () {
    const tSymbol = 'BTCUSDC';

    test(
      'should return FeeInfo when remote datasource call is successful',
      () async {
        // arrange
        final tResponse =
            SymbolFeesResponse()
              ..symbol = tSymbol
              ..makerFee = 0.001
              ..takerFee = 0.001
              ..feeCurrency = 'BNB'
              ..lastUpdated = Int64(DateTime.now().millisecondsSinceEpoch);

        when(
          () => mockRemoteDatasource.getSymbolFees(any()),
        ).thenAnswer((_) async => Right(tResponse));

        // act
        final result = await repository.getSymbolFees(tSymbol);

        // assert
        expect(result.isRight(), true);
        final feeInfo = result.getOrElse((_) => throw Exception());
        expect(feeInfo.symbol, tSymbol);
        expect(feeInfo.makerFee, 0.001);
        verify(() => mockRemoteDatasource.getSymbolFees(any())).called(1);
      },
    );

    test(
      'should return default fees and cache them when datasource fails',
      () async {
        // arrange
        final tFailure = ServerFailure(message: 'Error');
        when(
          () => mockRemoteDatasource.getSymbolFees(any()),
        ).thenAnswer((_) async => Left(tFailure));

        // act
        final result = await repository.getSymbolFees(tSymbol);

        // assert
        expect(result.isRight(), true); // Returns default fees in Right
        final feeInfo = result.getOrElse((_) => throw Exception());
        expect(feeInfo.symbol, tSymbol);
        expect(feeInfo.makerFee, 0.001); // Default Binance fee
      },
    );

    test('should return cached value if present and valid', () async {
      // arrange
      final tResponse =
          SymbolFeesResponse()
            ..symbol = tSymbol
            ..makerFee = 0.005
            ..takerFee = 0.005
            ..lastUpdated = Int64(DateTime.now().millisecondsSinceEpoch);

      when(
        () => mockRemoteDatasource.getSymbolFees(any()),
      ).thenAnswer((_) async => Right(tResponse));

      // act
      await repository.getSymbolFees(tSymbol); // First call to populate cache
      final result = await repository.getSymbolFees(tSymbol); // Second call

      // assert
      expect(result.isRight(), true);
      final feeInfo = result.getOrElse((_) => throw Exception());
      expect(feeInfo.makerFee, 0.005);
      verify(
        () => mockRemoteDatasource.getSymbolFees(any()),
      ).called(1); // Only called once
    });
  });

  group('FeeRepositoryImpl - getAllSymbolFees', () {
    test(
      'should return map of FeeInfo when batch call is successful',
      () async {
        // arrange
        final tResponse = AllSymbolFeesResponse();
        tResponse.symbolFees.add(
          SymbolFeesResponse()
            ..symbol = 'BTCUSDC'
            ..makerFee = 0.001
            ..takerFee = 0.001,
        );

        when(
          () => mockRemoteDatasource.getAllSymbolFees(),
        ).thenAnswer((_) async => Right(tResponse));

        // act
        final result = await repository.getAllSymbolFees();

        // assert
        expect(result.isRight(), true);
        final feeMap = result.getOrElse((_) => throw Exception());
        expect(feeMap.containsKey('BTCUSDC'), true);
        expect(feeMap['BTCUSDC']?.makerFee, 0.001);
        verify(() => mockRemoteDatasource.getAllSymbolFees()).called(1);
      },
    );
  });
}

