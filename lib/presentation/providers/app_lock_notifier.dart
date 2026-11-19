import 'package:flutter/foundation.dart';

import '../../core/logging/app_log.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/device_authenticator.dart';
import 'base_notifier.dart';

enum AppLockStatus { checking, locked, authenticating, unlocked }

class AppLockNotifier extends ChangeNotifier with SafeNotifier {
  AppLockNotifier({
    required SettingsRepository settingsRepository,
    required DeviceAuthenticator authenticator,
    this.relockAfter = const Duration(seconds: 30),
    DateTime Function()? clock,
  })  : _settingsRepository = settingsRepository,
        _authenticator = authenticator,
        _clock = clock ?? DateTime.now;

  static const String unlockReason = 'Buka kunci SodiScan untuk melihat catatan natrium Anda';
  static const String cancelledText = 'Autentikasi dibatalkan. Tekan Buka Kunci untuk mencoba lagi.';
  static const String failedText = 'Autentikasi gagal. Silakan coba lagi.';
  static const String lockedOutText = 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
  static const String notAvailableText =
      'Kunci layar HP tidak aktif, jadi kunci aplikasi dimatikan. Aktifkan lagi di Pengaturan setelah mengatur PIN/sidik jari.';

  final SettingsRepository _settingsRepository;
  final DeviceAuthenticator _authenticator;
  final Duration relockAfter;
  final DateTime Function() _clock;

  AppLockStatus _status = AppLockStatus.checking;
  String? _message;
  DateTime? _backgroundedAt;

  AppLockStatus get status => _status;
  String? get message => _message;
  bool get isUnlocked => _status == AppLockStatus.unlocked;

  Future<void> init() async {
    final settings = await _loadSettings();
    if (!settings.appLockEnabled) {
      _set(AppLockStatus.unlocked);
      return;
    }
    _set(AppLockStatus.locked);
    await unlock();
  }

  Future<void> unlock() async {
    if (_status == AppLockStatus.authenticating || _status == AppLockStatus.unlocked) return;
    _set(AppLockStatus.authenticating);

    final result = await _authenticator.authenticate(unlockReason);
    AppLog.i('KunciAplikasi', 'Hasil autentikasi: ${result.name}');
    switch (result) {
      case DeviceAuthResult.success:
        _set(AppLockStatus.unlocked);
      case DeviceAuthResult.notAvailable:
        final settings = await _loadSettings();
        await _settingsRepository.save(settings.copyWith(appLockEnabled: false));
        _set(AppLockStatus.unlocked, message: notAvailableText);
      case DeviceAuthResult.cancelled:
        _set(AppLockStatus.locked, message: cancelledText);
      case DeviceAuthResult.lockedOut:
        _set(AppLockStatus.locked, message: lockedOutText);
      case DeviceAuthResult.failed:
        _set(AppLockStatus.locked, message: failedText);
    }
  }

  void onBackground() {
    if (_status == AppLockStatus.unlocked) _backgroundedAt = _clock();
  }

  Future<void> onForeground() async {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null || _status != AppLockStatus.unlocked) return;
    if (_clock().difference(since) < relockAfter) return;

    final settings = await _loadSettings();
    if (!settings.appLockEnabled) return;
    _set(AppLockStatus.locked);
    await unlock();
  }

  void clearMessage() {
    if (_message == null) return;
    _message = null;
    notifySafely();
  }

  Future<AppSettings> _loadSettings() async {
    try {
      return await _settingsRepository.load();
    } on Exception catch (error) {
      AppLog.w('KunciAplikasi', 'Pengaturan gagal dibaca, memakai nilai bawaan', error);
      return const AppSettings();
    }
  }

  void _set(AppLockStatus status, {String? message}) {
    if (isDisposed) return;
    _status = status;
    _message = message;
    notifyListeners();
  }
}
