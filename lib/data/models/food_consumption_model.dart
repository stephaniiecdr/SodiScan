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

  factory FoodConsumptionModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) throw const FormatException('Item konsumsi harus berupa objek JSON.');

    final id = json['id'];
    final barcode = json['barcode'];
    final productName = json['productName'];
    final sodiumMg = json['sodiumMg'];
    final source = json['source'];
    final consumedAt = json['consumedAt'] is String ? DateTime.tryParse(json['consumedAt'] as String) : null;

    if (id is! String || id.isEmpty) throw const FormatException('Field id wajib berupa teks.');
    if (barcode != null && barcode is! String) throw const FormatException('Field barcode harus teks atau null.');
    if (productName is! String || productName.trim().isEmpty) {
      throw const FormatException('Field productName wajib diisi.');
    }
    if (sodiumMg is! num || !sodiumMg.isFinite || sodiumMg <= 0) {
      throw const FormatException('Field sodiumMg harus angka lebih dari 0.');
    }
    if (!ConsumptionSource.values.any((value) => value.name == source)) {
      throw const FormatException('Field source harus scan atau manual.');
    }
    if (consumedAt == null) throw const FormatException('Field consumedAt harus tanggal ISO 8601.');

    return FoodConsumptionModel(
      id: id,
      barcode: barcode as String?,
      productName: productName.trim(),
      sodiumMg: sodiumMg.toDouble(),
      source: source as String,
      consumedAt: consumedAt,
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

  Map<String, dynamic> toJson() => toMap();

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
