import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/settings_form.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/main_shell.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsView();
  }
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  static final generalKey = GlobalKey();
  static final targetsKey = GlobalKey();
  static final dcaKey = GlobalKey();
  static final budgetKey = GlobalKey();
  static final cooldownKey = GlobalKey();
  static final warmupKey = GlobalKey();

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<SettingsFormState>();

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
          builder: (context, state) {
            final isTest = state.settings?.isTestMode ?? false;
            return Row(
              children: [
                const Text('Impostazioni Strategia'),
                if (isTest) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(50),
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TESTNET',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Vai alla sezione',
            icon: const Icon(Icons.segment),
            onSelected: (value) {
              final map = {
                'Generale': SettingsView.generalKey,
                'Obiettivi & Rischio': SettingsView.targetsKey,
                'DCA': SettingsView.dcaKey,
                'Budget & Limiti': SettingsView.budgetKey,
                'Cooldown & Retry': SettingsView.cooldownKey,
                'Avvio & Warm‑up': SettingsView.warmupKey,
              };
              final key = map[value];
              if (key != null) {
                final ctx = key.currentContext;
                if (ctx != null) {
                  Scrollable.ensureVisible(
                    ctx,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: 0.1,
                  );
                }
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(value: 'Generale', child: const Text('Generale')),
                PopupMenuItem(
                  value: 'Obiettivi & Rischio',
                  child: const Text('Obiettivi & Rischio'),
                ),
                PopupMenuItem(value: 'DCA', child: const Text('DCA')),
                PopupMenuItem(
                  value: 'Budget & Limiti',
                  child: const Text('Budget & Limiti'),
                ),
                PopupMenuItem(
                  value: 'Cooldown & Retry',
                  child: const Text('Cooldown & Retry'),
                ),
                PopupMenuItem(
                  value: 'Avvio & Warm‑up',
                  child: const Text('Avvio & Warm‑up'),
                ),
              ];
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              if (state.warnings.isEmpty) {
                return const SizedBox.shrink();
              }
              final text = 'Ultimi warnings:  ${state.warnings.join('  •  ')}';
              return Container(
                width: double.infinity,
                color: Colors.amber,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        // Il listener gestisce "effetti collaterali" come le SnackBar,
        // senza ricostruire la UI.
        listener: (context, state) {
          if (state.status == SettingsStatus.saved) {
            final raw = state.infoMessage ?? '';
            // Se ci sono warnings, mostriamoli in modo leggibile
            final warnings =
                raw
                    .split(';')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
            final isWarning = warnings.isNotEmpty;
            final message =
                isWarning
                    ? 'Attenzione:\n- ${warnings.join('\n- ')}'
                    : (raw.isNotEmpty
                        ? raw
                        : 'Impostazioni salvate con successo!');
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor:
                      isWarning ? Colors.amber : AppTheme.accentColor,
                ),
              );
          } else if (state.status == SettingsStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Errore: ${state.failureMessage}'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
          }
        },
        // Il builder si occupa di costruire la UI in base allo stato corrente.
        builder: (context, state) {
          // P10 fix: rimosso addPostFrameCallback duplicato per warnings SnackBar.
          // I warnings sono già gestiti nel listener (stato saved)
          // e nel banner persistente nell'AppBar bottom.
          if (state.status == SettingsStatus.loading ||
              state.status == SettingsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.settings == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Impossibile caricare le impostazioni.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () =>
                            context.read<SettingsBloc>().add(SettingsFetched()),
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            );
          }
          // Se i dati sono stati caricati, mostriamo il form.
          return SettingsForm(
            key: _formKey,
            initialSettings: state.settings!,
            sectionKeys: SettingsSectionKeys(
              generalKey: SettingsView.generalKey,
              targetsKey: SettingsView.targetsKey,
              dcaKey: SettingsView.dcaKey,
              budgetKey: SettingsView.budgetKey,
              cooldownKey: SettingsView.cooldownKey,
              warmupKey: SettingsView.warmupKey,
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'save_settings',
            tooltip: 'Salva Impostazioni',
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.white,
            onPressed: () => _formKey.currentState?.save(),
            child: const Icon(Icons.save),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.small(
            heroTag: 'scroll_top',
            tooltip: 'Torna su',
            onPressed: () {
              final controller = PrimaryScrollController.of(context);
              controller.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            child: const Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }
}
