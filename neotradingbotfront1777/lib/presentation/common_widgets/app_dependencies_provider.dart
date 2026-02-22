import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_bloc_real.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_event.dart';
import 'package:neotradingbotfront1777/presentation/blocs/strategy_control/strategy_control_bloc.dart';
import 'package:neotradingbotfront1777/presentation/blocs/system_log/system_log_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/bloc/strategy_state_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_event.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_event.dart';

/// Provides global application dependencies (BLoCs) to the shell.
/// Extracted from AppRouter to separate dependency injection from routing logic.
class AppDependenciesProvider extends StatelessWidget {
  final Widget child;

  const AppDependenciesProvider({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    // Determine the initial symbol context
    final initialSymbol = sl<SymbolContext>().activeSymbol;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) =>
                  sl<StrategyStateBloc>()
                    ..add(StrategyStateSubscriptionRequested(initialSymbol)),
        ),
        BlocProvider(
          create:
              (context) =>
                  sl<SystemLogBloc>()
                    ..add(const SystemLogSubscriptionRequested()),
        ),
        BlocProvider(create: (context) => sl<StrategyControlBloc>()),
        BlocProvider(
          create:
              (context) =>
                  sl<TradeHistoryBloc>()..add(const LoadTradeHistory()),
        ),
        BlocProvider(
          create:
              (context) =>
                  sl<PriceBlocReal>()
                    ..add(SubscribeToPriceUpdates(initialSymbol)),
        ),
        BlocProvider(
          create: (context) => sl<SettingsBloc>()..add(SettingsFetched()),
        ),
        BlocProvider(
          create:
              (context) =>
                  sl<AccountBloc>()
                    ..add(const LoadAccountInfo())
                    ..add(const WatchAccountInfo()),
        ),
      ],
      child: child,
    );
  }
}
