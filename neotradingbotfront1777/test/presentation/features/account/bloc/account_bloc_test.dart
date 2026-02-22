import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/account_info.dart';
import 'package:neotradingbotfront1777/domain/entities/balance.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_account_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_event.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_state.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

class MockAccountRepository extends Mock implements IAccountRepository {}

void main() {
  late MockAccountRepository mockAccountRepository;
  late AccountBloc accountBloc;
  late StreamController<Either<Failure, AccountInfo>> accountStreamController;

  final tBalanceUSDC = Balance(asset: 'USDC', free: 1000.0, locked: 0.0);
  final tBalanceBTC = Balance(asset: 'BTC', free: 0.5, locked: 0.1);
  final tBalanceSmall = Balance(asset: 'DUST', free: 0.000000001, locked: 0.0);

  final tAccountInfo = AccountInfo(
    balances: [tBalanceUSDC, tBalanceBTC, tBalanceSmall],
    totalEstimatedValueUSDC: 15000.0,
    totalEstimatedValueUSDCStr: '15000.00 USDC',
  );

  final tFailure = ServerFailure(message: 'Account info failure');

  setUp(() {
    mockAccountRepository = MockAccountRepository();
    accountStreamController =
        StreamController<Either<Failure, AccountInfo>>.broadcast();

    when(
      () => mockAccountRepository.getAccountInfo(),
    ).thenAnswer((_) async => Right(tAccountInfo));
    when(
      () => mockAccountRepository.subscribeAccountInfo(),
    ).thenAnswer((_) => accountStreamController.stream);

    accountBloc = AccountBloc(accountRepository: mockAccountRepository);
  });

  tearDown(() {
    accountStreamController.close();
    accountBloc.close();
  });

  group('AccountBloc', () {
    test('initial state is AccountInitial', () {
      expect(accountBloc.state, const AccountInitial());
    });

    blocTest<AccountBloc, AccountState>(
      'emits [AccountLoading, AccountLoaded] when LoadAccountInfo is added and succeeds',
      build: () => accountBloc,
      act: (bloc) => bloc.add(const LoadAccountInfo()),
      expect:
          () => [
            const AccountLoading(),
            isA<AccountLoaded>().having(
              (s) => s.accountInfo,
              'accountInfo',
              tAccountInfo,
            ),
          ],
    );

    blocTest<AccountBloc, AccountState>(
      'emits [AccountLoading, AccountError] when LoadAccountInfo fails',
      build: () {
        when(
          () => mockAccountRepository.getAccountInfo(),
        ).thenAnswer((_) async => Left(tFailure));
        return accountBloc;
      },
      act: (bloc) => bloc.add(const LoadAccountInfo()),
      expect: () => [const AccountLoading(), AccountError(tFailure.message)],
    );

    blocTest<AccountBloc, AccountState>(
      'emits [AccountLoading, AccountLoaded] and handles stream when WatchAccountInfo is added',
      build: () => accountBloc,
      act: (bloc) async {
        bloc.add(const WatchAccountInfo(isStreaming: true));
        await Future.delayed(Duration.zero);
        accountStreamController.add(Right(tAccountInfo));
      },
      expect:
          () => [
            const AccountLoading(),
            isA<AccountLoaded>().having(
              (s) => s.isStreaming,
              'isStreaming',
              false,
            ),
            isA<AccountLoaded>().having(
              (s) => s.isStreaming,
              'isStreaming',
              true,
            ),
          ],
    );

    blocTest<AccountBloc, AccountState>(
      'filters results by asset when FilterBalancesByAsset is added',
      build: () => accountBloc,
      seed:
          () => AccountLoaded(
            accountInfo: tAccountInfo,
            filteredBalances: tAccountInfo.balances,
          ),
      act: (bloc) => bloc.add(const FilterBalancesByAsset('BTC')),
      expect:
          () => [
            isA<AccountLoaded>()
                .having((s) => s.assetFilter, 'assetFilter', 'BTC')
                .having((s) => s.filteredBalances.length, 'length', 1)
                .having((s) => s.filteredBalances.first.asset, 'asset', 'BTC'),
          ],
    );

    blocTest<AccountBloc, AccountState>(
      'toggles non-zero filter when ShowOnlyNonZeroBalances is added',
      build: () => accountBloc,
      seed:
          () => AccountLoaded(
            accountInfo: tAccountInfo,
            filteredBalances: tAccountInfo.balances,
            showOnlyNonZero: false,
          ),
      act: (bloc) => bloc.add(const ShowOnlyNonZeroBalances(true)),
      expect:
          () => [
            isA<AccountLoaded>()
                .having((s) => s.showOnlyNonZero, 'showOnlyNonZero', true)
                .having(
                  (s) => s.filteredBalances.length,
                  'length',
                  2,
                ), // BTC and USDC (DUST filtered)
          ],
    );

    blocTest<AccountBloc, AccountState>(
      'sorts balances when SortBalances is added',
      build: () => accountBloc,
      seed:
          () => AccountLoaded(
            accountInfo: tAccountInfo,
            filteredBalances: tAccountInfo.balances,
          ),
      act:
          (bloc) =>
              bloc.add(const SortBalances(BalanceSortType.totalBalanceDesc)),
      expect:
          () => [
            isA<AccountLoaded>()
                .having(
                  (s) => s.sortType,
                  'sortType',
                  BalanceSortType.totalBalanceDesc,
                )
                .having((s) => s.filteredBalances.first.asset, 'first', 'USDC'),
          ],
    );
  });
}
