import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';

class SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isNumeric;
  final String? Function(String value)? extraValidator;
  final String? tooltip;

  const SettingsTextField({
    required this.controller,
    required this.label,
    required this.icon,
    super.key,
    this.isNumeric = false,
    this.extraValidator,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.accentColor),
          suffixIcon:
              tooltip == null
                  ? null
                  : Tooltip(
                    message: tooltip!,
                    preferBelow: false,
                    child: const Icon(Icons.info_outline, size: 18),
                  ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        keyboardType:
            isNumeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Questo campo è obbligatorio.';
          }
          if (isNumeric && double.tryParse(value) == null) {
            return 'Inserisci un valore numerico valido.';
          }
          if (extraValidator != null) {
            final msg = extraValidator!(value);
            if (msg != null) return msg;
          }
          // La validazione per !isNumeric non è necessaria se il campo è di testo generico.
          // Se ci fossero requisiti specifici (es. no caratteri speciali), andrebbero qui.
          return null;
        },
      ),
    );
  }
}
