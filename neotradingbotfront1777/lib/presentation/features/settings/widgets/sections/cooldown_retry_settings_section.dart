import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/sections/settings_section_card.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/widgets/settings_text_field.dart';

class CooldownRetrySettingsSection extends StatelessWidget {
  final Key? sectionKey;
  final TextEditingController buyCooldownSecondsController;
  final TextEditingController dustRetryCooldownSecondsController;
  final TextEditingController maxCyclesController;

  const CooldownRetrySettingsSection({
    required this.buyCooldownSecondsController,
    required this.dustRetryCooldownSecondsController,
    required this.maxCyclesController,
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
                'Cooldown & Retry',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Tooltip(
              message:
                  'Rallenta l’emissione di ordini BUY e gestisce il retry delle vendite fallite per dust.',
              preferBelow: false,
              child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SettingsTextField(
          controller: buyCooldownSecondsController,
          label: 'Cooldown BUY (secondi)',
          icon: Icons.schedule,
          isNumeric: true,
          tooltip:
              'Tempo minimo tra BUY consecutivi (iniziale o DCA). Riduce doppioni in rapida successione.',
          extraValidator: (value) {
            final parsedValue = double.parse(value);
            if (parsedValue < 0 || parsedValue > 3600) {
              return 'Intervallo [0, 3600]';
            }
            return null;
          },
        ),
        SettingsTextField(
          controller: dustRetryCooldownSecondsController,
          label: 'Cooldown retry SELL dust (secondi)',
          icon: Icons.hourglass_top,
          isNumeric: true,
          tooltip:
              'Ritardo tra tentativi di vendita falliti per notional troppo basso (dust).',
          extraValidator: (value) {
            final parsedValue = double.parse(value);
            if (parsedValue < 0) return 'Valore ≥ 0';
            return null;
          },
        ),
        SettingsTextField(
          controller: maxCyclesController,
          label: 'Numero massimo cicli (0 = infinito)',
          icon: Icons.repeat_on,
          isNumeric: true,
          tooltip:
              'Numero di cicli completi (compra→vendi→ricomincia) che il backend eseguirà prima di fermarsi automaticamente. 0 = nessun limite (infinito). Funziona anche a frontend chiuso.',
          extraValidator: (value) {
            final parsedValue = int.tryParse(value) ?? -1;
            if (parsedValue < 0) return 'Valore ≥ 0';
            return null;
          },
        ),
      ],
    );
  }
}
