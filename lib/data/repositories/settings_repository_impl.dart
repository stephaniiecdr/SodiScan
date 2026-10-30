import 'package:hive/hive.dart';

import '../../core/errors/failures.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._box);

  static const String boxName = 'settings';
  static const String _appLockKey = 'appLockEnabled';
  static const String _sodiumAlertsKey = 'sodiumAlertsEnabled';

  final Box<dynamic> _box;

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      appLockEnabled: _box.get(_appLockKey, defaultValue: false) as bool,
      sodiumAlertsEnabled: _box.get(_sodiumAlertsKey, defaultValue: false) as bool,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    try {
      await _box.putAll({_appLockKey: settings.appLockEnabled, _sodiumAlertsKey: settings.sodiumAlertsEnabled});
    } catch (error) {
      throw StorageFailure('Gagal menyimpan pengaturan: $error');
    }
  }
}
