import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_event.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_state.dart';
import 'package:neotradingbotfront1777/presentation/features/account/widgets/account_overview_card.dart';
import 'package:neotradingbotfront1777/presentation/features/account/widgets/balances_list.dart';
import 'package:neotradingbotfront1777/presentation/features/account/widgets/account_filters.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/main_shell.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountView();
  }
}

class AccountView extends StatelessWidget {
  const AccountView({super.key});

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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ACCOUNT INFO',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          BlocBuilder<AccountBloc, AccountState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state is AccountLoaded && state.isStreaming
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
                onPressed: () {
                  if (state is AccountLoaded && state.isStreaming) {
                    // B4 fix: ferma correttamente lo stream
                    context.read<AccountBloc>().add(
                      const WatchAccountInfo(isStreaming: false),
                    );
                  } else {
                    context.read<AccountBloc>().add(
                      const WatchAccountInfo(isStreaming: true),
                    );
                  }
                },
                tooltip:
                    state is AccountLoaded && state.isStreaming
                        ? 'Ferma aggiornamenti'
                        : 'Avvia aggiornamenti',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AccountBloc>().add(const RefreshAccountInfo());
            },
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state is AccountInitial || state is AccountLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AccountError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Errore Account',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AccountBloc>().add(
                          const RefreshAccountInfo(),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Riprova'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is AccountLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Account Overview Section
                  AccountOverviewCard(),
                  SizedBox(height: 16),
                  // Filters Section
                  AccountFilters(),
                  SizedBox(height: 16),
                  // Balances List Section (wrappata internamente con altezza max)
                  BalancesList(),
                ],
              ),
            );
          }

          return const Center(child: Text('Stato sconosciuto'));
        },
      ),
    );
  }
}
