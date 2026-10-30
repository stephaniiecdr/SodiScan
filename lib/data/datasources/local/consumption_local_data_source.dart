import 'package:hive/hive.dart';

import '../../models/food_consumption_model.dart';

class ConsumptionLocalDataSource {
  const ConsumptionLocalDataSource(this._box);

  static const String boxName = 'consumptions';

  final Box<Map> _box;

  Future<void> save(FoodConsumptionModel model) => _box.put(model.id, model.toMap());

  bool contains(String id) => _box.containsKey(id);

  Future<void> delete(String id) => _box.delete(id);

  List<FoodConsumptionModel> getAll() => _box.values.map(FoodConsumptionModel.fromMap).toList();
}
