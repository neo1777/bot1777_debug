import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_event.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_state.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/widgets/orders_overview_card.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/widgets/orders_filters.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/widgets/orders_list.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/main_shell.dart';

class OrdersPage extends StatelessWidget {
  final String symbol;
  const OrdersPage({required this.symbol, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              sl<OrdersBloc>()
                ..add(LoadOpenOrders(symbol))
                ..add(LoadSymbolLimits(symbol)),
      child: const OrdersView(),
    );
  }
}

class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

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
          builder: (context, settingsState) {
            final isTest = settingsState.settings?.isTestMode ?? false;
            return Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ORDINI APERTI',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
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
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          BlocBuilder<OrdersBloc, OrdersState>(
            builder: (context, state) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Azioni',
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 8),
                            Text('Aggiorna'),
                          ],
                        ),
                      ),

                      if (state is OrdersLoaded &&
                          state.filteredOrders.isNotEmpty)
                        const PopupMenuItem(
                          value: 'cancel_all',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Cancella Tutti'),
                            ],
                          ),
                        ),
                    ],
                onSelected: (value) => _handleMenuAction(context, value),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersInitial || state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OrdersError) {
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
                      'Errore Ordini',
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
                        context.read<OrdersBloc>().add(const RefreshOrders());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Riprova'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is OrdersLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Orders Overview Section
                  OrdersOverviewCard(),
                  SizedBox(height: 16),
                  // Filters Section
                  OrdersFilters(),
                  SizedBox(height: 16),
                  // Orders List Section
                  OrdersList(),
                ],
              ),
            );
          }

          return const Center(child: Text('Stato sconosciuto'));
        },
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'refresh':
        context.read<OrdersBloc>().add(const RefreshOrders());
        break;

      case 'cancel_all':
        _showCancelAllDialog(context);
        break;
    }
  }

  void _showCancelAllDialog(BuildContext context) {
    final state = context.read<OrdersBloc>().state;
    if (state is! OrdersLoaded || state.filteredOrders.isEmpty) return;

    // Recupera il simbolo dal primo ordine (tutti condividono lo stesso simbolo)
    final symbol = state.filteredOrders.first.symbol;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Cancella Tutti gli Ordini'),
            content: Text(
              'Sei sicuro di voler cancellare tutti i ${state.filteredOrders.length} '
              'ordini aperti per $symbol?\n\n'
              'Questa azione non può essere annullata.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<OrdersBloc>().add(
                    CancelAllOrders(symbol: symbol),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text(
                  'Cancella Tutti',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
