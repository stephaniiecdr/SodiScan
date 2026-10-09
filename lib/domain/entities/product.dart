enum ConsumptionUnit { serving, gram }

class Product {
  const Product({
    required this.barcode,
    required this.name,
    this.brand,
    this.servingSize,
    this.sodiumPer100gMg,
    this.sodiumPerServingMg,
  });

  final String barcode;
  final String name;
  final String? brand;
  final String? servingSize;
  final double? sodiumPer100gMg;
  final double? sodiumPerServingMg;

  bool get hasSodiumData => sodiumPerServingMg != null || sodiumPer100gMg != null;

  ConsumptionUnit get unit => sodiumPerServingMg != null ? ConsumptionUnit.serving : ConsumptionUnit.gram;

  double sodiumFor(double amount) {
    if (sodiumPerServingMg != null) return sodiumPerServingMg! * amount;
    if (sodiumPer100gMg != null) return sodiumPer100gMg! * amount / 100;
    return 0;
  }
}
