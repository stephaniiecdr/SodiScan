import 'package:hive/hive.dart';

import '../../../core/logging/app_log.dart';
import '../../models/food_consumption_model.dart';

class ConsumptionLocalDataSource {
  const ConsumptionLocalDataSource(this._box);

  static const String boxName = 'consumptions';
  static const String _tag = 'Hive';

  final Box<Map> _box;

  Future<void> save(FoodConsumptionModel model) => _box.put(model.id, model.toMap());

  bool contains(String id) => _box.containsKey(id);

  Future<void> delete(String id) => _box.delete(id);

  /// Satu catatan rusak (field hilang / tipe salah) dilewati dan dicatat di log,
  /// bukan membuat seluruh riwayat gagal dimuat.
  List<FoodConsumptionModel> getAll() {
    final models = <FoodConsumptionModel>[];
    for (final key in _box.keys) {
      try {
        models.add(FoodConsumptionModel.fromMap(_box.get(key)!));
      } catch (error) {
        AppLog.w(_tag, 'Catatan lokal $key rusak dan dilewati', error);
      }
    }
    return models;
  }
}
