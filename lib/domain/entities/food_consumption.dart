enum ConsumptionSource { scan, manual }

class FoodConsumption {
  const FoodConsumption({
    required this.id,
    this.barcode,
    required this.productName,
    required this.sodiumMg,
    required this.source,
    required this.consumedAt,
    this.updatedAt,
  });

  final String id;
  final String? barcode;
  final String productName;
  final double sodiumMg;
  final ConsumptionSource source;
  final DateTime consumedAt;

  /// Waktu terakhir catatan diubah. `null` berarti belum pernah diubah sejak dicatat.
  final DateTime? updatedAt;

  /// Dipakai untuk menyelesaikan konflik sinkronisasi (last-modified-wins).
  DateTime get lastModifiedAt => updatedAt ?? consumedAt;

  FoodConsumption copyWith({String? productName, double? sodiumMg, DateTime? updatedAt}) {
    return FoodConsumption(
      id: id,
      barcode: barcode,
      productName: productName ?? this.productName,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      source: source,
      consumedAt: consumedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
