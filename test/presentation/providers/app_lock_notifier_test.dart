import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/repositories/settings_repository.dart';
import 'package:sodiscan/domain/services/device_authenticator.dart';
import 'package:sodiscan/presentation/providers/app_lock_notifier.dart';

import '../../helpers/fake_device_services.dart';

void main() {
  late FakeSettingsRepository settings;
  late FakeDeviceAuthenticator authenticator;
  late DateTime now;

  AppLockNotifier build() {
    return AppLockNotifier(
      settingsRepository: settings,
      authenticator: authenticator,
      clock: () => now,
    );
  }

  setUp(() {
    settings = FakeSettingsRepository(const AppSettings(appLockEnabled: true));
    authenticator = FakeDeviceAuthenticator();
    now = DateTime(2026, 10, 1, 12);
  });

  test('kunci mati: aplikasi langsung terbuka tanpa autentikasi', () async {
    settings.settings = const AppSettings();
    final notifier = build();

    await notifier.init();

    expect(notifier.status, AppLockStatus.unlocked);
    expect(authenticator.reasons, isEmpty);
  });

  test('kunci aktif: autentikasi berhasil membuka aplikasi', () async {
    final notifier = build();

    await notifier.init();

    expect(notifier.status, AppLockStatus.unlocked);
    expect(authenticator.reasons.single, AppLockNotifier.unlockReason);
  });

  test('dibatalkan pengguna: tetap terkunci dengan pesan, lalu bisa dicoba lagi', () async {
    authenticator.result = DeviceAuthResult.cancelled;
    final notifier = build();

    await notifier.init();
    expect(notifier.status, AppLockStatus.locked);
    expect(notifier.message, AppLockNotifier.cancelledText);

    authenticator.result = DeviceAuthResult.success;
    await notifier.unlock();
    expect(notifier.status, AppLockStatus.unlocked);
  });

  test('terlalu banyak percobaan dan gagal tetap terkunci dengan pesan berbeda', () async {
    authenticator.result = DeviceAuthResult.lockedOut;
    final notifier = build();
    await notifier.init();
    expect(notifier.message, AppLockNotifier.lockedOutText);

    authenticator.result = DeviceAuthResult.failed;
    await notifier.unlock();
    expect(notifier.status, AppLockStatus.locked);
    expect(notifier.message, AppLockNotifier.failedText);
  });

  test('kunci layar HP dihapus: kunci aplikasi dimatikan agar pengguna tidak terkunci permanen', () async {
    authenticator.result = DeviceAuthResult.notAvailable;
    final notifier = build();

    await notifier.init();

    expect(notifier.status, AppLockStatus.unlocked);
    expect(notifier.message, AppLockNotifier.notAvailableText);
    expect(settings.settings.appLockEnabled, isFalse);
  });

  test('terkunci lagi setelah di latar belakang lebih lama dari batas waktu', () async {
    final notifier = build();
    await notifier.init();

    notifier.onBackground();
    now = now.add(const Duration(seconds: 10));
    await notifier.onForeground();
    expect(authenticator.reasons, hasLength(1));

    notifier.onBackground();
    now = now.add(const Duration(minutes: 1));
    authenticator.result = DeviceAuthResult.cancelled;
    await notifier.onForeground();
    expect(authenticator.reasons, hasLength(2));
    expect(notifier.status, AppLockStatus.locked);
  });
}
