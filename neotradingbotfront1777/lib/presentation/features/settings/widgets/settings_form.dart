import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/snackbar_helper.dart';
import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';
import 'package:neotradingbotfront1777/domain/services/quantity_calculator_service.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_bloc_real.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_state.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/budget_limits_settings_section.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/cooldown_retry_settings_section.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/dca_settings_section.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/general_settings_section.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/targets_risk_settings_section.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/warmup_settings_section.dart';

class SettingsSectionKeys {
  final GlobalKey generalKey;
  final GlobalKey targetsKey;
  final GlobalKey dcaKey;
  final GlobalKey budgetKey;
  final GlobalKey cooldownKey;
  final GlobalKey warmupKey;
  const SettingsSectionKeys({
    required this.generalKey,
    required this.targetsKey,
    required this.dcaKey,
    required this.budgetKey,
    required this.cooldownKey,
    required this.warmupKey,
  });
}

class SettingsForm extends StatefulWidget {
  final AppSettings initialSettings;
  final SettingsSectionKeys? sectionKeys;
  const SettingsForm({
    required this.initialSettings,
    super.key,
    this.sectionKeys,
  });

  @override
  State<SettingsForm> createState() => SettingsFormState();
}

class SettingsFormState extends State<SettingsForm> {
  final _formKey = GlobalKey<FormState>();

  // Controller per ogni campo del form, inizializzati con i valori correnti.
  late final TextEditingController _tradeAmountController;
  late final TextEditingController _fixedQuantityController;
  late final TextEditingController _profitTargetController;
  late final TextEditingController _stopLossController;
  late final TextEditingController _dcaDecrementController;
  late final TextEditingController _maxOpenTradesController;
  late bool _isTestMode;

  // Nuovi campi avvio strategia
  late bool _buyOnStart;
  late final TextEditingController _initialWarmupTicksController;
  late final TextEditingController _initialWarmupSecondsController;
  late final TextEditingController _initialSignalThresholdPctController;
  // Nuovi controlli robustezza
  late final TextEditingController _dcaCooldownSecondsController;
  late final TextEditingController _dustRetryCooldownSecondsController;
  late final TextEditingController _maxTradeAmountCapController;
  late final TextEditingController _maxBuyOveragePctController;

  late final TextEditingController _maxCyclesController;
  late bool _strictBudget;
  late bool _buyOnStartRespectWarmup;
  late final TextEditingController _buyCooldownSecondsController;
  late bool _dcaCompareAgainstAverage;
  late bool _enableFeeAwareTrading;
  late bool _enableReBuy;

  // Variabili per il calcolo automatico della quantità fissa
  double? _currentPrice;
  String? _currentSymbol;

  @override
  void initState() {
    super.initState();
    final settings = widget.initialSettings;
    _tradeAmountController = TextEditingController(
      text: settings.tradeAmount.toString(),
    );
    _fixedQuantityController = TextEditingController(
      text: settings.fixedQuantity?.toString() ?? '',
    );
    _profitTargetController = TextEditingController(
      text: settings.profitTargetPercentage.toString(),
    );
    _stopLossController = TextEditingController(
      text: settings.stopLossPercentage.toString(),
    );
    _dcaDecrementController = TextEditingController(
      text: settings.dcaDecrementPercentage.toString(),
    );
    _maxOpenTradesController = TextEditingController(
      text: settings.maxOpenTrades.toString(),
    );
    _isTestMode = settings.isTestMode;

    _buyOnStart = settings.buyOnStart;
    _initialWarmupTicksController = TextEditingController(
      text: settings.initialWarmupTicks.toString(),
    );
    _initialWarmupSecondsController = TextEditingController(
      text: settings.initialWarmupSeconds.toString(),
    );
    _initialSignalThresholdPctController = TextEditingController(
      text: settings.initialSignalThresholdPct.toString(),
    );
    _dcaCooldownSecondsController = TextEditingController(
      text: settings.dcaCooldownSeconds.toString(),
    );
    _dustRetryCooldownSecondsController = TextEditingController(
      text: settings.dustRetryCooldownSeconds.toString(),
    );
    _maxTradeAmountCapController = TextEditingController(
      text: settings.maxTradeAmountCap.toString(),
    );
    _maxBuyOveragePctController = TextEditingController(
      text: settings.maxBuyOveragePct.toString(),
    );

    _maxCyclesController = TextEditingController(
      text: settings.maxCycles.toString(),
    );
    _strictBudget = settings.strictBudget;
    _buyOnStartRespectWarmup = settings.buyOnStartRespectWarmup;
    _buyCooldownSecondsController = TextEditingController(
      text: settings.buyCooldownSeconds.toString(),
    );
    _dcaCompareAgainstAverage = settings.dcaCompareAgainstAverage;
    _enableFeeAwareTrading = settings.enableFeeAwareTrading;
    _enableReBuy = settings.enableReBuy;

    // Inizializza il simbolo corrente
    _currentSymbol = sl<SymbolContext>().activeSymbol;

    // Aggiungi listener per monitorare lo stato "dirty" e ricalcoli
    _tradeAmountController.addListener(_onTradeAmountChanged);
    _tradeAmountController.addListener(_notifyDirtyStatus);
    _fixedQuantityController.addListener(_notifyDirtyStatus);
    _profitTargetController.addListener(_notifyDirtyStatus);
    _stopLossController.addListener(_notifyDirtyStatus);
    _dcaDecrementController.addListener(_notifyDirtyStatus);
    _maxOpenTradesController.addListener(_notifyDirtyStatus);
    _initialWarmupTicksController.addListener(_notifyDirtyStatus);
    _initialWarmupSecondsController.addListener(_notifyDirtyStatus);
    _initialSignalThresholdPctController.addListener(_notifyDirtyStatus);
    _dcaCooldownSecondsController.addListener(_notifyDirtyStatus);
    _dustRetryCooldownSecondsController.addListener(_notifyDirtyStatus);
    _maxTradeAmountCapController.addListener(_notifyDirtyStatus);
    _maxBuyOveragePctController.addListener(_notifyDirtyStatus);
    _maxCyclesController.addListener(_notifyDirtyStatus);
    _buyCooldownSecondsController.addListener(_notifyDirtyStatus);
  }

  void _notifyDirtyStatus() {
    if (mounted) {
      final currentDirty = _isDirty;
      context.read<SettingsBloc>().add(SettingsDirtyChanged(currentDirty));
    }
  }

  @override
  void dispose() {
    _fixedQuantityController.removeListener(_notifyDirtyStatus);
    _tradeAmountController.removeListener(_notifyDirtyStatus);
    _tradeAmountController.removeListener(_onTradeAmountChanged);
    _profitTargetController.removeListener(_notifyDirtyStatus);
    _stopLossController.removeListener(_notifyDirtyStatus);
    _dcaDecrementController.removeListener(_notifyDirtyStatus);
    _maxOpenTradesController.removeListener(_notifyDirtyStatus);
    _initialWarmupTicksController.removeListener(_notifyDirtyStatus);
    _initialWarmupSecondsController.removeListener(_notifyDirtyStatus);
    _initialSignalThresholdPctController.removeListener(_notifyDirtyStatus);
    _dcaCooldownSecondsController.removeListener(_notifyDirtyStatus);
    _dustRetryCooldownSecondsController.removeListener(_notifyDirtyStatus);
    _maxTradeAmountCapController.removeListener(_notifyDirtyStatus);
    _maxBuyOveragePctController.removeListener(_notifyDirtyStatus);
    _maxCyclesController.removeListener(_notifyDirtyStatus);
    _buyCooldownSecondsController.removeListener(_notifyDirtyStatus);

    _tradeAmountController.dispose();
    _fixedQuantityController.dispose();
    _profitTargetController.dispose();
    _stopLossController.dispose();
    _dcaDecrementController.dispose();
    _maxOpenTradesController.dispose();
    _initialWarmupTicksController.dispose();
    _initialWarmupSecondsController.dispose();
    _initialSignalThresholdPctController.dispose();
    _dcaCooldownSecondsController.dispose();
    _dustRetryCooldownSecondsController.dispose();
    _maxTradeAmountCapController.dispose();
    _maxBuyOveragePctController.dispose();
    _buyCooldownSecondsController.dispose();
    _maxCyclesController.dispose();

    super.dispose();
  }

  /// Gestisce il cambio dell'importo per il trade e calcola automaticamente la quantità fissa
  void _onTradeAmountChanged() {
    if (_currentSymbol == null) return;

    final tradeAmount = double.tryParse(_tradeAmountController.text);
    if (tradeAmount == null || tradeAmount <= 0) return;

    // Se abbiamo un prezzo corrente, calcola la quantità fissa
    if (_currentPrice != null && _currentPrice! > 0) {
      final fixedQuantity = QuantityCalculatorService.calculateForSymbol(
        symbol: _currentSymbol!,
        tradeAmount: tradeAmount,
        currentPrice: _currentPrice!,
      );

      // Aggiorna il campo quantità fissa solo se è vuoto o se l'utente non l'ha modificato manualmente
      if (_fixedQuantityController.text.isEmpty) {
        _fixedQuantityController
            .text = QuantityCalculatorService.formatQuantity(fixedQuantity);
      }
    }
  }

  /// Calcola e imposta la quantità fissa in base al prezzo corrente
  void _calculateFixedQuantity() {
    if (_currentSymbol == null ||
        _currentPrice == null ||
        _currentPrice! <= 0) {
      return;
    }

    final tradeAmount = double.tryParse(_tradeAmountController.text);
    if (tradeAmount == null || tradeAmount <= 0) {
      AppSnackBar.showWarning(
        context,
        'Inserisci prima un importo valido per il trade',
      );
      return;
    }

    final fixedQuantity = QuantityCalculatorService.calculateForSymbol(
      symbol: _currentSymbol!,
      tradeAmount: tradeAmount,
      currentPrice: _currentPrice!,
    );

    _fixedQuantityController.text = QuantityCalculatorService.formatQuantity(
      fixedQuantity,
    );

    // Mostra un messaggio di conferma
    final equivalentAmount =
        QuantityCalculatorService.calculateEquivalentAmount(
          fixedQuantity: fixedQuantity,
          currentPrice: _currentPrice!,
        );

    AppSnackBar.showInfo(
      context,
      'Quantità calcolata: ${QuantityCalculatorService.formatQuantity(fixedQuantity)} $_currentSymbol '
      '(≈\$${equivalentAmount.toStringAsFixed(2)})',
    );
  }

  void _onSave() {
    // Nasconde la tastiera e valida il form.
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      // Validazione di coerenza: se buyOnStart=false, almeno uno tra warmup/threshold deve essere > 0
      final warmupTicks = int.tryParse(_initialWarmupTicksController.text) ?? 0;
      final warmupSeconds =
          double.tryParse(_initialWarmupSecondsController.text) ?? 0.0;
      final signalThreshold =
          double.tryParse(_initialSignalThresholdPctController.text) ?? 0.0;
      if (!_buyOnStart &&
          warmupTicks == 0 &&
          warmupSeconds == 0.0 &&
          signalThreshold == 0.0) {
        AppSnackBar.showWarning(
          context,
          'Per buyOnStart disattivato è richiesto almeno uno tra: warm‑up tick, warm‑up secondi o soglia segnale > 0.',
        );
        return;
      }
      // Crea la nuova entità AppSettings dai valori del form.
      final updatedSettings = AppSettings(
        tradeAmount: double.parse(_tradeAmountController.text),
        fixedQuantity:
            _fixedQuantityController.text.isEmpty
                ? null
                : double.tryParse(_fixedQuantityController.text),
        profitTargetPercentage: double.parse(_profitTargetController.text),
        stopLossPercentage: double.parse(_stopLossController.text),
        dcaDecrementPercentage: double.parse(_dcaDecrementController.text),
        maxOpenTrades: int.parse(_maxOpenTradesController.text),
        isTestMode: _isTestMode,
        buyOnStart: _buyOnStart,
        initialWarmupTicks:
            int.tryParse(_initialWarmupTicksController.text) ?? 0,
        initialWarmupSeconds:
            double.tryParse(_initialWarmupSecondsController.text) ?? 0.0,
        initialSignalThresholdPct:
            double.tryParse(_initialSignalThresholdPctController.text) ?? 0.0,
        maxBuyOveragePct:
            double.tryParse(_maxBuyOveragePctController.text) ?? 0.03,
        strictBudget: _strictBudget,
        buyOnStartRespectWarmup: _buyOnStartRespectWarmup,
        buyCooldownSeconds:
            double.tryParse(_buyCooldownSecondsController.text) ?? 2.0,
        dcaCompareAgainstAverage: _dcaCompareAgainstAverage,

        dcaCooldownSeconds:
            double.tryParse(_dcaCooldownSecondsController.text) ?? 3.0,
        dustRetryCooldownSeconds:
            double.tryParse(_dustRetryCooldownSecondsController.text) ?? 15.0,
        maxTradeAmountCap:
            double.tryParse(_maxTradeAmountCapController.text) ?? 1000000.0,
        maxCycles: int.tryParse(_maxCyclesController.text) ?? 0,
        enableFeeAwareTrading: _enableFeeAwareTrading,
        enableReBuy: _enableReBuy,
      );
      // maxCycles sarà inviato al backend come parte delle Settings
      // Invia l'evento al BLoC.
      context.read<SettingsBloc>().add(SettingsUpdated(updatedSettings));
      // Reset locale immediato per la consistenza UI prima che arrivi lo stato salvato
      context.read<SettingsBloc>().add(const SettingsDirtyChanged(false));
    }
  }

  void save() => _onSave();

  bool get _isDirty {
    final s = widget.initialSettings;
    if (_tradeAmountController.text != s.tradeAmount.toString()) return true;
    if (_profitTargetController.text != s.profitTargetPercentage.toString())
      return true;
    if (_stopLossController.text != s.stopLossPercentage.toString())
      return true;
    if (_dcaDecrementController.text != s.dcaDecrementPercentage.toString())
      return true;
    if (_maxOpenTradesController.text != s.maxOpenTrades.toString())
      return true;
    if (_isTestMode != s.isTestMode) return true;
    if (_buyOnStart != s.buyOnStart) return true;
    if (_maxCyclesController.text != s.maxCycles.toString()) return true;
    if (_strictBudget != s.strictBudget) return true;

    if (_initialWarmupTicksController.text != s.initialWarmupTicks.toString())
      return true;
    if (_initialWarmupSecondsController.text !=
        s.initialWarmupSeconds.toString())
      return true;
    if (_initialSignalThresholdPctController.text !=
        s.initialSignalThresholdPct.toString())
      return true;
    if (_dcaCooldownSecondsController.text != s.dcaCooldownSeconds.toString())
      return true;
    if (_dustRetryCooldownSecondsController.text !=
        s.dustRetryCooldownSeconds.toString())
      return true;
    if (_maxTradeAmountCapController.text != s.maxTradeAmountCap.toString())
      return true;
    if (_maxBuyOveragePctController.text != s.maxBuyOveragePct.toString())
      return true;
    if (_buyCooldownSecondsController.text != s.buyCooldownSeconds.toString())
      return true;
    if (_buyOnStartRespectWarmup != s.buyOnStartRespectWarmup) return true;
    if (_dcaCompareAgainstAverage != s.dcaCompareAgainstAverage) return true;
    if (_enableFeeAwareTrading != s.enableFeeAwareTrading) return true;
    if (_enableReBuy != s.enableReBuy) return true;

    // Check optional fixed quantity
    final fqText = _fixedQuantityController.text;
    final fqInitial = s.fixedQuantity?.toString() ?? '';
    if (fqText != fqInitial) return true;

    return false;
  }

  Future<void> _handlePopScope(bool didPop) async {
    if (didPop) return;
    if (!_isDirty) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifiche non salvate'),
            content: const Text(
              'Hai delle modifiche non salvate. Vuoi uscire perdendo le modifiche?',
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

    if (shouldPop == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // We always handle manually to check dirtiness
      onPopInvokedWithResult: (didPop, _) => _handlePopScope(didPop),
      child: BlocListener<PriceBlocReal, PriceState>(
        listener: (context, state) {
          if (state is PriceLoaded &&
              state.priceData.symbol == _currentSymbol) {
            if (mounted) {
              setState(() {
                _currentPrice = state.priceData.price;
              });
            }
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            primary: true,
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1800),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = (constraints.maxWidth / 400)
                        .floor()
                        .clamp(1, 4);
                    double childAspectRatio;
                    if (crossAxisCount >= 4) {
                      childAspectRatio =
                          0.8; // più spazio verticale per card ricche
                    } else if (crossAxisCount == 3) {
                      childAspectRatio = 0.9;
                    } else {
                      childAspectRatio = 1.0;
                    }

                    // Using extracted widgets
                    final cards = <Widget>[
                      GeneralSettingsSection(
                        generalKey: widget.sectionKeys?.generalKey,
                        tradeAmountController: _tradeAmountController,
                        fixedQuantityController: _fixedQuantityController,
                        isTestMode: _isTestMode,
                        onTestModeChanged:
                            (v) => setState(() => _isTestMode = v),
                        enableFeeAwareTrading: _enableFeeAwareTrading,
                        onFeeAwareTradingChanged:
                            (v) => setState(() => _enableFeeAwareTrading = v),
                        enableReBuy: _enableReBuy,
                        onEnableReBuyChanged:
                            (v) => setState(() => _enableReBuy = v),
                        currentSymbol: _currentSymbol,
                        currentPrice: _currentPrice,
                        onCalculateFixedQuantity: _calculateFixedQuantity,
                      ),
                      TargetsRiskSettingsSection(
                        sectionKey: widget.sectionKeys?.targetsKey,
                        profitTargetController: _profitTargetController,
                        stopLossController: _stopLossController,
                        maxOpenTradesController: _maxOpenTradesController,
                      ),
                      DcaSettingsSection(
                        sectionKey: widget.sectionKeys?.dcaKey,
                        dcaDecrementController: _dcaDecrementController,
                        dcaCooldownSecondsController:
                            _dcaCooldownSecondsController,
                        dcaCompareAgainstAverage: _dcaCompareAgainstAverage,
                        onDcaCompareChanged:
                            (v) =>
                                setState(() => _dcaCompareAgainstAverage = v),
                      ),
                      BudgetLimitsSettingsSection(
                        sectionKey: widget.sectionKeys?.budgetKey,
                        maxTradeAmountCapController:
                            _maxTradeAmountCapController,
                        maxBuyOveragePctController: _maxBuyOveragePctController,
                        strictBudget: _strictBudget,
                        onStrictBudgetChanged:
                            (v) => setState(() => _strictBudget = v),
                      ),
                      CooldownRetrySettingsSection(
                        sectionKey: widget.sectionKeys?.cooldownKey,
                        buyCooldownSecondsController:
                            _buyCooldownSecondsController,
                        dustRetryCooldownSecondsController:
                            _dustRetryCooldownSecondsController,
                        maxCyclesController: _maxCyclesController,
                      ),
                      WarmupSettingsSection(
                        sectionKey: widget.sectionKeys?.warmupKey,
                        buyOnStart: _buyOnStart,
                        onBuyOnStartChanged:
                            (v) => setState(() => _buyOnStart = v),
                        buyOnStartRespectWarmup: _buyOnStartRespectWarmup,
                        onBuyOnStartRespectWarmupChanged:
                            (v) => setState(() => _buyOnStartRespectWarmup = v),
                        initialWarmupTicksController:
                            _initialWarmupTicksController,
                        initialWarmupSecondsController:
                            _initialWarmupSecondsController,
                        initialSignalThresholdPctController:
                            _initialSignalThresholdPctController,
                      ),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GridView.count(
                          padding: const EdgeInsets.all(16.0),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: cards,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: BlocBuilder<SettingsBloc, SettingsState>(
                            builder: (context, state) {
                              final isSaving =
                                  state.status == SettingsStatus.saving;
                              return ElevatedButton.icon(
                                icon:
                                    isSaving
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.save),
                                label: const Text('SALVA IMPOSTAZIONI'),
                                onPressed: isSaving ? null : _onSave,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
