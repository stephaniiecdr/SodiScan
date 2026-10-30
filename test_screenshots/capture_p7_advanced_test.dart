import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/core/theme/app_theme.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/repositories/settings_repository.dart';
import 'package:sodiscan/domain/services/device_authenticator.dart';
import 'package:sodiscan/domain/services/notification_service.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_consumption_history.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/get_product_by_barcode.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/domain/usecases/update_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/providers/app_lock_notifier.dart';
import 'package:sodiscan/presentation/screens/home/home_screen.dart';
import 'package:sodiscan/presentation/screens/lock/app_lock_gate.dart';
import 'package:sodiscan/presentation/screens/scanner/scan_result.dart';
import 'package:sodiscan/presentation/screens/scanner/scanner_screen.dart';

import '../test/helpers/fake_consumption_repository.dart';
import '../test/helpers/fake_device_services.dart';
import '../test/helpers/fake_product_repository.dart';
import 'screenshot_helpers.dart';

void main() {
  late FakeConsumptionRepository repository;
  late FakeSettingsRepository settings;
  late FakeDeviceAuthenticator authenticator;
  late FakeNotificationService notifications;
  late FakeProductRepository products;
  ScanResult? scanResult;

  setUpAll(loadAppFonts);

  setUp(() {
    repository = FakeConsumptionRepository(items: [
      indomieConsumption(),
      FoodConsumption(
        id: 'keripik',
        productName: 'Keripik Kentang',
        sodiumMg: 900,
        source: ConsumptionSource.manual,
        consumedAt: fixedNow.subtract(const Duration(hours: 1)),
      ),
    ]);
    settings = FakeSettingsRepository();
    authenticator = FakeDeviceAuthenticator();
    notifications = FakeNotificationService();
    products = FakeProductRepository(product: indomieProduct);
    scanResult = null;
  });

  Future<void> pumpApp(WidgetTester tester, {bool settle = true}) async {
    usePhoneView(tester);
    final recordConsumption = RecordConsumption(repository, clock: () => fixedNow);
    final home = AddConsumptionNotifier(
      getDailySummary: GetDailySummary(repository),
      recordConsumption: recordConsumption,
      updateConsumption: UpdateConsumption(repository),
      deleteConsumption: DeleteConsumption(repository),
      clock: () => fixedNow,
    );
    final lock = AppLockNotifier(settingsRepository: settings, authenticator: authenticator);
    addTearDown(home.dispose);
    addTearDown(lock.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: recordConsumption),
          Provider.value(value: GetProductByBarcode(products)),
          Provider.value(value: GetConsumptionHistory(repository)),
          Provider<SettingsRepository>.value(value: settings),
          Provider<DeviceAuthenticator>.value(value: authenticator),
          Provider<NotificationService>.value(value: notifications),
          Provider<ScanBarcode>.value(value: (_) async => scanResult),
          ChangeNotifierProvider.value(value: lock..init()),
          ChangeNotifierProvider.value(value: home..load()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          builder: (_, child) => AppLockGate(child: child!),
          home: const HomeScreen(),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> capture(String name) => captureScreen('../docs/screenshots/pertemuan7/$name.png');

  Future<void> captureScanner(WidgetTester tester, String name, Widget body) async {
    usePhoneView(tester);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: Scaffold(appBar: AppBar(title: const Text('Pindai Barcode')), body: body),
      ),
    );
    await tester.pump();
    await capture(name);
  }

  captureTest('01 home', (tester) async {
    await pumpApp(tester);
    await capture('01_home');
  });

  captureTest('02 scanner loading', (tester) async {
    await captureScanner(tester, '02_scanner_loading', const ScannerStatusView.loading());
  });

  captureTest('03 scanner permission denied', (tester) async {
    await captureScanner(
      tester,
      '03_scanner_permission_denied',
      ScannerStatusView.error(error: MobileScannerErrorCode.permissionDenied, onRetry: () {}, onTypeManually: () {}),
    );
  });

  captureTest('04 scan result', (tester) async {
    scanResult = const ScanResult.barcode('089686010947');
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('scanBarcodeButton')));
    await tester.pumpAndSettle();
    await capture('04_scan_result');
  });

  captureTest('05 scan cancelled', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('scanBarcodeButton')));
    await tester.pumpAndSettle();
    await capture('05_scan_cancelled');
  });

  captureTest('06-07 settings', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('openSettingsButton')));
    await tester.pumpAndSettle();
    await capture('06_settings');

    notifications.permissionGranted = false;
    await tester.tap(find.byKey(const Key('sodiumAlertSwitch')));
    await tester.pumpAndSettle();
    await capture('07_notification_denied');
  });

  captureTest('08 settings enabled', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('openSettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sodiumAlertSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appLockSwitch')));
    await tester.pumpAndSettle();
    await capture('08_settings_enabled');
  });

  captureTest('09 lock authenticating', (tester) async {
    settings.settings = const AppSettings(appLockEnabled: true);
    authenticator.gate = Completer<void>();
    await pumpApp(tester, settle: false);
    await capture('09_lock_authenticating');
    authenticator.gate!.complete();
    await tester.pumpAndSettle();
  });

  captureTest('10 lock cancelled', (tester) async {
    settings.settings = const AppSettings(appLockEnabled: true);
    authenticator.result = DeviceAuthResult.cancelled;
    await pumpApp(tester);
    await capture('10_lock_cancelled');
  });
}
