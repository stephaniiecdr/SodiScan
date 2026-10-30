import 'dart:async';

import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/repositories/consumption_sync_repository.dart';

class FakeConsumptionSyncRepository implements ConsumptionSyncRepository {
  FakeConsumptionSyncRepository({List<FoodConsumption>? items}) : items = items ?? [];

  final List<FoodConsumption> items;

  Failure? failWith;
  Completer<void>? gate;
  int fetchCalls = 0;

  @override
  Future<List<FoodConsumption>> fetchFromServer() async {
    fetchCalls++;
    if (gate != null) await gate!.future;
    if (failWith != null) throw failWith!;
    return List.of(items);
  }

  @override
  Future<void> uploadToServer(FoodConsumption consumption) async {
    if (gate != null) await gate!.future;
    if (failWith != null) throw failWith!;
    items
      ..removeWhere((item) => item.id == consumption.id)
      ..add(consumption);
  }
}
