import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_state.dart';
import 'package:neotradingbotfront1777/domain/entities/balance.dart';

class AccountOverviewCard extends StatelessWidget {
  const AccountOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        if (state is! AccountLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state),
              const SizedBox(height: 24),
              _buildMainStats(context, state),
              const SizedBox(height: 20),
              _buildTopBalances(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AccountLoaded state) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.account_balance,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'PANORAMICA ACCOUNT',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        if (state.isStreaming)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.successColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMainStats(BuildContext context, AccountLoaded state) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildMainBalanceCard(context, state)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatsGrid(context, state)),
      ],
    );
  }

  Widget _buildMainBalanceCard(BuildContext context, AccountLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Bilancio Totale',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${state.totalBalanceUSDC.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Valore Totale Stimato (USDC)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AccountLoaded state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Asset Totali',
                state.totalAssets.toString(),
                Icons.category,
                AppTheme.mutedTextColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Con Saldo',
                state.assetsWithBalance.toString(),
                Icons.check_circle,
                AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'Asset Filtrati',
          state.filteredBalances.length.toString(),
          Icons.filter_list,
          AppTheme.primaryColor,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child:
          isWide
              ? Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: AppTheme.mutedTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTopBalances(BuildContext context, AccountLoaded state) {
    final topBalances = [
      if (state.usdcBalance != null) state.usdcBalance!,
      if (state.btcBalance != null) state.btcBalance!,
      if (state.ethBalance != null) state.ethBalance!,
    ];

    if (topBalances.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asset Principali',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedTextColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children:
              topBalances.map((balance) {
                final index = topBalances.indexOf(balance);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < topBalances.length - 1 ? 12.0 : 0,
                    ),
                    child: _buildBalanceChip(balance),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildBalanceChip(Balance balance) {
    Color assetColor;
    IconData assetIcon;

    switch (balance.asset) {
      case 'USDC':
        assetColor = AppTheme.successColor;
        assetIcon = Icons.attach_money;
        break;
      case 'BTC':
        assetColor = const Color(0xFFF7931A);
        assetIcon = Icons.currency_bitcoin;
        break;
      case 'ETH':
        assetColor = const Color(0xFF627EEA);
        assetIcon = Icons.diamond;
        break;
      default:
        assetColor = AppTheme.primaryColor;
        assetIcon = Icons.monetization_on;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: assetColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: assetColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(assetIcon, color: assetColor, size: 20),
              const SizedBox(width: 8),
              Text(
                balance.asset,
                style: TextStyle(
                  color: assetColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            balance.free.toStringAsFixed(6),
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            'Libero',
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
