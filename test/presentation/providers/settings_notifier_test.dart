import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/repositories/settings_repository.dart';
import 'package:sodiscan/domain/services/device_authenticator.dart';
import 'package:sodiscan/presentation/providers/settings_notifier.dart';

import '../../helpers/fake_device_services.dart';

void main() {
  late FakeSettingsRepository settings;
  late FakeDeviceAuthenticator authenticator;
  late FakeNotificationService notifications;
  late SettingsNotifier notifier;

  setUp(() async {
    settings = FakeSettingsRepository();
    authenticator = FakeDeviceAuthenticator();
    notifications = FakeNotificationService();
    notifier = SettingsNotifier(
      settingsRepository: settings,
      authenticator: authenticator,
      notificationService: notifications,
    );
    await notifier.load();
  });

  test('mengaktifkan peringatan meminta izin notifikasi lalu menyimpan', () async {
    final message = await notifier.setSodiumAlerts(true);

    expect(notifications.permissionRequests, 1);
    expect(message, SettingsNotifier.notificationOnText);
    expect(settings.settings.sodiumAlertsEnabled, isTrue);
    expect(notifier.settings!.sodiumAlertsEnabled, isTrue);
  });

  test('izin notifikasi ditolak: switch tetap mati dan pesan arahan ditampilkan', () async {
    notifications.permissionGranted = false;

    final message = await notifier.setSodiumAlerts(true);

    expect(message, SettingsNotifier.notificationDeniedText);
    expect(settings.settings.sodiumAlertsEnabled, isFalse);
  });

  test('mematikan peringatan tidak meminta izin', () async {
    settings.settings = const AppSettings(sodiumAlertsEnabled: true);
    await notifier.load();

    await notifier.setSodiumAlerts(false);

    expect(notifications.permissionRequests, 0);
    expect(settings.settings.sodiumAlertsEnabled, isFalse);
  });

  test('mengaktifkan kunci aplikasi butuh autentikasi berhasil', () async {
    final message = await notifier.setAppLock(true);

    expect(authenticator.reasons.single, contains('mengaktifkan'));
    expect(message, SettingsNotifier.lockOnText);
    expect(settings.settings.appLockEnabled, isTrue);
  });

  test('autentikasi dibatalkan atau HP tanpa kunci layar: pengaturan tidak berubah', () async {
    authenticator.result = DeviceAuthResult.cancelled;
    expect(await notifier.setAppLock(true), SettingsNotifier.lockCancelledText);

    authenticator.result = DeviceAuthResult.notAvailable;
    expect(await notifier.setAppLock(true), SettingsNotifier.lockUnavailableText);

    expect(settings.settings.appLockEnabled, isFalse);
  });

  test('gagal menyimpan menampilkan pesan error', () async {
    settings.failSave = true;

    expect(await notifier.setAppLock(true), SettingsNotifier.saveErrorText);
    expect(notifier.settings!.appLockEnabled, isFalse);
    expect(notifier.isBusy, isFalse);
  });
}
