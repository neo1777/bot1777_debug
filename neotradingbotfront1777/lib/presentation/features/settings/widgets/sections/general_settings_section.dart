import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/settings_section_card.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/settings_text_field.dart';

class GeneralSettingsSection extends StatelessWidget {
  final Key? generalKey;
  final TextEditingController tradeAmountController;
  final TextEditingController fixedQuantityController;
  final bool isTestMode;
  final ValueChanged<bool> onTestModeChanged;
  final bool enableFeeAwareTrading;
  final ValueChanged<bool> onFeeAwareTradingChanged;
  final bool enableReBuy;
  final ValueChanged<bool> onEnableReBuyChanged;
  final String? currentSymbol;
  final double? currentPrice;
  final VoidCallback onCalculateFixedQuantity;

  const GeneralSettingsSection({
    required this.tradeAmountController,
    required this.fixedQuantityController,
    required this.isTestMode,
    required this.onTestModeChanged,
    required this.enableFeeAwareTrading,
    required this.onFeeAwareTradingChanged,
    required this.enableReBuy,
    required this.onEnableReBuyChanged,
    required this.onCalculateFixedQuantity,
    super.key,
    this.generalKey,
    this.currentSymbol,
    this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      key: generalKey,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Generale',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Tooltip(
              message:
                  'Parametri globali: importo per trade e modalità test (ordini non reali).',
              preferBelow: false,
              child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsTextField(
          controller: tradeAmountController,
          label: 'Importo per Trade (es. 10.5)',
          icon: Icons.attach_money,
          isNumeric: true,
          tooltip:
              'Budget per singolo BUY in valuta quote. Aumentando questo valore acquisti più quantità a ogni ordine.',
          extraValidator: (v) {
            final x = double.parse(v);
            if (x <= 0) return 'Deve essere > 0';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SettingsTextField(
                controller: fixedQuantityController,
                label: 'Quantità Fissa (es. 0.0001)',
                icon: Icons.settings,
                isNumeric: true,
                tooltip:
                    'Quantità fissa da acquistare ad ogni ordine. Se specificata, sovrascrive l\'importo in dollari. Utile per evitare problemi di arrotondamento.',
                extraValidator: (v) {
                  if (v.isEmpty) return null; // Campo opzionale
                  final x = double.tryParse(v);
                  if (x == null || x <= 0) return 'Deve essere un numero > 0';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            // Note: State logic for price updates is better handled in the parent form or a dedicated bloc listener,
            // but for UI extraction we pass current values down.
            Tooltip(
              message:
                  'Calcola automaticamente la quantità fissa in base al prezzo corrente di $currentSymbol',
              child: IconButton(
                icon: const Icon(Icons.calculate, size: 20),
                onPressed:
                    currentPrice != null && currentPrice! > 0
                        ? onCalculateFixedQuantity
                        : null,
                style: IconButton.styleFrom(
                  backgroundColor:
                      currentPrice != null && currentPrice! > 0
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                  foregroundColor:
                      currentPrice != null && currentPrice! > 0
                          ? AppTheme.primaryColor
                          : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Row(
            children: [
              Expanded(child: const Text('Modalità Test (Binance Testnet)')),
              const SizedBox(width: 6),
              const Tooltip(
                message:
                    'Se attiva, il bot userà gli endpoint Testnet di Binance con fondi virtuali. Ideale per testare la strategia senza rischi.',
                child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
              ),
            ],
          ),
          value: isTestMode,
          onChanged: onTestModeChanged,
          secondary: const Icon(Icons.science_outlined),
          activeThumbColor: AppTheme.accentColor,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Row(
            children: [
              Expanded(child: const Text('Trading con Fee Consapevole')),
              const SizedBox(width: 6),
              const Tooltip(
                message:
                    'Se attiva, utilizza le fee reali di Binance per calcolare il profitto netto nelle decisioni di trading. Migliora la precisione dei calcoli di profitto.',
                child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
              ),
            ],
          ),
          value: enableFeeAwareTrading,
          onChanged: onFeeAwareTradingChanged,
          secondary: const Icon(Icons.account_balance_wallet),
          activeThumbColor: AppTheme.accentColor,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Row(
            children: [
              Expanded(child: const Text('Ri-acquisto Automatico')),
              const SizedBox(width: 6),
              const Tooltip(
                message:
                    'Se attiva, il bot rientra automaticamente in acquisto dopo aver completato un ciclo di vendita. Se disattiva, rimane in attesa senza comprare.',
                child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
              ),
            ],
          ),
          value: enableReBuy,
          onChanged: onEnableReBuyChanged,
          secondary: const Icon(Icons.replay),
          activeThumbColor: AppTheme.accentColor,
        ),
      ],
    );
  }
}
