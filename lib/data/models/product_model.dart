import '../../domain/entities/product.dart';

class ProductModel {
  const ProductModel({
    required this.barcode,
    required this.name,
    this.brand,
    this.servingSize,
    this.sodiumPer100gMg,
    this.sodiumPerServingMg,
  });

  factory ProductModel.fromOpenFoodFactsJson(String barcode, Map<String, dynamic> product) {
    final nutriments = product['nutriments'];
    final nutrimentMap = nutriments is Map ? nutriments : const {};
    final name = (product['product_name'] as String?)?.trim();

    return ProductModel(
      barcode: barcode,
      name: name == null || name.isEmpty ? 'Produk $barcode' : name,
      brand: _nonEmpty(product['brands']),
      servingSize: _nonEmpty(product['serving_size']),
      sodiumPer100gMg: _gramToMg(nutrimentMap['sodium_100g']),
      sodiumPerServingMg: _gramToMg(nutrimentMap['sodium_serving']),
    );
  }

  final String barcode;
  final String name;
  final String? brand;
  final String? servingSize;
  final double? sodiumPer100gMg;
  final double? sodiumPerServingMg;

  Product toEntity() {
    return Product(
      barcode: barcode,
      name: name,
      brand: brand,
      servingSize: servingSize,
      sodiumPer100gMg: sodiumPer100gMg,
      sodiumPerServingMg: sodiumPerServingMg,
    );
  }

  static String? _nonEmpty(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static double? _gramToMg(Object? value) {
    final grams = switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text.replaceAll(',', '.')),
      _ => null,
    };
    if (grams == null || !grams.isFinite || grams < 0) return null;
    return grams * 1000;
  }
}
