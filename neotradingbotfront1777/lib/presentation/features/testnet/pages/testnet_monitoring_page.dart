import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/snackbar_helper.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_event.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_state.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/main_shell.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/gradient_icon_container.dart';
import 'package:neotradingbotfront1777/core/utils/price_formatter.dart';
import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';

class TestnetMonitoringPage extends StatelessWidget {
  const TestnetMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isTestMode = settingsState.settings?.isTestMode ?? false;

        return Scaffold(
          backgroundColor:
              isTestMode
                  ? Colors.orange.withAlpha(25)
                  : AppTheme.backgroundColor,
          appBar: AppBar(
            centerTitle: true,
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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientIconContainer(
                  icon: isTestMode ? Icons.science : Icons.lock_outline,
                  gradient:
                      isTestMode
                          ? const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                          )
                          : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'TESTNET MONITORING',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color:
                        isTestMode ? Colors.orangeAccent : AppTheme.textColor,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              BlocBuilder<AccountBloc, AccountState>(
                builder: (context, state) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed:
                        state is AccountLoading
                            ? null
                            : () {
                              context.read<AccountBloc>().add(
                                const RefreshAccountInfo(),
                              );
                            },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(context, isTestMode),
                const SizedBox(height: 24),
                Text(
                  'Bilanci Testnet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBalanceList(context, isTestMode),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isTestMode) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isTestMode
                  ? Colors.orangeAccent.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isTestMode ? Colors.orangeAccent : Colors.grey)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTestMode ? Icons.science : Icons.lock_outline,
                    color: isTestMode ? Colors.orangeAccent : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTestMode
                            ? 'Modalità Test Attiva'
                            : 'Modalità Reale Attiva',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTestMode
                            ? 'Stai operando sul Testnet di Binance.'
                            : 'Stai operando sul network principale di Binance.',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isTestMode)
                  ElevatedButton.icon(
                    onPressed: () {
                      final state = context.read<SettingsBloc>().state;
                      final updated =
                          state.settings?.copyWith(isTestMode: true) ??
                          const AppSettings(
                            tradeAmount: 100.0,
                            profitTargetPercentage: 1.5,
                            stopLossPercentage: 5.0,
                            dcaDecrementPercentage: 1.0,
                            maxOpenTrades: 5,
                            isTestMode: true,
                          );
                      context.read<SettingsBloc>().add(
                        SettingsUpdated(updated),
                      );
                      AppSnackBar.showSuccess(
                        context,
                        'Modalità Testnet Attivata!',
                      );
                    },
                    icon: const Icon(Icons.science),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    label: const Text('ATTIVA TESTNET'),
                  ),
              ],
            ),
            if (isTestMode) ...[
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      label: 'API Endpoint',
                      value: 'testnet.binance.vision',
                    ),
                  ),
                  Expanded(
                    child: _InfoTile(
                      label: 'WebSocket',
                      value:
                          isTestMode
                              ? 'stream.testnet.binance.vision/ws'
                              : 'stream.binance.com:9443/ws',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    const ClipboardData(
                      text: 'https://testnet.binance.vision/',
                    ),
                  );
                  AppSnackBar.showInfo(context, 'Link Testnet Faucet copiato!');
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copia Link Faucet (Fondi Virtuali)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: const BorderSide(color: Colors.orangeAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceList(BuildContext context, bool isTestMode) {
    if (!isTestMode) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Attiva la Modalità Test nelle impostazioni\nper vedere i bilanci virtuali.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        if (state is AccountLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AccountError) {
          return Center(child: Text('Errore: ${state.message}'));
        }

        if (state is AccountLoaded) {
          final balances =
              state.accountInfo.balances.where((b) => b.total > 0).toList();

          if (balances.isEmpty) {
            return const Center(
              child: Text('Nessun fondo disponibile sul Testnet.'),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: balances.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final balance = balances[index];
              return Card(
                elevation: 0,
                color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      balance.asset[0],
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        balance.asset,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isTestMode) ...[
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
                              Icon(
                                Icons.science,
                                size: 12,
                                color: Colors.white,
                              ),
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
                  ),
                  subtitle: Text(
                    'Disponibile: ${PriceFormatter.format(balance.free)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total: ${PriceFormatter.format(balance.total)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (balance.locked > 0)
                        Text(
                          'Locked: ${PriceFormatter.format(balance.locked)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const Center(child: Text('Caricamento bilanci...'));
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
