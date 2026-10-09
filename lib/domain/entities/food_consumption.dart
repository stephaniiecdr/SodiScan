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
}
