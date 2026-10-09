import '../../domain/entities/food_consumption.dart';

class FoodConsumptionModel {
  const FoodConsumptionModel({
    required this.id,
    this.barcode,
    required this.productName,
    required this.sodiumMg,
    required this.source,
    required this.consumedAt,
  });

  factory FoodConsumptionModel.fromEntity(FoodConsumption entity) {
    return FoodConsumptionModel(
      id: entity.id,
      barcode: entity.barcode,
      productName: entity.productName,
      sodiumMg: entity.sodiumMg,
      source: entity.source.name,
      consumedAt: entity.consumedAt,
    );
  }

  factory FoodConsumptionModel.fromMap(Map<dynamic, dynamic> map) {
    return FoodConsumptionModel(
      id: map['id'] as String,
      barcode: map['barcode'] as String?,
      productName: map['productName'] as String,
      sodiumMg: (map['sodiumMg'] as num).toDouble(),
      source: map['source'] as String,
      consumedAt: DateTime.parse(map['consumedAt'] as String),
    );
  }

  final String id;
  final String? barcode;
  final String productName;
  final double sodiumMg;
  final String source;
  final DateTime consumedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'productName': productName,
      'sodiumMg': sodiumMg,
      'source': source,
      'consumedAt': consumedAt.toIso8601String(),
    };
  }

  FoodConsumption toEntity() {
    return FoodConsumption(
      id: id,
      barcode: barcode,
      productName: productName,
      sodiumMg: sodiumMg,
      source: ConsumptionSource.values.firstWhere(
        (value) => value.name == source,
        orElse: () => ConsumptionSource.manual,
      ),
      consumedAt: consumedAt,
    );
  }
}
