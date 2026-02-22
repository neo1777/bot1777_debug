import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/settings_section_card.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/settings_text_field.dart';

class WarmupSettingsSection extends StatelessWidget {
  final Key? sectionKey;
  final bool buyOnStart;
  final ValueChanged<bool> onBuyOnStartChanged;
  final bool buyOnStartRespectWarmup;
  final ValueChanged<bool> onBuyOnStartRespectWarmupChanged;
  final TextEditingController initialWarmupTicksController;
  final TextEditingController initialWarmupSecondsController;
  final TextEditingController initialSignalThresholdPctController;

  const WarmupSettingsSection({
    required this.buyOnStart,
    required this.onBuyOnStartChanged,
    required this.buyOnStartRespectWarmup,
    required this.onBuyOnStartRespectWarmupChanged,
    required this.initialWarmupTicksController,
    required this.initialWarmupSecondsController,
    required this.initialSignalThresholdPctController,
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
                'Avvio & Warm‑up',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Tooltip(
              message:
                  'Regole primo BUY: warm‑up per tick/tempo e soglia di segnale dal primo prezzo osservato.',
              preferBelow: false,
              child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Flexible(child: Text('Compra Subito all\'Avvio (buyOnStart)')),
              SizedBox(width: 6),
              Tooltip(
                message:
                    'Se disattivo, applica warm‑up e soglia di segnale prima del primo BUY',
                child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
              ),
            ],
          ),
          value: buyOnStart,
          onChanged: onBuyOnStartChanged,
          secondary: const Icon(Icons.play_circle_outline),
          activeThumbColor: AppTheme.accentColor,
        ),
        SwitchListTile(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Flexible(child: Text('Rispetta Warm‑up anche con buyOnStart')),
              SizedBox(width: 6),
              Tooltip(
                message:
                    'Se attivo, il primo BUY aspetta comunque le condizioni di warm‑up.',
                child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
              ),
            ],
          ),
          value: buyOnStartRespectWarmup,
          onChanged: onBuyOnStartRespectWarmupChanged,
          secondary: const Icon(Icons.pending_actions_outlined),
          activeThumbColor: AppTheme.accentColor,
        ),
        SettingsTextField(
          controller: initialWarmupTicksController,
          label: 'Warm‑up Minimo (tick)',
          icon: Icons.timelapse,
          isNumeric: true,
          tooltip: 'Numero minimo di tick da osservare prima del primo BUY.',
          extraValidator: (value) {
            final parsedValue = int.tryParse(value) ?? -1;
            if (parsedValue < 0) return 'Valore ≥ 0';
            return null;
          },
        ),
        SettingsTextField(
          controller: initialWarmupSecondsController,
          label: 'Warm‑up Timeout (secondi)',
          icon: Icons.hourglass_bottom,
          isNumeric: true,
          tooltip: 'Tempo minimo (secondi) da attendere prima del primo BUY.',
          extraValidator: (value) {
            final parsedValue = double.parse(value);
            if (parsedValue < 0) return 'Valore ≥ 0';
            return null;
          },
        ),
        SettingsTextField(
          controller: initialSignalThresholdPctController,
          label: 'Soglia Segnale Iniziale (%)',
          icon: Icons.multiline_chart,
          isNumeric: true,
          tooltip:
              'Variazione percentuale assoluta dal primo prezzo osservato necessaria per il primo BUY.',
          extraValidator: (value) {
            final parsedValue = double.parse(value);
            if (parsedValue < 0 || parsedValue >= 100)
              return 'Intervallo [0, 100)';
            return null;
          },
        ),
      ],
    );
  }
}
