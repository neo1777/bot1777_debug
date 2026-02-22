import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/settings_section_card.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/settings_text_field.dart';

class TargetsRiskSettingsSection extends StatelessWidget {
  final Key? sectionKey;
  final TextEditingController profitTargetController;
  final TextEditingController stopLossController;
  final TextEditingController maxOpenTradesController;

  const TargetsRiskSettingsSection({
    required this.profitTargetController,
    required this.stopLossController,
    required this.maxOpenTradesController,
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
                'Obiettivi & Rischio',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Tooltip(
              message:
                  'Controlla quando prendere profitto o fermare la perdita, e l’esposizione massima in numero di trade.',
              preferBelow: false,
              child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsTextField(
          controller: profitTargetController,
          label: 'Target Profit (%)',
          icon: Icons.trending_up,
          isNumeric: true,
          tooltip:
              'Percentuale di guadagno target rispetto al prezzo medio. Valori bassi chiudono prima, valori alti attendono di più.',
          extraValidator: (v) {
            final x = double.parse(v);
            if (x <= 0 || x >= 100) return 'Intervallo (0, 100)';
            return null;
          },
        ),
        SettingsTextField(
          controller: stopLossController,
          label: 'Stop Loss (%)',
          icon: Icons.trending_down,
          isNumeric: true,
          tooltip:
              'Perdita massima concessa rispetto al prezzo medio. Protegge dal drawdown prolungato.',
          extraValidator: (v) {
            final x = double.parse(v);
            if (x <= 0 || x >= 100) return 'Intervallo (0, 100)';
            return null;
          },
        ),
        SettingsTextField(
          controller: maxOpenTradesController,
          label: 'Massimo N. di Trade Aperti',
          icon: Icons.layers,
          isNumeric: true,
          tooltip:
              'Limita il numero di DCA/posizioni aperte per round: controlla l’esposizione complessiva.',
          extraValidator: (v) {
            final x = int.parse(v);
            if (x < 1) return 'Almeno 1';
            return null;
          },
        ),
      ],
    );
  }
}
