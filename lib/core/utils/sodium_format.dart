String formatSodiumMg(double value) {
  final number = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  return '$number mg';
}
