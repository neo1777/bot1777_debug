import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/bloc/strategy_state_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/widgets/dashboard_card.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/widgets/strategy_state_card_content.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/trading_control_panel.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/price_display_card.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_bloc_real.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_state.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/widgets/strategy_targets_card.dart';

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 400).floor().clamp(1, 4);

        return GridView.count(
          padding: const EdgeInsets.all(16.0),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: crossAxisCount > 2 ? 0.85 : 0.75, // P5 fix
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // --- Card Stato Strategia ---
            BlocBuilder<StrategyStateBloc, StrategyStateState>(
              buildWhen:
                  (p, c) =>
                      p.strategyState != c.strategyState ||
                      p.failureMessage != c.failureMessage,
              builder: (context, state) {
                return DashboardCard(
                  title: 'Stato Strategia',
                  icon: Icons.auto_awesome_motion,
                  warningMessage: state.strategyState?.warningMessage,
                  child: StrategyStateCardContent(
                    symbol: state.currentSymbol,
                    state: state.strategyState,
                    failureMessage: state.failureMessage,
                  ),
                );
              },
            ),

            // --- Price Display Card ---
            BlocBuilder<PriceBlocReal, PriceState>(
              builder: (context, priceState) {
                return BlocBuilder<StrategyStateBloc, StrategyStateState>(
                  buildWhen: (p, c) => p.currentSymbol != c.currentSymbol,
                  builder: (context, dashboardState) {
                    final priceData =
                        priceState is PriceLoaded ? priceState.priceData : null;
                    return PriceDisplayCard(
                      symbol: dashboardState.currentSymbol,
                      priceData: priceData,
                    );
                  },
                );
              },
            ),

            // --- Strategy Targets Card ---
            const StrategyTargetsCard(),

            // --- Trading Control Panel ---
            BlocBuilder<StrategyStateBloc, StrategyStateState>(
              buildWhen:
                  (p, c) =>
                      p.strategyState != c.strategyState ||
                      p.currentSymbol != c.currentSymbol,
              builder: (context, state) {
                return TradingControlPanel(
                  currentSymbol: state.currentSymbol,
                  strategyState: state.strategyState,
                  onSymbolChanged: (symbol) {
                    context.read<StrategyStateBloc>().add(
                      SymbolChanged(symbol),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
