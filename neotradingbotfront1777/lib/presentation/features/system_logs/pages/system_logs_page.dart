import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/system_log.dart';
import 'package:neotradingbotfront1777/presentation/blocs/system_log/system_log_bloc.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/main_shell.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/gradient_icon_container.dart';
import 'package:intl/intl.dart';

class SystemLogsPage extends StatefulWidget {
  const SystemLogsPage({super.key});

  @override
  State<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends State<SystemLogsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Garantisce la sottoscrizione allo stream anche se la ShellRoute non ha ancora inizializzato il bloc
    context.read<SystemLogBloc>().add(const SystemLogSubscriptionRequested());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyQuery(String value) {
    context.read<SystemLogBloc>().add(SystemLogFilterChanged(query: value));
  }

  void _toggleLevel(LogLevel level, bool enabled, SystemLogState state) {
    final newLevels = Set<LogLevel>.from(state.activeLevels);
    if (enabled) {
      newLevels.add(level);
    } else {
      newLevels.remove(level);
    }
    context.read<SystemLogBloc>().add(
      SystemLogFilterChanged(levels: newLevels),
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 100) {
      context.read<SystemLogBloc>().add(const SystemLogLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // P12 fix: AppBar per navigazione mobile
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
            const GradientIconContainer(icon: Icons.terminal),
            const SizedBox(width: 12),
            Text(
              'LOG DI SISTEMA',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // P13 fix: Wrap per evitare overflow su schermi stretti
            BlocBuilder<SystemLogBloc, SystemLogState>(
              builder: (context, state) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('INFO'),
                      selected: state.activeLevels.contains(LogLevel.info),
                      onSelected: (v) => _toggleLevel(LogLevel.info, v, state),
                    ),
                    FilterChip(
                      label: const Text('WARN'),
                      selected: state.activeLevels.contains(LogLevel.warning),
                      onSelected:
                          (v) => _toggleLevel(LogLevel.warning, v, state),
                    ),
                    FilterChip(
                      label: const Text('ERROR'),
                      selected: state.activeLevels.contains(LogLevel.error),
                      onSelected: (v) => _toggleLevel(LogLevel.error, v, state),
                    ),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Cerca...',
                          isDense: true,
                        ),
                        onChanged: _applyQuery,
                      ),
                    ),
                    const Tooltip(
                      message: 'Scorri automaticamente ai log più recenti',
                      child: Icon(
                        Icons.auto_awesome_motion,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Auto‑scroll',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Tooltip(
                      message:
                          'Attiva/Disattiva lo scorrimento automatico ai log più recenti',
                      child: Switch(
                        value: state.autoScroll,
                        activeThumbColor: AppTheme.primaryColor,
                        onChanged:
                            (v) => context.read<SystemLogBloc>().add(
                              SystemLogToggleAutoScroll(v),
                            ),
                      ),
                    ),
                    Tooltip(
                      message: 'Svuota tutti i log',
                      child: IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded),
                        color: AppTheme.errorColor,
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: AppTheme.cardColor,
                                  title: const Row(
                                    children: [
                                      GradientIconContainer(
                                        icon: Icons.delete_sweep_rounded,
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.errorColor,
                                            Color(0xFFFF5252),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Svuota Log'),
                                    ],
                                  ),
                                  content: const Text(
                                    'Sei sicuro di voler cancellare tutti i log di sistema? Questa azione non può essere annullata.',
                                    style: TextStyle(
                                      color: AppTheme.mutedTextColor,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: const Text(
                                        'ANNULLA',
                                        style: TextStyle(
                                          color: AppTheme.mutedTextColor,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.errorColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('S VUOTA'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirmed == true && context.mounted) {
                            context.read<SystemLogBloc>().add(
                              const SystemLogClearRequested(),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: AppTheme.cardDecoration,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BlocConsumer<SystemLogBloc, SystemLogState>(
                    listenWhen:
                        (p, c) =>
                            p.logs != c.logs || p.autoScroll != c.autoScroll,
                    listener: (context, state) {
                      if (state.autoScroll && _scrollController.hasClients) {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    buildWhen:
                        (p, c) =>
                            p.logs != c.logs ||
                            p.status != c.status ||
                            p.query != c.query ||
                            p.activeLevels != c.activeLevels ||
                            p.visibleCount != c.visibleCount,
                    builder: (context, state) {
                      if (state.status == SystemLogStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.status == SystemLogStatus.failure) {
                        return Center(
                          child: Text(
                            state.errorMessage ?? 'Errore nello stream dei log',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.errorColor),
                          ),
                        );
                      }
                      final filtered =
                          state.logs
                              .where((log) {
                                final levelOk = state.activeLevels.contains(
                                  log.level,
                                );
                                if (!levelOk) return false;
                                final q = state.query.trim().toLowerCase();
                                if (q.isEmpty) return true;
                                final text =
                                    '${log.serviceName ?? ''} ${log.message}'
                                        .toLowerCase();
                                return text.contains(q);
                              })
                              .take(state.visibleCount)
                              .toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('Nessun log corrispondente ai filtri.'),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: filtered.length + 1,
                        itemBuilder: (context, index) {
                          if (index == filtered.length) {
                            // P14 fix: mostra loader solo se ci sono più log da caricare
                            final totalFiltered =
                                state.logs.where((log) {
                                  final levelOk = state.activeLevels.contains(
                                    log.level,
                                  );
                                  if (!levelOk) return false;
                                  final q = state.query.trim().toLowerCase();
                                  if (q.isEmpty) return true;
                                  final text =
                                      '${log.serviceName ?? ''} ${log.message}'
                                          .toLowerCase();
                                  return text.contains(q);
                                }).length;
                            if (state.visibleCount >= totalFiltered) {
                              return const SizedBox.shrink();
                            }
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          final log = filtered[index];
                          final Color color;
                          switch (log.level) {
                            case LogLevel.info:
                              color = AppTheme.textColor;
                              break;
                            case LogLevel.warning:
                              color = Colors.orangeAccent;
                              break;
                            case LogLevel.error:
                              color = AppTheme.errorColor;
                              break;
                            default:
                              color = Colors.grey;
                          }
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 10.0,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withAlpha(80),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('HH:mm:ss').format(log.timestamp),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textColor.withAlpha(180),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '[${log.level.name.toUpperCase()}]${log.serviceName != null ? ' (${log.serviceName})' : ''}',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  log.message,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
