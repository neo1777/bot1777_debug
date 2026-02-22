import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart'
    as domain;
import 'package:neotradingbotfront1777/presentation/blocs/price/price_bloc_real.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_state.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/bloc/strategy_state_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';
import 'package:neotradingbotfront1777/domain/services/fee_aware_calculation_service.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotfront1777/domain/entities/fee_info.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/utils/price_formatter.dart';

class StrategyTargetsCard extends StatefulWidget {
  const StrategyTargetsCard({super.key});

  @override
  State<StrategyTargetsCard> createState() => _StrategyTargetsCardState();
}

class _StrategyTargetsCardState extends State<StrategyTargetsCard> {
  FeeInfo? _currentFees;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    final feeRepository = sl<IFeeRepository>();

    // Ottieni il simbolo corrente dallo stato della strategia
    final strategyState = context.read<StrategyStateBloc>().state;
    final currentSymbol = strategyState.currentSymbol;

    try {
      final feesResult = await feeRepository.getSymbolFees(currentSymbol);
      feesResult.fold(
        (failure) => null, // Ignora errori, usa fee di default
        (fees) => setState(() => _currentFees = fees),
      );
    } catch (e) {
      // Ignora errori, usa fee di default
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilizziamo solo BlocBuilder per reagire immediatamente ai cambiamenti
    // sia delle impostazioni che dello stato della strategia
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) {
        // Ricostruisci quando cambiano le impostazioni o lo stato
        return previous.settings != current.settings ||
            previous.status != current.status;
      },
      builder: (context, settingsState) {
        // Se le impostazioni non sono caricate, mostra un indicatore di caricamento
        if (settingsState.settings == null) {
          // Carica automaticamente le impostazioni solo se non sono ancora state caricate
          // e se non è già in corso un caricamento
          if (settingsState.status == SettingsStatus.initial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Verifica di nuovo lo stato per evitare chiamate duplicate
              if (context.read<SettingsBloc>().state.status ==
                  SettingsStatus.initial) {
                context.read<SettingsBloc>().add(SettingsFetched());
              }
            });
          }

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Caricamento impostazioni...'),
                ],
              ),
            ),
          );
        }

        return BlocBuilder<StrategyStateBloc, StrategyStateState>(
          buildWhen: (previous, current) {
            // Ricostruisci quando cambia lo stato della strategia
            final symbolChanged =
                previous.currentSymbol != current.currentSymbol;

            // Se cambia il simbolo, ricarica le fee
            if (symbolChanged) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadFees();
              });
            }

            return previous.strategyState != current.strategyState ||
                symbolChanged;
          },
          builder: (context, strategyState) {
            return BlocBuilder<PriceBlocReal, PriceState>(
              buildWhen: (previous, current) {
                // Ricostruisci quando cambia il prezzo
                return previous is PriceLoaded != current is PriceLoaded ||
                    (previous is PriceLoaded &&
                        current is PriceLoaded &&
                        previous.priceData.currentPrice !=
                            current.priceData.currentPrice);
              },
              builder: (context, priceState) {
                return _buildCard(
                  context,
                  strategyState.strategyState,
                  settingsState,
                  priceState is PriceLoaded
                      ? priceState.priceData.currentPrice
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    domain.StrategyState? s,
    SettingsState settingsState,
    double? currentPrice,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.warningColor,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.warningColor.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'OBIETTIVI STRATEGIA',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                          color: AppTheme.textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                if (currentPrice != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Prezzo attuale: \$${PriceFormatter.format(currentPrice)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if ((s?.status == domain.StrategyStatus.running) &&
                ((s?.openTradesCount ?? 0) == 0))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withAlpha(20),
                  border: Border.all(color: Colors.orangeAccent.withAlpha(80)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'In attesa del primo BUY... (slot DCA e target saranno disponibili dopo il primo acquisto)',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (settingsState.settings == null)
              const Center(child: CircularProgressIndicator())
            else
              _buildTargets(context, s, settingsState, currentPrice),
          ],
        ),
      ),
    );
  }

  Widget _buildTargets(
    BuildContext context,
    domain.StrategyState? s,
    SettingsState settingsState,
    double? currentPrice,
  ) {
    final settings = settingsState.settings!;
    final hasPosition = (s?.openTradesCount ?? 0) > 0;

    final averagePrice = s?.averagePrice ?? 0.0;
    final lastBuyPrice = s?.lastBuyPrice ?? 0.0;
    final totalQty = s?.totalQuantity ?? 0.0;

    // Calcola target considerando le fee se abilitate
    final tpTarget =
        hasPosition
            ? (settings.enableFeeAwareTrading && _currentFees != null)
                ? FeeAwareCalculationService.calculateTakeProfitTarget(
                  averagePrice: averagePrice,
                  profitTargetPercentage: settings.profitTargetPercentage,
                  fees: _currentFees,
                  isMaker: false, // Vendita tipicamente taker
                )
                : averagePrice * (1 + settings.profitTargetPercentage / 100)
            : 0.0;

    final slTarget =
        hasPosition
            ? (settings.enableFeeAwareTrading && _currentFees != null)
                ? FeeAwareCalculationService.calculateStopLossTarget(
                  averagePrice: averagePrice,
                  stopLossPercentage: settings.stopLossPercentage,
                  fees: _currentFees,
                  isMaker: false, // Vendita tipicamente taker
                )
                : averagePrice * (1 - settings.stopLossPercentage / 100)
            : 0.0;

    final nextDcaTarget =
        !hasPosition
            ? 0.0
            : (lastBuyPrice > 0 && settings.dcaDecrementPercentage > 0)
            ? lastBuyPrice * (1 - settings.dcaDecrementPercentage / 100)
            : 0.0;

    double? distToTp;
    double? distToSl;
    double? distToDca;
    if (currentPrice != null && currentPrice > 0) {
      distToTp =
          tpTarget > 0
              ? ((tpTarget - currentPrice) / currentPrice) * 100
              : null;
      distToSl =
          slTarget > 0
              ? ((currentPrice - slTarget) / currentPrice) * 100
              : null; // quanto manca a scendere
      distToDca =
          nextDcaTarget > 0
              ? ((currentPrice - nextDcaTarget) / currentPrice) * 100
              : null; // quanto manca a scendere
    }

    final remainingDcaSlots = (settings.maxOpenTrades -
            (s?.openTradesCount ?? 0))
        .clamp(0, settings.maxOpenTrades);
    // Calcola profitto atteso considerando le fee se abilitate
    final expectedProfitAtTp =
        (hasPosition && totalQty > 0)
            ? (settings.enableFeeAwareTrading && _currentFees != null)
                ? FeeAwareCalculationService.calculateNetProfitAtTarget(
                  targetPrice: tpTarget,
                  averagePrice: averagePrice,
                  quantity: totalQty,
                  fees: _currentFees!,
                  isMaker: false, // Vendita tipicamente taker
                )
                : (tpTarget - averagePrice) * totalQty
            : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _tile(
                context,
                label:
                    settings.enableFeeAwareTrading && _currentFees != null
                        ? 'Take Profit (Net)'
                        : 'Take Profit',
                value:
                    hasPosition ? '\$${PriceFormatter.format(tpTarget)}' : '—',
                subtitle:
                    hasPosition && distToTp != null
                        ? 'Distanza: ${distToTp >= 0 ? distToTp.toStringAsFixed(2) : '0.00'}%${settings.enableFeeAwareTrading && _currentFees != null ? ' (con fee)' : ''}'
                        : 'N/D',
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tile(
                context,
                label:
                    settings.enableFeeAwareTrading && _currentFees != null
                        ? 'Stop Loss (Net)'
                        : 'Stop Loss',
                value:
                    hasPosition ? '\$${PriceFormatter.format(slTarget)}' : '—',
                subtitle:
                    hasPosition && distToSl != null
                        ? 'Distanza: ${distToSl >= 0 ? distToSl.toStringAsFixed(2) : '0.00'}%${settings.enableFeeAwareTrading && _currentFees != null ? ' (con fee)' : ''}'
                        : 'N/D',
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _tile(
                context,
                label: 'Prossimo DCA',
                value:
                    hasPosition && nextDcaTarget > 0
                        ? '\$${PriceFormatter.format(nextDcaTarget)}'
                        : '—',
                subtitle:
                    hasPosition && distToDca != null
                        ? 'A -${distToDca >= 0 ? distToDca.toStringAsFixed(2) : '0.00'}%'
                        : 'N/D',
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tile(
                context,
                label: 'Slot DCA residui',
                value: remainingDcaSlots.toString(),
                subtitle: 'Max: ${settings.maxOpenTrades}',
                color: AppTheme.mutedTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _tile(
                context,
                label: 'Prezzo medio',
                value:
                    hasPosition
                        ? '\$${PriceFormatter.format(averagePrice)}'
                        : '—',
                subtitle: 'Qty: ${totalQty.toStringAsFixed(8)}',
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tile(
                context,
                label:
                    settings.enableFeeAwareTrading && _currentFees != null
                        ? 'Profitto Netto a TP'
                        : 'Profitto a TP (stima)',
                value:
                    hasPosition
                        ? '\$${expectedProfitAtTp.toStringAsFixed(4)}'
                        : '—',
                subtitle:
                    hasPosition
                        ? (settings.enableFeeAwareTrading &&
                                _currentFees != null
                            ? 'dopo fee (${(_currentFees!.getEffectiveFeePercentage(isMaker: false) * 100).toStringAsFixed(3)}%)'
                            : 'su qty attuale')
                        : 'N/D',
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context, {
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(70), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          AutoSizeText(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            minFontSize: 11,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedTextColor),
          ),
        ],
      ),
    );
  }
}
