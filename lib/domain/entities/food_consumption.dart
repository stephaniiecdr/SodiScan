enum ConsumptionSource { scan, manual }

class FoodConsumption {
  const FoodConsumption({
    required this.id,
    this.barcode,
    required this.productName,
    required this.sodiumMg,
    required this.source,
    required this.consumedAt,
  });

  final String id;
  final String? barcode;
  final String productName;
  final double sodiumMg;
  final ConsumptionSource source;
  final DateTime consumedAt;

  FoodConsumption copyWith({String? productName, double? sodiumMg}) {
    return FoodConsumption(
      id: id,
      barcode: barcode,
      productName: productName ?? this.productName,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      source: source,
      consumedAt: consumedAt,
    );
  }
}
