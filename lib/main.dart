import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'core/config/api_config.dart';
import 'core/logging/app_log.dart';
import 'core/logging/error_reporting.dart';
import 'core/logging/log_observers.dart';
import 'data/datasources/local/consumption_local_data_source.dart';
import 'data/datasources/local/hive_log_store.dart';
import 'data/datasources/remote/consumption_remote_data_source.dart';
import 'data/datasources/remote/open_food_facts_remote_data_source.dart';
import 'data/repositories/consumption_repository_impl.dart';
import 'data/repositories/consumption_sync_repository_impl.dart';
import 'data/repositories/product_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/services/local_auth_device_authenticator.dart';
import 'data/services/local_notification_service.dart';
import 'data/services/logging_http_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorReporting();
  await Hive.initFlutter();
  AppLog.configure(store: HiveLogStore(await Hive.openBox<Map>(HiveLogStore.boxName)));
  createLifecycleLogger();

  final apiBaseUrl = sodiScanApiBaseUrl();
  AppLog.i('App', 'SodiScan dimulai (mode: ${_buildMode()}, platform: ${defaultTargetPlatform.name}, API: $apiBaseUrl)');

  final box = await Hive.openBox<Map>(ConsumptionLocalDataSource.boxName);
  final deletedBox = await Hive.openBox<dynamic>(ConsumptionLocalDataSource.deletedBoxName);
  final settingsBox = await Hive.openBox<dynamic>(SettingsRepositoryImpl.boxName);
  final notificationService = await LocalNotificationService.create();
  final client = LoggingHttpClient(http.Client());
  AppLog.d('App', 'Inisialisasi selesai (${box.length} catatan lokal)');

  runApp(
    SodiScanApp(
      consumptionRepository: ConsumptionRepositoryImpl(ConsumptionLocalDataSource(box, deletedBox: deletedBox)),
      consumptionSyncRepository: ConsumptionSyncRepositoryImpl(ConsumptionRemoteDataSource(client, baseUrl: apiBaseUrl)),
      productRepository: ProductRepositoryImpl(OpenFoodFactsRemoteDataSource(client)),
      settingsRepository: SettingsRepositoryImpl(settingsBox),
      authenticator: LocalAuthDeviceAuthenticator(),
      notificationService: notificationService,
      logStore: AppLog.store,
    ),
  );
}

String _buildMode() {
  if (kReleaseMode) return 'release';
  if (kProfileMode) return 'profile';
  return 'debug';
}
