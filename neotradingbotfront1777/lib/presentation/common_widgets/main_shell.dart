import 'package:flutter/material.dart';
import 'dart:async';
import 'package:neotradingbotfront1777/core/api/grpc_client.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/generated/proto/grpc/health/v1/health.pbgrpc.dart'
    as health;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/snackbar_helper.dart';
import 'package:neotradingbotfront1777/presentation/blocs/system_log/system_log_bloc.dart';
import 'package:neotradingbotfront1777/domain/entities/system_log.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/bloc/strategy_state_bloc.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';

class MainShell extends StatelessWidget {
  static final GlobalKey<ScaffoldState> mobileScaffoldKey =
      GlobalKey<ScaffoldState>();

  final Widget child;
  const MainShell({required this.child, super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/testnet')) return 1;
    if (location.startsWith('/account')) return 2;
    if (location.startsWith('/orders')) return 3;
    if (location.startsWith('/history')) return 4;
    if (location.startsWith('/logs')) return 5;
    if (location.startsWith('/settings')) return 6;
    if (location.startsWith('/log-settings')) return 7;
    if (location.startsWith('/diagnostics')) return 8;
    if (location.startsWith('/backtest')) return 9;
    return 0;
  }

  Future<void> _onDestinationSelected(int index, BuildContext context) async {
    // B5: Guard per cambiamenti non salvati in Settings
    final settingsState = context.read<SettingsBloc>().state;
    final isCurrentlyOnSettings = _calculateSelectedIndex(context) == 6;

    if (isCurrentlyOnSettings && settingsState.isDirty) {
      final shouldLeave = await _showUnsavedChangesDialog(context);
      if (shouldLeave != true) return;
      // Reset dirty state if user explicitly chooses to leave
      if (context.mounted) {
        context.read<SettingsBloc>().add(const SettingsDirtyChanged(false));
      }
    }

    if (!context.mounted) return;

    final strategyState = context.read<StrategyStateBloc>().state;
    final activeSymbol =
        strategyState.currentSymbol.isNotEmpty
            ? strategyState.currentSymbol
            : sl<SymbolContext>().activeSymbol;

    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/testnet');
        break;
      case 2:
        context.go('/account');
        break;
      case 3:
        context.go('/orders/$activeSymbol');
        break;
      case 4:
        context.go('/history');
        break;
      case 5:
        context.go('/logs');
        break;
      case 6:
        context.go('/settings');
        break;

      case 7:
        context.go('/log-settings');
        break;
      case 8:
        context.go('/diagnostics/tls');
        break;
      case 9:
        context.go('/backtest');
        break;
    }
  }

  Future<bool?> _showUnsavedChangesDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifiche non salvate'),
            content: const Text(
              'Hai delle modifiche non salvate nelle impostazioni. \n'
              'Vuoi uscire perdendo le modifiche?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ANNULLA'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('ESCI'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isTestnet = settingsState.settings?.isTestMode ?? false;
        final content = LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 768) {
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _calculateSelectedIndex(context),
                      onDestinationSelected:
                          (index) => _onDestinationSelected(index, context),
                      labelType: NavigationRailLabelType.all,
                      leading: const _ServerHealthBadge(),
                      minExtendedWidth: 80,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.science_outlined),
                          selectedIcon: Icon(Icons.science),
                          label: Text('Testnet'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.account_balance_wallet_outlined),
                          selectedIcon: Icon(Icons.account_balance_wallet),
                          label: Text('Account'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.list_alt_outlined),
                          selectedIcon: Icon(Icons.list_alt),
                          label: Text('Ordini'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.history_outlined),
                          selectedIcon: Icon(Icons.history),
                          label: Text('Storico'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.terminal_outlined),
                          selectedIcon: Icon(Icons.terminal),
                          label: Text('Log'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: Text('Impostazioni'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.tune_outlined),
                          selectedIcon: Icon(Icons.tune),
                          label: Text('Log Settings'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.shield_outlined),
                          selectedIcon: Icon(Icons.shield),
                          label: Text('Diagnostica'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.history_edu_outlined),
                          selectedIcon: Icon(Icons.history_edu),
                          label: Text('Backtest'),
                        ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                      child: BlocListener<SystemLogBloc, SystemLogState>(
                        listenWhen: (prev, curr) => prev.logs != curr.logs,
                        listener: (context, state) {
                          if (state.logs.isNotEmpty) {
                            final last = state.logs.first;
                            // Dust SELL
                            if (last.level == LogLevel.error &&
                                last.message.contains('DUST SELL')) {
                              AppSnackBar.showWarning(
                                context,
                                'Vendita non eseguibile per dust. Nuovo tentativo programmato a breve.',
                              );
                            }
                            // BUY overage applicato
                            if (last.level == LogLevel.warning &&
                                last.message.contains('BUY_OVERAGE_APPLIED')) {
                              AppSnackBar.showWarning(
                                context,
                                'Attenzione: applicato overage al budget per soddisfare i limiti exchange.',
                              );
                            }
                            // Recovering (no active isolate)
                            if (last.level == LogLevel.warning &&
                                last.message.contains('RECOVERING')) {
                              AppSnackBar.showWarning(
                                context,
                                'Stato: RECOVERING. Nessun isolate attivo, ripristino in corso...',
                              );
                            }
                            // Clamp settings
                            if (last.level == LogLevel.warning &&
                                last.message.contains('SETTINGS_CLAMP')) {
                              AppSnackBar.showWarning(
                                context,
                                'Alcune impostazioni sono state clamped dal server per sicurezza.',
                              );
                            }
                          }
                        },
                        child: child,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Scaffold(
                key: mobileScaffoldKey,
                // AppBar removed to avoid duplication with child pages (Fix P3)
                drawer: Drawer(
                  child: Column(
                    children: [
                      const DrawerHeader(
                        decoration: BoxDecoration(color: AppTheme.surfaceColor),
                        child: Center(child: Icon(Icons.shield_moon, size: 60)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.dashboard_outlined),
                        title: const Text('Dashboard'),
                        selected: _calculateSelectedIndex(context) == 0,
                        onTap: () async {
                          await _onDestinationSelected(0, context);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.science_outlined),
                        title: const Text('Testnet'),
                        selected: _calculateSelectedIndex(context) == 1,
                        onTap: () async {
                          await _onDestinationSelected(1, context);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                        title: const Text('Account'),
                        selected: _calculateSelectedIndex(context) == 2,
                        onTap: () async {
                          await _onDestinationSelected(2, context);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.list_alt_outlined),
                        title: const Text('Ordini'),
                        selected: _calculateSelectedIndex(context) == 3,
                        onTap: () async {
                          await _onDestinationSelected(3, context);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.history_outlined),
                        title: const Text('Storico'),
                        selected: _calculateSelectedIndex(context) == 4,
                        onTap: () async {
                          await _onDestinationSelected(4, context);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.terminal_outlined),
                        title: const Text('Log'),
                        selected: _calculateSelectedIndex(context) == 5,
                        onTap: () async {
                          await _onDestinationSelected(5, context);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.tune_outlined),
                        title: const Text('Log Settings'),
                        selected: _calculateSelectedIndex(context) == 7,
                        onTap: () async {
                          await _onDestinationSelected(7, context);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Impostazioni'),
                        selected: _calculateSelectedIndex(context) == 6,
                        onTap: () async {
                          await _onDestinationSelected(6, context);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: const Text('Diagnostica'),
                        selected: _calculateSelectedIndex(context) == 8,
                        onTap: () async {
                          await _onDestinationSelected(8, context);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                body: BlocListener<SystemLogBloc, SystemLogState>(
                  listenWhen: (prev, curr) => prev.logs != curr.logs,
                  listener: (context, state) {
                    if (state.logs.isNotEmpty) {
                      final last = state.logs.first;
                      if (last.level == LogLevel.error &&
                          last.message.contains('DUST SELL')) {
                        AppSnackBar.showWarning(
                          context,
                          'Vendita non eseguibile per dust. Nuovo tentativo programmato a breve.',
                        );
                      }
                    }
                    // Guida utente in caso di TLS pinning error
                    final conn = sl<GrpcClientManager>();
                    if (conn.currentStatus ==
                        GrpcConnectionStatus.pinningError) {
                      AppSnackBar.showError(
                        context,
                        'Errore TLS pinning: apri Diagnostica > TLS per configurare certificato o pinning.',
                      );
                    }
                  },
                  child: child,
                ),
              );
            }
          },
        );

        if (isTestnet) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Banner(
              message: 'TESTNET',
              location: BannerLocation.topEnd,
              color: AppTheme.warningColor,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
              child: content,
            ),
          );
        }
        return content;
      },
    );
  }
}

class _ServerHealthBadge extends StatefulWidget {
  const _ServerHealthBadge();

  @override
  State<_ServerHealthBadge> createState() => _ServerHealthBadgeState();
}

class _ServerHealthBadgeState extends State<_ServerHealthBadge> {
  health.HealthCheckResponse_ServingStatus _status =
      health.HealthCheckResponse_ServingStatus.SERVICE_UNKNOWN;
  Stream<health.HealthCheckResponse>? _stream;
  StreamSubscription<health.HealthCheckResponse>? _sub;
  GrpcConnectionStatus _connStatus = GrpcConnectionStatus.disconnected;
  StreamSubscription<GrpcConnectionStatus>? _connSub;

  @override
  void initState() {
    super.initState();
    final channel = sl<GrpcClientManager>();
    // Seed dello stato corrente per evitare visualizzazione "DISCONNECTED" iniziale
    _connStatus = channel.currentStatus;
    // Ascolta lo stato connessione/pinning/health sintetico
    _connSub = channel.statusStream.listen((s) {
      if (!mounted) return;
      setState(() => _connStatus = s);
    });
    // best-effort: health.watch non blocca in caso di errore, badge rimane UNKNOWN
    try {
      final healthClient = health.HealthClient(channel.channel);
      _stream = healthClient.watch(health.HealthCheckRequest());
      _sub = _stream!.listen(
        (event) {
          if (!mounted) return;
          setState(() => _status = event.status);
        },
        onError: (_) {
          if (!mounted) return;
          setState(
            () =>
                _status = health.HealthCheckResponse_ServingStatus.NOT_SERVING,
          );
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  Color _colorFor(health.HealthCheckResponse_ServingStatus s) {
    switch (s) {
      case health.HealthCheckResponse_ServingStatus.SERVING:
        return Colors.greenAccent;
      case health.HealthCheckResponse_ServingStatus.NOT_SERVING:
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  String _labelFor(health.HealthCheckResponse_ServingStatus s) {
    switch (s) {
      case health.HealthCheckResponse_ServingStatus.SERVING:
        return 'SERVING';
      case health.HealthCheckResponse_ServingStatus.NOT_SERVING:
        return 'NOT SERVING';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Priorità di visualizzazione: errori di connessione/pinning > health gRPC
    Color color;
    String label;
    switch (_connStatus) {
      case GrpcConnectionStatus.pinningError:
        color = Colors.redAccent;
        label = 'PINNING ERROR';
        break;
      case GrpcConnectionStatus.error:
        color = Colors.redAccent;
        label = 'CONNECTION ERROR';
        break;
      case GrpcConnectionStatus.disconnected:
        color = Colors.orangeAccent;
        label = 'DISCONNECTED';
        break;
      case GrpcConnectionStatus.initializing:
        color = Colors.orangeAccent;
        label = 'CONNECTING';
        break;
      case GrpcConnectionStatus.unhealthy:
        color = Colors.orangeAccent;
        label = 'UNHEALTHY';
        break;
      case GrpcConnectionStatus.connected:
        color = _colorFor(_status);
        label = _labelFor(_status);
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
