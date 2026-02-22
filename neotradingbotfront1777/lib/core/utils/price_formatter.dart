class PriceFormatter {
  /// Formats the price with appropriate decimal places based on its value.
  /// - >= 1000: 2 decimal places
  /// - >= 1: 4 decimal places
  /// - < 1: 8 decimal places
  static String format(double price) {
    final abs = price.abs();
    if (abs >= 1000) return price.toStringAsFixed(2);
    if (abs >= 1) return price.toStringAsFixed(4);
    if (abs == 0) return price.toStringAsFixed(2); // Gestione zero
    return price.toStringAsFixed(8);
  }
}
