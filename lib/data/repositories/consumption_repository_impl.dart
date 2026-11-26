import '../../core/errors/failures.dart';
import '../../domain/entities/food_consumption.dart';
import '../../domain/repositories/consumption_repository.dart';
import '../datasources/local/consumption_local_data_source.dart';
import '../models/food_consumption_model.dart';
import 'repository_guard.dart';

class ConsumptionRepositoryImpl implements ConsumptionRepository {
  const ConsumptionRepositoryImpl(this._localDataSource);

  final ConsumptionLocalDataSource _localDataSource;

  @override
  Future<List<FoodConsumption>> getConsumptionsByDate(DateTime date) {
    return guardStorage('membaca data konsumsi', () async {
      return _readAll().where((consumption) => _isSameDay(consumption.consumedAt, date)).toList();
    });
  }

  @override
  Future<List<FoodConsumption>> getAllConsumptions() {
    return guardStorage('membaca riwayat konsumsi', () async => _readAll().toList());
  }

  @override
  Future<void> saveConsumption(FoodConsumption consumption) {
    return guardStorage('menyimpan data konsumsi', () => _write(consumption));
  }

  @override
  Future<void> updateConsumption(FoodConsumption consumption) async {
    if (!_localDataSource.contains(consumption.id)) {
      throw const StorageFailure('Data konsumsi yang akan diubah tidak ditemukan.');
    }
    await guardStorage('mengubah data konsumsi', () => _write(consumption));
  }

  @override
  Future<void> deleteConsumption(String id) {
    return guardStorage('menghapus data konsumsi', () => _localDataSource.delete(id));
  }

  Iterable<FoodConsumption> _readAll() => _localDataSource.getAll().map((model) => model.toEntity());

  Future<void> _write(FoodConsumption consumption) => _localDataSource.save(FoodConsumptionModel.fromEntity(consumption));

  bool _isSameDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }
}
