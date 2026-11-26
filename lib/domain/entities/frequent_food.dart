import 'food_consumption.dart';

/// Makanan yang pernah dicatat, untuk fitur "Catat Cepat" (#17).
/// Nilai natrium, barcode, dan sumber diambil dari catatan terakhir makanan tersebut.
class FrequentFood {
  const FrequentFood({
    required this.productName,
    required this.sodiumMg,
    required this.source,
    required this.count,
    required this.lastConsumedAt,
    this.barcode,
  });

  final String productName;
  final double sodiumMg;
  final ConsumptionSource source;
  final String? barcode;
  final int count;
  final DateTime lastConsumedAt;
}
