import 'package:flutter/material.dart';
import 'dart:async' show unawaited;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/presentation/blocs/strategy_control/strategy_control_bloc.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_bloc_real.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_event.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_event.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/bloc/strategy_state_bloc.dart';
import 'package:neotradingbotfront1777/core/config/run_control_prefs.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';

class TradingControlPanel extends StatefulWidget {
  const TradingControlPanel({
    required this.currentSymbol,
    required this.onSymbolChanged,
    super.key,
    this.strategyState,
  });

  final String currentSymbol;
  final Function(String) onSymbolChanged;
  final StrategyState? strategyState;

  @override
  State<TradingControlPanel> createState() => _TradingControlPanelState();
}

class _TradingControlPanelState extends State<TradingControlPanel> {
  bool _showWarnings = true;

  /// Fallback symbols used if gRPC call fails
  static const List<String> _fallbackSymbols = [
    'BTCUSDC',
    'ETHUSDC',
    'BNBUSDC',
    'ADAUSDC',
    'SOLUSDC',
    'XRPUSDC',
    'DOGEUSDC',
    'DOTUSDC',
  ];

  /// Dynamic list loaded from backend
  List<String> _availableSymbols = List.from(_fallbackSymbols);

  late String _selectedSymbol;

  /// Cached run-control preferences (fix P9: avoid nested FutureBuilder)
  bool _stopAfterNextSell = false;

  /// Tracks which operation is currently active (fix P8)
  _ActiveOp _activeOp = _ActiveOp.none;

  @override
  void initState() {
    super.initState();
    _selectedSymbol = widget.currentSymbol;
    _loadSymbols();
    _loadRunControlPrefs();
  }

  /// Loads run-control preferences from SharedPreferences into local state.
  Future<void> _loadRunControlPrefs() async {
    final stopVal = await RunControlPrefs.getStopAfterNextSell(_selectedSymbol);
    if (mounted) {
      setState(() {
        _stopAfterNextSell = stopVal;
      });
    }
  }

  /// Fetches available USDC symbols from the gRPC backend.
  /// Falls back to [_fallbackSymbols] on error.
  Future<void> _loadSymbols() async {
    try {
      final datasource = sl<ITradingRemoteDatasource>();
      final result = await datasource.getAvailableSymbols();
      final symbols = result.fold(
        (_) => <String>[],
        (response) => response.symbols.toList(),
      );

      if (symbols.isNotEmpty && mounted) {
        setState(() {
          _availableSymbols = symbols;
          if (!_availableSymbols.contains(_selectedSymbol)) {
            _availableSymbols.insert(0, _selectedSymbol);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableSymbols = List.from(_fallbackSymbols);
          if (!_availableSymbols.contains(_selectedSymbol)) {
            _availableSymbols.insert(0, _selectedSymbol);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StrategyControlBloc, StrategyControlState>(
      listenWhen:
          (previous, current) =>
              previous.status != current.status &&
              current.status == OperationStatus.failure,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Errore: ${state.errorMessage}')),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.cardDecoration,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              primary: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildSymbolSelection(),
                  const SizedBox(height: 8),
                  _buildControlButtons(),
                  const SizedBox(height: 6),
                  _buildStrategyStatus(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentColor,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'CONTROLLO STRATEGIA',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        BlocBuilder<StrategyControlBloc, StrategyControlState>(
          builder: (context, state) {
            final isLoading = state.status == OperationStatus.inProgress;
            return Tooltip(
              message: 'Invia report Telegram',
              child: IconButton(
                icon:
                    isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        )
                        : const Icon(
                          Icons.summarize_outlined,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                onPressed:
                    isLoading
                        ? null
                        : () {
                          context.read<StrategyControlBloc>().add(
                            const StatusReportRequested(),
                          );
                        },
                splashRadius: 18,
              ),
            );
          },
        ),
        Tooltip(
          message: _showWarnings ? 'Nascondi avvisi' : 'Mostra avvisi',
          child: IconButton(
            icon: Icon(
              _showWarnings ? Icons.visibility : Icons.visibility_off,
              color: AppTheme.mutedTextColor,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showWarnings = !_showWarnings;
              });
            },
            splashRadius: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildSymbolSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Simbolo Trading',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryColor.withAlpha(80)),
          ),
          child: DropdownButton<String>(
            value: _selectedSymbol,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppTheme.cardColor,
            style: Theme.of(context).textTheme.bodyLarge,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.primaryColor,
            ),
            items:
                _availableSymbols.map((symbol) {
                  return DropdownMenuItem<String>(
                    value: symbol,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                symbol == _selectedSymbol
                                    ? AppTheme.primaryColor
                                    : AppTheme.mutedTextColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          symbol,
                          style: TextStyle(
                            color:
                                symbol == _selectedSymbol
                                    ? AppTheme.primaryColor
                                    : AppTheme.textColor,
                            fontWeight:
                                symbol == _selectedSymbol
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            onChanged: (String? newValue) async {
              if (newValue != null && newValue != _selectedSymbol) {
                // U8: Confirm symbol change if running
                if (widget.strategyState?.status == StrategyStatus.running) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: AppTheme.cardColor,
                          title: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Cambio Simbolo'),
                            ],
                          ),
                          content: Text(
                            'La strategia è attualmente in esecuzione su $_selectedSymbol.\n\n'
                            'Vuoi davvero cambiare visualizzazione? Questo non fermerà la strategia.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.mutedTextColor),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'ANNULLA',
                                style: TextStyle(
                                  color: AppTheme.mutedTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'CAMBIA',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                  );
                  if (confirmed != true) return;
                }

                setState(() {
                  _selectedSymbol = newValue;
                });
                // Persisti simbolo e notifica bloc interessati
                unawaited(sl<SymbolContext>().setActiveSymbol(newValue));
                widget.onSymbolChanged(newValue);
                context.read<PriceBlocReal>().add(
                  SubscribeToPriceUpdates(newValue),
                );
                context.read<TradeHistoryBloc>().add(
                  FilterTradesBySymbol(newValue),
                );
                context.read<StrategyStateBloc>().add(SymbolChanged(newValue));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return BlocBuilder<StrategyControlBloc, StrategyControlState>(
      builder: (context, controlState) {
        final isRunning =
            widget.strategyState?.status == StrategyStatus.running;
        final isPaused = widget.strategyState?.status == StrategyStatus.paused;
        final isIdle =
            widget.strategyState?.status == StrategyStatus.idle ||
            widget.strategyState == null;
        final isOperationInProgress = controlState.isOperationInProgress;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controlli',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final useWrap = constraints.maxWidth < 320;
                if (useWrap) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: _buildControlButton(
                          label: isIdle ? 'AVVIA' : 'RIAVVIA',
                          icon: Icons.play_arrow,
                          color: AppTheme.successColor,
                          enabled:
                              !isOperationInProgress && (isIdle || isPaused),
                          isLoading:
                              controlState.status ==
                                  OperationStatus.inProgress &&
                              _activeOp == _ActiveOp.start,
                          onPressed: () => _handleStartStrategy(),
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: _buildControlButton(
                          label: isPaused ? 'RIPRENDI' : 'PAUSA',
                          icon: isPaused ? Icons.play_arrow : Icons.pause,
                          color: AppTheme.warningColor,
                          enabled:
                              !isOperationInProgress && (isRunning || isPaused),
                          isLoading:
                              controlState.status ==
                                  OperationStatus.inProgress &&
                              _activeOp == _ActiveOp.pause,
                          onPressed: () => _handlePauseResumeToggle(isPaused),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _buildControlButton(
                          label: 'STOP',
                          icon: Icons.stop,
                          color: AppTheme.errorColor,
                          enabled:
                              !isOperationInProgress && (isRunning || isPaused),
                          isLoading:
                              controlState.status ==
                                  OperationStatus.inProgress &&
                              _activeOp == _ActiveOp.stop,
                          onPressed: () => _handleStopStrategy(),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildControlButton(
                        label: isIdle ? 'AVVIA' : 'RIAVVIA',
                        icon: Icons.play_arrow,
                        color: AppTheme.successColor,
                        enabled: !isOperationInProgress && (isIdle || isPaused),
                        isLoading:
                            controlState.status == OperationStatus.inProgress &&
                            _activeOp == _ActiveOp.start,
                        onPressed: () => _handleStartStrategy(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildControlButton(
                        label: isPaused ? 'RIPRENDI' : 'PAUSA',
                        icon: isPaused ? Icons.play_arrow : Icons.pause,
                        color: AppTheme.warningColor,
                        enabled:
                            !isOperationInProgress && (isRunning || isPaused),
                        isLoading:
                            controlState.status == OperationStatus.inProgress &&
                            _activeOp == _ActiveOp.pause,
                        onPressed: () => _handlePauseResumeToggle(isPaused),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildControlButton(
                        label: 'STOP',
                        icon: Icons.stop,
                        color: AppTheme.errorColor,
                        enabled:
                            !isOperationInProgress && (isRunning || isPaused),
                        isLoading:
                            controlState.status == OperationStatus.inProgress &&
                            _activeOp == _ActiveOp.stop,
                        onPressed: () => _handleStopStrategy(),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _buildRunControlRow(isRunning: isRunning),
          ],
        );
      },
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && !isLoading ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                enabled
                    ? color.withAlpha(25)
                    : AppTheme.mutedTextColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? color : AppTheme.mutedTextColor,
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: color,
                  ),
                )
              else
                Icon(
                  icon,
                  color: enabled ? color : AppTheme.mutedTextColor,
                  size: 18,
                ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: enabled ? color : AppTheme.mutedTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  fontFamily: 'Roboto', // P1: Orbitron illeggibile a small size
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunControlRow({required bool isRunning}) {
    // P9: Usa valori pre-caricati in initState invece di FutureBuilder annidati
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Esecuzione',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message:
                    'Se attivo, alla prossima chiusura del round viene inviato STOP automaticamente.',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  title: const Text(
                    'Ferma alla prossima vendita',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _stopAfterNextSell,
                  onChanged: (v) async {
                    await RunControlPrefs.setStopAfterNextSell(
                      _selectedSymbol,
                      v,
                    );
                    setState(() {
                      _stopAfterNextSell = v;
                    });
                  },
                  secondary: const Icon(Icons.flag_circle_outlined, size: 16),
                  activeThumbColor: AppTheme.accentColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStrategyStatus() {
    final displayState =
        widget.strategyState ??
        StrategyState.initial(symbol: widget.currentSymbol);
    final statusText = _getStatusText(displayState.status);
    final statusColor = _getStatusColor(displayState.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withAlpha(80)),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withAlpha(128),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Stato: $statusText',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Trades: ${displayState.openTradesCount}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedTextColor),
              ),
            ],
          ),
        ),
        if (_showWarnings &&
            (displayState.warningMessage ?? '').isNotEmpty &&
            _shouldShowRawWarning(displayState.warningMessage!)) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withAlpha(18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor.withAlpha(100)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayState.warningMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusText(StrategyStatus? status) {
    switch (status) {
      case StrategyStatus.running:
        return 'ATTIVA';
      case StrategyStatus.paused:
        return 'IN PAUSA';
      case StrategyStatus.idle:
        return 'INATTIVA';
      case StrategyStatus.error:
        return 'ERRORE';
      case null:
        return 'SCONOSCIUTO';
      default:
        return 'NON SPECIFICATO';
    }
  }

  Color _getStatusColor(StrategyStatus? status) {
    switch (status) {
      case StrategyStatus.running:
        return AppTheme.successColor;
      case StrategyStatus.paused:
        return AppTheme.warningColor;
      case StrategyStatus.idle:
        return AppTheme.mutedTextColor;
      case StrategyStatus.error:
        return AppTheme.errorColor;
      default:
        return AppTheme.mutedTextColor;
    }
  }

  void _handleStartStrategy() {
    setState(() => _activeOp = _ActiveOp.start);
    context.read<StrategyControlBloc>().add(
      StartStrategyRequested(_selectedSymbol),
    );
    // Reset baseRoundId al momento dello start: sarà memorizzato quando riceveremo lo stato corrente
    RunControlPrefs.setBaseRoundId(_selectedSymbol, 0);
  }

  Future<void> _handleStopStrategy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: AppTheme.cardColor,
            title: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Conferma Interruzione'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sei sicuro di voler FERMARE la strategia?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'L\'interruzione immediata potrebbe lasciare ordini pendenti o posizioni aperte che dovranno essere gestite manualmente.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.warningColor.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.warningColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'SOGGERIMENTO: Usa "Ferma alla prossima vendita" per una chiusura pulita.',
                          style: TextStyle(
                            color: AppTheme.warningColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'ANNULLA',
                  style: TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'FERMA ORA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      context.read<StrategyControlBloc>().add(
        StopStrategyRequested(_selectedSymbol),
      );
    }
  }

  void _handlePauseResumeToggle(bool isPaused) {
    if (isPaused) {
      _handleResumeStrategy();
    } else {
      _handlePauseStrategy();
    }
  }

  void _handlePauseStrategy() {
    setState(() => _activeOp = _ActiveOp.pause);
    context.read<StrategyControlBloc>().add(
      PauseStrategyRequested(_selectedSymbol),
    );
  }

  void _handleResumeStrategy() {
    setState(() => _activeOp = _ActiveOp.pause);
    context.read<StrategyControlBloc>().add(
      ResumeStrategyRequested(_selectedSymbol),
    );
  }

  bool _shouldShowRawWarning(String msg) {
    if (msg.isEmpty) return false;
    final lower = msg.toLowerCase();
    // Nascondi errori gRPC e stringhe tecniche (U2)
    if (lower.contains('grpc error') ||
        lower.contains('status(') ||
        lower.contains('auto_stop_in_cycles') ||
        lower.contains('exception') ||
        lower.contains('serverfailure') ||
        lower.contains('connection closed') ||
        lower.contains('failed to connect') ||
        lower.contains('channel is in state')) {
      return false;
    }
    return true;
  }
}

/// Enum to track which operation button triggered the loading state (P8 fix).
enum _ActiveOp { none, start, pause, stop }
