import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/bloc/strategy_state_bloc.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/charts/trading_dashboard_charts_simple.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/price_display_card.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/trading_control_panel.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/widgets/dashboard_card.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/widgets/strategy_state_card_content.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/widgets/strategy_targets_card.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_bloc_real.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_state.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/main_shell.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardView();
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
            MediaQuery.of(context).size.width <= 768
                ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed:
                      () =>
                          MainShell.mobileScaffoldKey.currentState
                              ?.openDrawer(),
                )
                : null,
        title: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final isTest = state.settings?.isTestMode ?? false;
            return Row(
              children: [
                const Text('Dashboard'),
                if (isTest) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade700,
                          Colors.orange.shade900,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withAlpha(50),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'TESTNET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          BlocBuilder<StrategyStateBloc, StrategyStateState>(
            builder: (context, state) {
              final connectionColor = _getConnectionColor(state.status);
              final connectionText = _getConnectionText(state.status);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Stato connessione gRPC: $connectionText',
                    waitDuration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connectionColor,
                        boxShadow: [
                          BoxShadow(
                            color: connectionColor.withAlpha(120),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Connessione gRPC al backend',
                    waitDuration: const Duration(milliseconds: 300),
                    child: Text(
                      connectionText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed:
                        state.status == StrategyStateStatus.loading
                            ? null
                            : () => context.read<StrategyStateBloc>().add(
                              StrategyStateSubscriptionRequested(
                                state.currentSymbol,
                              ),
                            ),
                    tooltip: 'Ricarica stato (gRPC)',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<StrategyStateBloc, StrategyStateState>(
        builder: (context, state) {
          if (state.status == StrategyStateStatus.initial ||
              state.status == StrategyStateStatus.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connessione al backend (gRPC) e caricamento dati...'),
                ],
              ),
            );
          }

          final currentSymbol = sl<SymbolContext>().activeSymbol;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1000;

                if (isDesktop) {
                  return Column(
                    children: [
                      // Top Row: Metrics (3 columns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 280,
                              child: DashboardCard(
                                title: 'Stato Strategia',
                                icon: Icons.auto_awesome_motion,
                                warningMessage:
                                    state.strategyState?.warningMessage,
                                child: StrategyStateCardContent(
                                  symbol: state.currentSymbol,
                                  state: state.strategyState,
                                  failureMessage: state.failureMessage,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 280,
                              child: BlocBuilder<PriceBlocReal, PriceState>(
                                builder: (context, priceState) {
                                  final priceData =
                                      priceState is PriceLoaded
                                          ? priceState.priceData
                                          : null;
                                  return PriceDisplayCard(
                                    symbol: state.currentSymbol,
                                    priceData: priceData,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: SizedBox(
                              height: 280,
                              child: StrategyTargetsCard(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Bottom Row: Controls & Charts
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 1,
                            child: TradingControlPanel(
                              currentSymbol: state.currentSymbol,
                              strategyState: state.strategyState,
                              onSymbolChanged: (symbol) {
                                context.read<StrategyStateBloc>().add(
                                  SymbolChanged(symbol),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 600,
                              decoration: AppTheme.cardDecoration,
                              padding: const EdgeInsets.all(16),
                              child: TradingDashboardChartsSimple(
                                symbol: currentSymbol,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Mobile Layout
                  return Column(
                    children: [
                      DashboardCard(
                        title: 'Stato Strategia',
                        icon: Icons.auto_awesome_motion,
                        warningMessage: state.strategyState?.warningMessage,
                        child: StrategyStateCardContent(
                          symbol: state.currentSymbol,
                          state: state.strategyState,
                          failureMessage: state.failureMessage,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<PriceBlocReal, PriceState>(
                        builder: (context, priceState) {
                          final priceData =
                              priceState is PriceLoaded
                                  ? priceState.priceData
                                  : null;
                          return PriceDisplayCard(
                            symbol: state.currentSymbol,
                            priceData: priceData,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const StrategyTargetsCard(),
                      const SizedBox(height: 16),
                      TradingControlPanel(
                        currentSymbol: state.currentSymbol,
                        strategyState: state.strategyState,
                        onSymbolChanged: (symbol) {
                          context.read<StrategyStateBloc>().add(
                            SymbolChanged(symbol),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 400,
                        decoration: AppTheme.cardDecoration,
                        padding: const EdgeInsets.all(16),
                        child: TradingDashboardChartsSimple(
                          symbol: currentSymbol,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Color _getConnectionColor(StrategyStateStatus status) {
    switch (status) {
      case StrategyStateStatus.initial:
      case StrategyStateStatus.loading:
        return Colors.orange;
      case StrategyStateStatus.subscribed:
        return Colors.green;
      case StrategyStateStatus.failure:
        return Colors.red;
    }
  }

  String _getConnectionText(StrategyStateStatus status) {
    switch (status) {
      case StrategyStateStatus.initial:
        return 'Inizializzazione...';
      case StrategyStateStatus.loading:
        return 'Connessione...';
      case StrategyStateStatus.subscribed:
        return 'gRPC Online';
      case StrategyStateStatus.failure:
        return 'gRPC Offline';
    }
  }
}
