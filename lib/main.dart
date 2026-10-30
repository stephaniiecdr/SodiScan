import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'core/config/api_config.dart';
import 'data/datasources/local/consumption_local_data_source.dart';
import 'data/datasources/remote/consumption_remote_data_source.dart';
import 'data/datasources/remote/open_food_facts_remote_data_source.dart';
import 'data/repositories/consumption_repository_impl.dart';
import 'data/repositories/consumption_sync_repository_impl.dart';
import 'data/repositories/product_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox<Map>(ConsumptionLocalDataSource.boxName);
  final client = http.Client();

  runApp(
    SodiScanApp(
      consumptionRepository: ConsumptionRepositoryImpl(ConsumptionLocalDataSource(box)),
      consumptionSyncRepository: ConsumptionSyncRepositoryImpl(
        ConsumptionRemoteDataSource(client, baseUrl: sodiScanApiBaseUrl()),
      ),
      productRepository: ProductRepositoryImpl(OpenFoodFactsRemoteDataSource(client)),
    ),
  );
}
