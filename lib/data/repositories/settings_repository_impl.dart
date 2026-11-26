import 'package:hive/hive.dart';

import '../../core/constants/sodium_constants.dart';
import '../../domain/repositories/settings_repository.dart';
import 'repository_guard.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._box);

  static const String boxName = 'settings';
  static const String _appLockKey = 'appLockEnabled';
  static const String _sodiumAlertsKey = 'sodiumAlertsEnabled';
  static const String _dailyLimitKey = 'dailyLimitMg';

  final Box<dynamic> _box;

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      appLockEnabled: _box.get(_appLockKey, defaultValue: false) as bool,
      sodiumAlertsEnabled: _box.get(_sodiumAlertsKey, defaultValue: false) as bool,
      dailyLimitMg: _readDailyLimit(),
    );
  }

  @override
  Future<void> save(AppSettings settings) {
    return guardStorage(
      'menyimpan pengaturan',
      () => _box.putAll({
        _appLockKey: settings.appLockEnabled,
        _sodiumAlertsKey: settings.sodiumAlertsEnabled,
        _dailyLimitKey: settings.dailyLimitMg,
      }),
    );
  }

  /// Nilai yang hilang atau di luar rentang (mis. data lama/rusak) kembali ke default 2000 mg.
  int _readDailyLimit() {
    final value = _box.get(_dailyLimitKey);
    if (value is int && value >= minDailyLimitMg && value <= maxDailyLimitMg) return value;
    return AppSettings.defaultDailyLimitMg;
  }
}
