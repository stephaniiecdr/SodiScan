import '../../core/errors/failures.dart';
import '../../domain/entities/food_consumption.dart';
import '../../domain/repositories/consumption_sync_repository.dart';
import '../datasources/remote/consumption_remote_data_source.dart';
import '../models/food_consumption_model.dart';

class ConsumptionSyncRepositoryImpl implements ConsumptionSyncRepository {
  const ConsumptionSyncRepositoryImpl(this._remoteDataSource);

  final ConsumptionRemoteDataSource _remoteDataSource;

  @override
  Future<List<FoodConsumption>> fetchFromServer() {
    return _guard('memuat data dari server', () async {
      final models = await _remoteDataSource.fetchAll();
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<void> uploadToServer(FoodConsumption consumption) {
    return _guard('menyimpan data ke server', () => _remoteDataSource.upsert(FoodConsumptionModel.fromEntity(consumption)));
  }

  Future<T> _guard<T>(String action, Future<T> Function() run) async {
    try {
      return await run();
    } on FormatException catch (error) {
      throw DataFormatFailure('Data dari server rusak saat $action: ${error.message}');
    } on TypeError catch (error) {
      throw DataFormatFailure('Data dari server rusak saat $action: $error');
    } catch (error) {
      throw NetworkFailure('Gagal $action: $error');
    }
  }
}
