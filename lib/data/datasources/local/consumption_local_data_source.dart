import 'package:hive/hive.dart';

import '../../../core/logging/app_log.dart';
import '../../models/food_consumption_model.dart';

class ConsumptionLocalDataSource {
  ConsumptionLocalDataSource(this._box, {Box<dynamic>? deletedBox}) : _deletedBox = deletedBox;

  static const String boxName = 'consumptions';
  static const String deletedBoxName = 'deleted_consumptions';
  static const String _tag = 'Hive';

  final Box<Map> _box;

  /// Tombstone: id catatan yang dihapus -> waktu hapus (ISO 8601).
  /// Tanpa box (mis. di test lama) disimpan di memori.
  final Box<dynamic>? _deletedBox;
  final Map<String, String> _memoryDeleted = {};

  Future<void> save(FoodConsumptionModel model) async {
    await _box.put(model.id, model.toMap());
    await forgetDeleted(model.id);
  }

  bool contains(String id) => _box.containsKey(id);

  Future<void> delete(String id, {DateTime? deletedAt}) async {
    await _box.delete(id);
    final stamp = (deletedAt ?? DateTime.now()).toIso8601String();
    final deletedBox = _deletedBox;
    if (deletedBox == null) {
      _memoryDeleted[id] = stamp;
    } else {
      await deletedBox.put(id, stamp);
    }
  }

  Set<String> deletedIds() => (_deletedBox?.keys.cast<String>() ?? _memoryDeleted.keys).toSet();

  Future<void> forgetDeleted(String id) async {
    _memoryDeleted.remove(id);
    await _deletedBox?.delete(id);
  }

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
