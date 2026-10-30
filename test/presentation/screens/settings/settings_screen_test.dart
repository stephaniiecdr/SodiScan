import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/domain/repositories/settings_repository.dart';
import 'package:sodiscan/domain/services/device_authenticator.dart';
import 'package:sodiscan/domain/services/notification_service.dart';
import 'package:sodiscan/presentation/providers/settings_notifier.dart';
import 'package:sodiscan/presentation/screens/settings/settings_screen.dart';

import '../../../helpers/fake_device_services.dart';

void main() {
  late FakeSettingsRepository settings;
  late FakeDeviceAuthenticator authenticator;
  late FakeNotificationService notifications;

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SettingsRepository>.value(value: settings),
          Provider<DeviceAuthenticator>.value(value: authenticator),
          Provider<NotificationService>.value(value: notifications),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(SettingsScreen.route(context)),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  bool switchValue(WidgetTester tester, String key) => tester.widget<SwitchListTile>(find.byKey(Key(key))).value;

  setUp(() {
    settings = FakeSettingsRepository();
    authenticator = FakeDeviceAuthenticator();
    notifications = FakeNotificationService();
  });

  testWidgets('menampilkan pengaturan tersimpan', (tester) async {
    settings.settings = const AppSettings(sodiumAlertsEnabled: true);
    await pumpScreen(tester);

    expect(switchValue(tester, 'sodiumAlertSwitch'), isTrue);
    expect(switchValue(tester, 'appLockSwitch'), isFalse);
  });

  testWidgets('izin notifikasi diberikan - switch menyala dan pesan sukses', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('sodiumAlertSwitch')));
    await tester.pumpAndSettle();

    expect(switchValue(tester, 'sodiumAlertSwitch'), isTrue);
    expect(find.text(SettingsNotifier.notificationOnText), findsOneWidget);
  });

  testWidgets('izin notifikasi ditolak - switch tetap mati dan arahan ditampilkan', (tester) async {
    notifications.permissionGranted = false;
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('sodiumAlertSwitch')));
    await tester.pumpAndSettle();

    expect(switchValue(tester, 'sodiumAlertSwitch'), isFalse);
    expect(find.text(SettingsNotifier.notificationDeniedText), findsOneWidget);
  });

  testWidgets('kunci aplikasi dibatalkan - switch tetap mati', (tester) async {
    authenticator.result = DeviceAuthResult.cancelled;
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('appLockSwitch')));
    await tester.pumpAndSettle();

    expect(switchValue(tester, 'appLockSwitch'), isFalse);
    expect(find.text(SettingsNotifier.lockCancelledText), findsOneWidget);
  });

  testWidgets('kunci aplikasi diaktifkan setelah autentikasi berhasil', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('appLockSwitch')));
    await tester.pumpAndSettle();

    expect(switchValue(tester, 'appLockSwitch'), isTrue);
    expect(settings.settings.appLockEnabled, isTrue);
  });
}
