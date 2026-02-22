import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/balance.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_event.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_state.dart';

class BalancesList extends StatelessWidget {
  const BalancesList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        if (state is! AccountLoaded) {
          return const SizedBox.shrink();
        }

        if (state.filteredBalances.isEmpty) {
          return _buildEmptyState();
        }

        return Container(
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildListHeader(state, context),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.filteredBalances.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder:
                      (context, index) => _buildBalanceItem(
                        context,
                        state.filteredBalances[index],
                        index,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppTheme.mutedTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun saldo trovato',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prova a modificare i filtri per vedere più asset',
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(AccountLoaded state, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.list, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            'LISTA SALDI (${state.filteredBalances.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          _buildSortButton(context),
        ],
      ),
    );
  }

  Widget _buildSortButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort, color: AppTheme.mutedTextColor),
      tooltip: 'Ordina per',
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'asset_asc',
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha),
                  SizedBox(width: 8),
                  Text('Asset A-Z'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'asset_desc',
              child: Row(
                children: [
                  Icon(Icons.sort_by_alpha),
                  SizedBox(width: 8),
                  Text('Asset Z-A'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'total_desc',
              child: Row(
                children: [
                  Icon(Icons.trending_down),
                  SizedBox(width: 8),
                  Text('Totale Decrescente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'total_asc',
              child: Row(
                children: [
                  Icon(Icons.trending_up),
                  SizedBox(width: 8),
                  Text('Totale Crescente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'free_desc',
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet),
                  SizedBox(width: 8),
                  Text('Libero Decrescente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'free_asc',
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet),
                  SizedBox(width: 8),
                  Text('Libero Crescente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'locked_desc',
              child: Row(
                children: [
                  Icon(Icons.lock),
                  SizedBox(width: 8),
                  Text('Bloccato Decrescente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'locked_asc',
              child: Row(
                children: [
                  Icon(Icons.lock),
                  SizedBox(width: 8),
                  Text('Bloccato Crescente'),
                ],
              ),
            ),
          ],
      onSelected: (value) {
        BalanceSortType sortType;
        switch (value) {
          case 'asset_asc':
            sortType = BalanceSortType.alphabetical;
            break;
          case 'asset_desc':
            sortType = BalanceSortType.alphabeticalDesc;
            break;
          case 'free_asc':
            sortType = BalanceSortType.freeBalance;
            break;
          case 'free_desc':
            sortType = BalanceSortType.freeBalanceDesc;
            break;
          case 'total_asc':
            sortType = BalanceSortType.totalBalance;
            break;
          case 'total_desc':
            sortType = BalanceSortType.totalBalanceDesc;
            break;
          case 'locked_asc':
            sortType = BalanceSortType.lockedBalance;
            break;
          case 'locked_desc':
            sortType = BalanceSortType.lockedBalanceDesc;
            break;
          default:
            sortType = BalanceSortType.alphabetical;
        }

        BlocProvider.of<AccountBloc>(context).add(SortBalances(sortType));
      },
    );
  }

  Widget _buildBalanceItem(BuildContext context, Balance balance, int index) {
    final hasBalance = balance.total > 0;
    final isLocked = balance.locked > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Asset Icon and Info
          _buildAssetIcon(balance.asset),
          const SizedBox(width: 16),

          // Asset Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      balance.asset,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BLOCCATO',
                          style: TextStyle(
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getAssetDescription(balance.asset),
                  style: TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Balance Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance.free.toStringAsFixed(6),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color:
                      hasBalance ? AppTheme.textColor : AppTheme.mutedTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Libero',
                style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 11),
              ),
              if (isLocked) ...[
                const SizedBox(height: 8),
                Text(
                  balance.locked.toStringAsFixed(6),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: AppTheme.warningColor,
                  ),
                ),
                Text(
                  'Bloccato',
                  style: TextStyle(color: AppTheme.warningColor, fontSize: 10),
                ),
              ],
            ],
          ),

          // Total Balance
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance.total.toStringAsFixed(6),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color:
                      hasBalance
                          ? AppTheme.successColor
                          : AppTheme.mutedTextColor,
                ),
              ),
              if (balance.estimatedValueUSDC > 0 &&
                  balance.asset != 'USDC') ...[
                const SizedBox(height: 2),
                Text(
                  '≈ \$${balance.estimatedValueUSDC.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                'Totale',
                style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 11),
              ),
            ],
          ),

          // Action Button
          const SizedBox(width: 12),
          if (hasBalance)
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () => _showBalanceActions(context, balance),
              tooltip: 'Azioni',
            ),
        ],
      ),
    );
  }

  Widget _buildAssetIcon(String asset) {
    Color assetColor;
    IconData assetIcon;

    switch (asset) {
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
      case 'BNB':
        assetColor = const Color(0xFFF3BA2F);
        assetIcon = Icons.local_fire_department;
        break;
      case 'ADA':
        assetColor = const Color(0xFF0033AD);
        assetIcon = Icons.account_balance;
        break;
      case 'DOT':
        assetColor = const Color(0xFFE6007A);
        assetIcon = Icons.circle;
        break;
      case 'SOL':
        assetColor = const Color(0xFF9945FF);
        assetIcon = Icons.wb_sunny;
        break;
      case 'XRP':
        assetColor = const Color(0xFF23292F);
        assetIcon = Icons.water_drop;
        break;
      case 'DOGE':
        assetColor = const Color(0xFFC2A633);
        assetIcon = Icons.pets;
        break;
      default:
        assetColor = AppTheme.primaryColor;
        assetIcon = Icons.monetization_on;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: assetColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: assetColor.withValues(alpha: 0.3)),
      ),
      child: Icon(assetIcon, color: assetColor, size: 20),
    );
  }

  String _getAssetDescription(String asset) {
    switch (asset) {
      case 'USDC':
        return 'USD Coin';
      case 'BTC':
        return 'Bitcoin';
      case 'ETH':
        return 'Ethereum';
      case 'BNB':
        return 'Binance Coin';
      case 'ADA':
        return 'Cardano';
      case 'DOT':
        return 'Polkadot';
      case 'SOL':
        return 'Solana';
      case 'XRP':
        return 'Ripple';
      case 'DOGE':
        return 'Dogecoin';
      default:
        return 'Cryptocurrency';
    }
  }

  void _showBalanceActions(BuildContext context, Balance balance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildBalanceActionsSheet(context, balance),
    );
  }

  Widget _buildBalanceActionsSheet(BuildContext context, Balance balance) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.mutedTextColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    balance.asset,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AZIONI ${balance.asset}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Saldo: ${balance.total.toStringAsFixed(8)}',
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildActionTile(
                  context,
                  icon: Icons.send,
                  title: 'Trasferisci',
                  subtitle: 'Invia ${balance.asset} a un altro wallet',
                  enabled: balance.free > 0,
                  onTap: () => _showTransferDialog(context, balance),
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  context,
                  icon: Icons.swap_horiz,
                  title: 'Scambia',
                  subtitle: 'Converti ${balance.asset} in altro asset',
                  enabled: balance.free > 0,
                  onTap: () => _showTradeDialog(context, balance),
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  context,
                  icon: Icons.analytics,
                  title: 'Dettagli',
                  subtitle: 'Visualizza informazioni dettagliate',
                  enabled: true,
                  onTap: () => _showBalanceDetails(context, balance),
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  context,
                  icon: Icons.history,
                  title: 'Cronologia',
                  subtitle: 'Visualizza transazioni ${balance.asset}',
                  enabled: true,
                  onTap: () => _showBalanceHistory(context, balance),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                enabled
                    ? AppTheme.cardColor.withValues(alpha: 0.8)
                    : AppTheme.cardColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  enabled
                      ? AppTheme.primaryColor.withValues(alpha: 0.3)
                      : AppTheme.mutedTextColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      enabled
                          ? AppTheme.primaryColor.withValues(alpha: 0.2)
                          : AppTheme.mutedTextColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color:
                      enabled ? AppTheme.primaryColor : AppTheme.mutedTextColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: enabled ? Colors.white : AppTheme.mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.mutedTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.mutedTextColor,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransferDialog(BuildContext context, Balance balance) {
    Navigator.pop(context); // Close bottom sheet
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: Text('Trasferisci ${balance.asset}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Saldo disponibile: ${balance.free.toStringAsFixed(8)} ${balance.asset}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Questa funzionalità sarà disponibile prossimamente.\n'
                  'Permetterà di trasferire fondi a indirizzi esterni.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CHIUDI'),
              ),
            ],
          ),
    );
  }

  void _showTradeDialog(BuildContext context, Balance balance) {
    Navigator.pop(context); // Close bottom sheet
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: Text('Scambia ${balance.asset}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Saldo disponibile: ${balance.free.toStringAsFixed(8)} ${balance.asset}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Questa funzionalità sarà disponibile prossimamente.\n'
                  'Permetterà di convertire asset tramite spot trading.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CHIUDI'),
              ),
            ],
          ),
    );
  }

  void _showBalanceDetails(BuildContext context, Balance balance) {
    Navigator.pop(context); // Close bottom sheet
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: Text('Dettagli ${balance.asset}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Asset:', balance.asset),
                _buildDetailRow(
                  'Saldo Totale:',
                  '${balance.total.toStringAsFixed(8)} ${balance.asset}',
                ),
                _buildDetailRow(
                  'Saldo Libero:',
                  '${balance.free.toStringAsFixed(8)} ${balance.asset}',
                ),
                _buildDetailRow(
                  'Saldo Bloccato:',
                  '${balance.locked.toStringAsFixed(8)} ${balance.asset}',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informazioni:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Saldo Libero: Disponibile per trading\n'
                        '• Saldo Bloccato: In ordini aperti o altre operazioni',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CHIUDI'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showBalanceHistory(BuildContext context, Balance balance) {
    Navigator.pop(context); // Close bottom sheet
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: Text('Cronologia ${balance.asset}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 48, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'Cronologia transazioni sarà disponibile prossimamente.\n'
                  'Mostrerà tutti i movimenti per questo asset.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CHIUDI'),
              ),
            ],
          ),
    );
  }
}
