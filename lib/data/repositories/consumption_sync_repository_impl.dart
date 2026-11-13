import '../../domain/entities/food_consumption.dart';
import '../../domain/repositories/consumption_sync_repository.dart';
import '../datasources/remote/consumption_remote_data_source.dart';
import '../models/food_consumption_model.dart';
import 'repository_guard.dart';

class ConsumptionSyncRepositoryImpl implements ConsumptionSyncRepository {
  const ConsumptionSyncRepositoryImpl(this._remoteDataSource);

  final ConsumptionRemoteDataSource _remoteDataSource;

  @override
  Future<List<FoodConsumption>> fetchFromServer() {
    return guardRemote('memuat data dari server', () async {
      final models = await _remoteDataSource.fetchAll();
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<void> uploadToServer(FoodConsumption consumption) {
    return guardRemote(
      'menyimpan data ke server',
      () => _remoteDataSource.upsert(FoodConsumptionModel.fromEntity(consumption)),
    );
  }
}
