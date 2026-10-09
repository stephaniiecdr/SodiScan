import 'package:hive/hive.dart';

import '../../models/food_consumption_model.dart';

class ConsumptionLocalDataSource {
  const ConsumptionLocalDataSource(this._box);

  static const String boxName = 'consumptions';

  final Box<Map> _box;

  Future<void> save(FoodConsumptionModel model) => _box.put(model.id, model.toMap());

  List<FoodConsumptionModel> getAll() => _box.values.map(FoodConsumptionModel.fromMap).toList();
}
