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
import 'data/repositories/settings_repository_impl.dart';
import 'data/services/local_auth_device_authenticator.dart';
import 'data/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox<Map>(ConsumptionLocalDataSource.boxName);
  final settingsBox = await Hive.openBox<dynamic>(SettingsRepositoryImpl.boxName);
  final notificationService = await LocalNotificationService.create();
  final client = http.Client();

  runApp(
    SodiScanApp(
      consumptionRepository: ConsumptionRepositoryImpl(ConsumptionLocalDataSource(box)),
      consumptionSyncRepository: ConsumptionSyncRepositoryImpl(
        ConsumptionRemoteDataSource(client, baseUrl: sodiScanApiBaseUrl()),
      ),
      productRepository: ProductRepositoryImpl(OpenFoodFactsRemoteDataSource(client)),
      settingsRepository: SettingsRepositoryImpl(settingsBox),
      authenticator: LocalAuthDeviceAuthenticator(),
      notificationService: notificationService,
    ),
  );
}
