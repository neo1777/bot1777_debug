import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/settings_section_card.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/settings_text_field.dart';

class DcaSettingsSection extends StatelessWidget {
  final Key? sectionKey;
  final TextEditingController dcaDecrementController;
  final TextEditingController dcaCooldownSecondsController;
  final bool dcaCompareAgainstAverage;
  final ValueChanged<bool> onDcaCompareChanged;

  const DcaSettingsSection({
    required this.dcaDecrementController,
    required this.dcaCooldownSecondsController,
    required this.dcaCompareAgainstAverage,
    required this.onDcaCompareChanged,
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
                'DCA',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Tooltip(
              message:
                  'Regole per acquisto in mediazione: quando scatta, ogni quanto e prezzo di riferimento (ultimo o medio).',
              preferBelow: false,
              child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsTextField(
          controller: dcaDecrementController,
          label: 'Decremento DCA (%)',
          icon: Icons.arrow_downward,
          isNumeric: true,
          tooltip:
              'Discesa dal prezzo di riferimento (ultimo o medio) che fa scattare un DCA. Più alto ⇒ meno DCA.',
          extraValidator: (value) {
            final parsedValue = double.parse(value);
            if (parsedValue < 0 || parsedValue > 90)
              return 'Intervallo [0, 90]';
            return null;
          },
        ),
        SettingsTextField(
          controller: dcaCooldownSecondsController,
          label: 'Cooldown DCA (secondi)',
          icon: Icons.timer,
          isNumeric: true,
          tooltip: 'Tempo minimo tra DCA consecutivi per evitare raffiche.',
          extraValidator: (value) {
            final parsedValue = double.parse(value);
            if (parsedValue < 0) return 'Valore ≥ 0';
            return null;
          },
        ),
        SwitchListTile(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Flexible(child: Text('DCA su Prezzo Medio (averagePrice)')),
              SizedBox(width: 6),
              Tooltip(
                message:
                    'Se attivo, il decremento DCA è calcolato rispetto al prezzo medio (meno DCA quando la posizione cresce).',
                child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
              ),
            ],
          ),
          value: dcaCompareAgainstAverage,
          onChanged: onDcaCompareChanged,
          secondary: const Icon(Icons.swap_vert_circle_outlined),
          activeThumbColor: AppTheme.accentColor,
        ),
      ],
    );
  }
}
