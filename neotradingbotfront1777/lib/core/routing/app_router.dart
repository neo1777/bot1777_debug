import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/main_shell.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/app_dependencies_provider.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/pages/dashboard_page.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/pages/settings_page.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/pages/log_settings_page.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/pages/backtest_page.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/pages/trade_history_page.dart';
import 'package:neotradingbotfront1777/presentation/features/account/pages/account_page.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/pages/orders_page.dart';
import 'package:neotradingbotfront1777/presentation/features/system_logs/pages/system_logs_page.dart';
import 'package:neotradingbotfront1777/presentation/features/diagnostics/pages/tls_diagnostics_page.dart';
import 'package:neotradingbotfront1777/presentation/features/testnet/pages/testnet_monitoring_page.dart';

class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: '/dashboard', // Partiamo dalla dashboard
    routes: [
      // La ShellRoute avvolge tutte le pagine principali,
      // fornendo il layout comune (NavigationRail/Drawer) e i BLoC necessari.
      ShellRoute(
        builder: (context, state, child) {
          return AppDependenciesProvider(child: MainShell(child: child));
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/testnet',
            builder: (context, state) => const TestnetMonitoringPage(),
          ),
          GoRoute(
            path: '/account',
            builder: (context, state) => const AccountPage(),
          ),
          GoRoute(
            path: '/orders/:symbol',
            builder: (context, state) {
              final symbol =
                  state.pathParameters['symbol'] ??
                  sl<SymbolContext>().activeSymbol; // Fallback
              return OrdersPage(symbol: symbol);
            },
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const TradeHistoryPage(),
          ),
          GoRoute(
            path: '/logs',
            builder: (context, state) => const SystemLogsPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/log-settings',
            builder: (context, state) => const LogSettingsPage(),
          ),
          GoRoute(
            path: '/diagnostics/tls',
            builder: (context, state) => const TlsDiagnosticsPage(),
          ),
          GoRoute(
            path: '/backtest',
            builder: (context, state) => const BacktestPage(),
          ),
        ],
      ),
      // Qui, in futuro, aggiungeremo rotte pubbliche come /login
    ],
    // Gestione errori di base
    errorBuilder:
        (context, state) => Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pagina non trovata',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error.toString(),
                  style: const TextStyle(color: AppTheme.mutedTextColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Torna alla Dashboard'),
                ),
              ],
            ),
          ),
        ),
  );
}
