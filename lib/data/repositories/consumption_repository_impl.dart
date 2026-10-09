import '../../core/errors/failures.dart';
import '../../domain/entities/food_consumption.dart';
import '../../domain/repositories/consumption_repository.dart';
import '../datasources/local/consumption_local_data_source.dart';
import '../models/food_consumption_model.dart';

class ConsumptionRepositoryImpl implements ConsumptionRepository {
  const ConsumptionRepositoryImpl(this._localDataSource);

  final ConsumptionLocalDataSource _localDataSource;

  @override
  Future<List<FoodConsumption>> getConsumptionsByDate(DateTime date) async {
    try {
      return _localDataSource
          .getAll()
          .where((model) => _isSameDay(model.consumedAt, date))
          .map((model) => model.toEntity())
          .toList();
    } catch (error) {
      throw StorageFailure('Gagal membaca data konsumsi: $error');
    }
  }

  @override
  Future<void> saveConsumption(FoodConsumption consumption) async {
    try {
      await _localDataSource.save(FoodConsumptionModel.fromEntity(consumption));
    } catch (error) {
      throw StorageFailure('Gagal menyimpan data konsumsi: $error');
    }
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
