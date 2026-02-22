import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Utility per costruire stili di chart adattivi basati sul tema corrente.
///
/// Sostituisce la vecchia dipendenza da `cristalyse` ChartTheme con helper
/// per `fl_chart` che producono configurazioni coerenti e visivamente premium.

/// Restituisce colori adattivi per chart in base alla luminosità del contesto.
class ChartColors {
  final Color primary;
  final Color success;
  final Color danger;
  final Color accent;
  final Color warn;
  final Color axisColor;
  final Color gridColor;
  final Color borderColor;
  final Color background;

  const ChartColors._({
    required this.primary,
    required this.success,
    required this.danger,
    required this.accent,
    required this.warn,
    required this.axisColor,
    required this.gridColor,
    required this.borderColor,
    required this.background,
  });

  factory ChartColors.fromContext(
    BuildContext context, {
    Color? containerBackground,
  }) {
    final theme = Theme.of(context);
    final cardBg = containerBackground ?? theme.cardColor;
    final isDarkBg =
        theme.brightness == Brightness.dark ||
        (cardBg.computeLuminance() < 0.5);

    return ChartColors._(
      primary: theme.colorScheme.primary,
      success: const Color(0xFF28A745),
      danger: const Color(0xFFDC3545),
      accent: const Color(0xFF20C997),
      warn: const Color(0xFFFF6B35),
      axisColor:
          isDarkBg
              ? Colors.white.withValues(alpha: 0.85)
              : const Color(0xFF202124),
      gridColor:
          isDarkBg
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0x1A000000),
      borderColor:
          isDarkBg
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFFE1E5E9),
      background: cardBg,
    );
  }
}

/// Costruisce stile griglia comune per i chart fl_chart.
FlGridData buildChartGrid(ChartColors colors) {
  return FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: null,
    getDrawingHorizontalLine:
        (value) => FlLine(color: colors.gridColor, strokeWidth: 0.6),
  );
}

/// Costruisce stile bordo comune per i chart fl_chart.
FlBorderData buildChartBorder(ChartColors colors) {
  return FlBorderData(
    show: true,
    border: Border(
      bottom: BorderSide(color: colors.borderColor, width: 1),
      left: BorderSide(color: colors.borderColor, width: 1),
      right: BorderSide.none,
      top: BorderSide.none,
    ),
  );
}

/// Stile testi asse per fl_chart.
TextStyle chartAxisTextStyle(ChartColors colors) {
  return TextStyle(
    fontSize: 10,
    color: colors.axisColor,
    fontWeight: FontWeight.w500,
  );
}
