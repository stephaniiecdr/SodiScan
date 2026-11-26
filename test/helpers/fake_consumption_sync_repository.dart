import 'dart:async';

import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/repositories/consumption_sync_repository.dart';

class FakeConsumptionSyncRepository implements ConsumptionSyncRepository {
  FakeConsumptionSyncRepository({List<FoodConsumption>? items}) : items = items ?? [];

  final List<FoodConsumption> items;

  Failure? failWith;
  Set<String> failIds = {};
  Completer<void>? gate;
  int fetchCalls = 0;
  int uploadCalls = 0;

  @override
  Future<List<FoodConsumption>> fetchFromServer() async {
    fetchCalls++;
    if (gate != null) await gate!.future;
    if (failWith != null) throw failWith!;
    return List.of(items);
  }

  Set<String> failDeleteIds = {};
  int deleteCalls = 0;

  @override
  Future<void> deleteFromServer(String id) async {
    deleteCalls++;
    if (gate != null) await gate!.future;
    if (failWith != null) throw failWith!;
    if (failDeleteIds.contains(id)) throw NetworkFailure('delete $id failed');
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> uploadToServer(FoodConsumption consumption) async {
    uploadCalls++;
    if (gate != null) await gate!.future;
    if (failWith != null) throw failWith!;
    if (failIds.contains(consumption.id)) throw NetworkFailure('upload ${consumption.id} failed');
    items
      ..removeWhere((item) => item.id == consumption.id)
      ..add(consumption);
  }
}
