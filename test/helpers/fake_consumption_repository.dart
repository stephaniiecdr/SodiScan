import 'dart:async';

import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/repositories/consumption_repository.dart';

class FakeConsumptionRepository implements ConsumptionRepository {
  FakeConsumptionRepository({List<FoodConsumption>? items}) : items = items ?? [];

  final List<FoodConsumption> items;

  bool failLoad = false;
  bool failSave = false;
  bool failUpdate = false;
  bool failDelete = false;
  Completer<void>? loadGate;
  Completer<void>? saveGate;

  int loadCalls = 0;
  int saveCalls = 0;
  int updateCalls = 0;

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
  Future<List<FoodConsumption>> getAllConsumptions() async {
    loadCalls++;
    if (loadGate != null) await loadGate!.future;
    if (failLoad) throw const StorageFailure('load failed');
    return List.of(items);
  }

  @override
  Future<void> saveConsumption(FoodConsumption consumption) async {
    saveCalls++;
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw const StorageFailure('save failed');
    items.add(consumption);
  }

  @override
  Future<void> updateConsumption(FoodConsumption consumption) async {
    updateCalls++;
    if (saveGate != null) await saveGate!.future;
    if (failUpdate) throw const StorageFailure('update failed');
    final index = items.indexWhere((item) => item.id == consumption.id);
    if (index < 0) throw const StorageFailure('not found');
    items[index] = consumption;
  }

  @override
  Future<void> deleteConsumption(String id) async {
    if (failDelete) throw const StorageFailure('delete failed');
    items.removeWhere((item) => item.id == id);
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
