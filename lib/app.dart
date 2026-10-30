import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'domain/repositories/consumption_repository.dart';
import 'domain/repositories/consumption_sync_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/services/device_authenticator.dart';
import 'domain/services/notification_service.dart';
import 'domain/usecases/delete_consumption.dart';
import 'domain/usecases/get_consumption_history.dart';
import 'domain/usecases/get_daily_summary.dart';
import 'domain/usecases/get_product_by_barcode.dart';
import 'domain/usecases/record_consumption.dart';
import 'domain/usecases/send_sodium_alert.dart';
import 'domain/usecases/sync_consumptions.dart';
import 'domain/usecases/update_consumption.dart';
import 'presentation/providers/add_consumption_notifier.dart';
import 'presentation/providers/app_lock_notifier.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/lock/app_lock_gate.dart';

class SodiScanApp extends StatelessWidget {
  const SodiScanApp({
    super.key,
    required this.consumptionRepository,
    required this.consumptionSyncRepository,
    required this.productRepository,
    required this.settingsRepository,
    required this.authenticator,
    required this.notificationService,
  });

  final ConsumptionRepository consumptionRepository;
  final ConsumptionSyncRepository consumptionSyncRepository;
  final ProductRepository productRepository;
  final SettingsRepository settingsRepository;
  final DeviceAuthenticator authenticator;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    final recordConsumption = RecordConsumption(consumptionRepository);

    return MultiProvider(
      providers: [
        Provider.value(value: recordConsumption),
        Provider.value(value: GetProductByBarcode(productRepository)),
        Provider.value(value: GetConsumptionHistory(consumptionRepository)),
        Provider.value(value: settingsRepository),
        Provider.value(value: authenticator),
        Provider.value(value: notificationService),
        Provider.value(value: GetServerConsumptions(consumptionSyncRepository)),
        Provider.value(value: UploadConsumptions(consumptionRepository, consumptionSyncRepository)),
        Provider.value(value: RestoreConsumptions(consumptionSyncRepository, consumptionRepository)),
        ChangeNotifierProvider(
          create: (_) => AppLockNotifier(settingsRepository: settingsRepository, authenticator: authenticator)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => AddConsumptionNotifier(
            getDailySummary: GetDailySummary(consumptionRepository),
            recordConsumption: recordConsumption,
            updateConsumption: UpdateConsumption(consumptionRepository),
            deleteConsumption: DeleteConsumption(consumptionRepository),
            sendSodiumAlert: SendSodiumAlert(settingsRepository, notificationService),
          )..load(),
        ),
      ],
      child: MaterialApp(
        title: 'SodiScan',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        builder: (_, child) => AppLockGate(child: child!),
        home: const HomeScreen(),
      ),
    );
  }
}
