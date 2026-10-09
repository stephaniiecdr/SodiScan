import 'dart:async';

import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/repositories/consumption_repository.dart';

class FakeConsumptionRepository implements ConsumptionRepository {
  FakeConsumptionRepository({List<FoodConsumption>? items}) : items = items ?? [];

  final List<FoodConsumption> items;

  bool failLoad = false;
  bool failSave = false;
  Completer<void>? loadGate;
  Completer<void>? saveGate;

  int loadCalls = 0;
  int saveCalls = 0;

  @override
  Future<List<FoodConsumption>> getConsumptionsByDate(DateTime date) async {
    loadCalls++;
    if (loadGate != null) await loadGate!.future;
    if (failLoad) throw const StorageFailure('load failed');
    return items
        .where((item) =>
            item.consumedAt.year == date.year && item.consumedAt.month == date.month && item.consumedAt.day == date.day)
        .toList();
  }

  @override
  Future<void> saveConsumption(FoodConsumption consumption) async {
    saveCalls++;
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw const StorageFailure('save failed');
    items.add(consumption);
  }
}

final DateTime fixedNow = DateTime(2026, 10, 1, 12, 30);

FoodConsumption indomieConsumption() {
  return FoodConsumption(
    id: 'indomie-1',
    barcode: '089686010947',
    productName: 'Indomie Mi Goreng',
    sodiumMg: 750,
    source: ConsumptionSource.scan,
    consumedAt: fixedNow.subtract(const Duration(hours: 2)),
  );
}
