import 'package:flutter/foundation.dart';

import '../../core/utils/sodium_format.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/validation/settings_rules.dart';
import '../../domain/services/device_authenticator.dart';
import '../../domain/services/notification_service.dart';
import 'base_notifier.dart';

class SettingsNotifier extends ChangeNotifier with SafeNotifier {
  SettingsNotifier({
    required SettingsRepository settingsRepository,
    required DeviceAuthenticator authenticator,
    required NotificationService notificationService,
  })  : _settingsRepository = settingsRepository,
        _authenticator = authenticator,
        _notificationService = notificationService;

  static const String loadErrorText = 'Pengaturan tidak dapat dimuat.';
  static const String saveErrorText = 'Pengaturan gagal disimpan. Silakan coba lagi.';
  static const String notificationDeniedText =
      'Izin notifikasi ditolak. Aktifkan lewat Pengaturan HP > Aplikasi > SodiScan > Notifikasi.';
  static const String notificationOnText = 'Peringatan natrium aktif.';
  static const String notificationOffText = 'Peringatan natrium dimatikan.';
  static const String lockOnText = 'Kunci aplikasi aktif.';
  static const String lockOffText = 'Kunci aplikasi dimatikan.';
  static const String lockCancelledText = 'Dibatalkan. Pengaturan kunci tidak berubah.';
  static const String lockUnavailableText = 'Atur PIN, pola, atau sidik jari di HP terlebih dulu.';
  static const String lockLockedOutText = 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
  static const String lockFailedText = 'Autentikasi gagal. Pengaturan kunci tidak berubah.';

  final SettingsRepository _settingsRepository;
  final DeviceAuthenticator _authenticator;
  final NotificationService _notificationService;

  AppSettings? _settings;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifySafely();
    try {
      _settings = await _settingsRepository.load();
    } on Exception {
      _errorMessage = loadErrorText;
    }
    _isLoading = false;
    notifySafely();
  }

  Future<String?> setSodiumAlerts(bool enabled) {
    return _change(() async {
      if (enabled && !await _notificationService.requestPermission()) return (null, notificationDeniedText);
      return (_settings!.copyWith(sodiumAlertsEnabled: enabled), enabled ? notificationOnText : notificationOffText);
    });
  }

  static String dailyLimitSavedText(int limitMg) => 'Target natrium harian diatur ke ${formatSodiumMg(limitMg.toDouble())}.';

  Future<String?> setDailyLimit(int limitMg) {
    return _change(() async {
      if (!isValidDailyLimit(limitMg)) return (null, dailyLimitRangeMessage);
      if (limitMg == _settings!.dailyLimitMg) return (null, dailyLimitSavedText(limitMg));
      return (_settings!.copyWith(dailyLimitMg: limitMg), dailyLimitSavedText(limitMg));
    });
  }

  Future<String?> setAppLock(bool enabled) {
    return _change(() async {
      final reason = enabled ? 'Konfirmasi untuk mengaktifkan kunci aplikasi' : 'Konfirmasi untuk mematikan kunci aplikasi';
      final result = await _authenticator.authenticate(reason);
      return switch (result) {
        DeviceAuthResult.success => (
            _settings!.copyWith(appLockEnabled: enabled),
            enabled ? lockOnText : lockOffText,
          ),
        DeviceAuthResult.cancelled => (null, lockCancelledText),
        DeviceAuthResult.notAvailable => (null, lockUnavailableText),
        DeviceAuthResult.lockedOut => (null, lockLockedOutText),
        DeviceAuthResult.failed => (null, lockFailedText),
      };
    });
  }

  Future<String?> _change(Future<(AppSettings?, String)> Function() action) async {
    if (_isBusy || _settings == null) return null;
    _isBusy = true;
    notifySafely();
    try {
      final (updated, message) = await action();
      if (updated != null) {
        await _settingsRepository.save(updated);
        _settings = updated;
      }
      return message;
    } on Exception {
      return saveErrorText;
    } finally {
      _isBusy = false;
      notifySafely();
    }
  }
}
