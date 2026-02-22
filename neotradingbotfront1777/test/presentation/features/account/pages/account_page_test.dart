import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neotradingbotfront1777/domain/entities/account_info.dart';
import 'package:neotradingbotfront1777/domain/entities/balance.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_event.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_state.dart';
import 'package:neotradingbotfront1777/presentation/features/account/pages/account_page.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountBloc extends MockBloc<AccountEvent, AccountState>
    implements AccountBloc {}

void main() {
  late MockAccountBloc mockAccountBloc;

  final tBalanceUSDC = const Balance(asset: 'USDC', free: 1000.0, locked: 0.0);
  final tBalanceBTC = const Balance(asset: 'BTC', free: 0.5, locked: 0.1);
  final tAccountInfo = AccountInfo(
    balances: [tBalanceUSDC, tBalanceBTC],
    totalEstimatedValueUSDC: 15000.0,
    totalEstimatedValueUSDCStr: '15000.00 USDC',
  );

  setUp(() {
    mockAccountBloc = MockAccountBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AccountBloc>.value(
        value: mockAccountBloc,
        child: const AccountPage(),
      ),
    );
  }

  group('AccountPage', () {
    testWidgets(
      'renders CircularProgressIndicator when state is AccountLoading',
      (tester) async {
        when(() => mockAccountBloc.state).thenReturn(const AccountLoading());

        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('renders error message when state is AccountError', (
      tester,
    ) async {
      const errorMessage = 'Failed to load account';
      when(
        () => mockAccountBloc.state,
      ).thenReturn(const AccountError(errorMessage));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Errore Account'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Riprova'), findsOneWidget);
    });

    testWidgets('renders account details when state is AccountLoaded', (
      tester,
    ) async {
      when(() => mockAccountBloc.state).thenReturn(
        AccountLoaded(
          accountInfo: tAccountInfo,
          filteredBalances: tAccountInfo.balances,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('ACCOUNT INFO'), findsOneWidget);
      expect(find.text(r'$15000.00'), findsOneWidget);
      expect(find.text('BTC'), findsNWidgets(3)); // Card, Filters, and List
      expect(find.text('USDC'), findsNWidgets(3)); // Card, Filters, and List
      expect(find.text('0.500000'), findsNWidgets(2)); // Card, List Free
      expect(
        find.text('1000.000000'),
        findsNWidgets(3),
      ); // Card, List Free, List Total
    });

    testWidgets('renders empty state when filteredBalances is empty', (
      tester,
    ) async {
      when(() => mockAccountBloc.state).thenReturn(
        AccountLoaded(accountInfo: tAccountInfo, filteredBalances: const []),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Nessun saldo trovato'), findsOneWidget);
      expect(
        find.text('Prova a modificare i filtri per vedere più asset'),
        findsOneWidget,
      );
    });

    testWidgets('adds RefreshAccountInfo when refresh button is pressed', (
      tester,
    ) async {
      when(() => mockAccountBloc.state).thenReturn(
        AccountLoaded(
          accountInfo: tAccountInfo,
          filteredBalances: tAccountInfo.balances,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      verify(() => mockAccountBloc.add(const RefreshAccountInfo())).called(1);
    });

    testWidgets('adds WatchAccountInfo when stream toggle button is pressed', (
      tester,
    ) async {
      when(() => mockAccountBloc.state).thenReturn(
        AccountLoaded(
          accountInfo: tAccountInfo,
          filteredBalances: tAccountInfo.balances,
          isStreaming: false,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pump();

      verify(
        () => mockAccountBloc.add(const WatchAccountInfo(isStreaming: true)),
      ).called(1);
    });
  });
}

