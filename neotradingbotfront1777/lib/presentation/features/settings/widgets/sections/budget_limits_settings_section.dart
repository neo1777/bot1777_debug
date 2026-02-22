import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/settings_section_card.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/settings_text_field.dart';

class BudgetLimitsSettingsSection extends StatelessWidget {
  final Key? sectionKey;
  final TextEditingController maxTradeAmountCapController;
  final TextEditingController maxBuyOveragePctController;
  final bool strictBudget;
  final ValueChanged<bool> onStrictBudgetChanged;

  const BudgetLimitsSettingsSection({
    required this.maxTradeAmountCapController,
    required this.maxBuyOveragePctController,
    required this.strictBudget,
    required this.onStrictBudgetChanged,
    super.key,
    this.sectionKey,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      key: sectionKey,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Budget & Limiti',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Tooltip(
              message:
                  'Limita la spesa e gestisce gli arrotondamenti exchange: cap, overage massimo e vendita parziale.',
              preferBelow: false,
              child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsTextField(
          controller: maxTradeAmountCapController,
          label: 'Massimale importo per trade',
          icon: Icons.shield,
          isNumeric: true,
          tooltip:
              'Tetto massimo lato server su tradeAmount: i valori oltre il cap vengono ridotti.',
          extraValidator: (v) {
            final x = double.parse(v);
            if (x <= 0) return 'Deve essere > 0';
            return null;
          },
        ),
        SettingsTextField(
          controller: maxBuyOveragePctController,
          label: 'Overage massimo BUY (frazione, es. 0.03)',
          icon: Icons.percent,
          isNumeric: true,
          tooltip:
              'Extra budget per superare minNotional/minQty dopo rounding. 0 = disattivato.',
          extraValidator: (v) {
            final x = double.parse(v);
            if (x < 0 || x > 0.2) return 'Intervallo [0, 0.2]';
            return null;
          },
        ),
        SwitchListTile(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Flexible(child: Text('Strict Budget (no overage)')),
              SizedBox(width: 6),
              Tooltip(
                message:
                    'Se attivo, non verrà mai superato l\'importo per trade per soddisfare minNotional/minQty.',
                child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
              ),
            ],
          ),
          value: strictBudget,
          onChanged: onStrictBudgetChanged,
          secondary: const Icon(Icons.lock_outline),
          activeThumbColor: AppTheme.accentColor,
        ),
      ],
    );
  }
}
