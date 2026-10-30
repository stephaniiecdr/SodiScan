class AppSettings {
  const AppSettings({this.appLockEnabled = false, this.sodiumAlertsEnabled = false});

  final bool appLockEnabled;
  final bool sodiumAlertsEnabled;

  AppSettings copyWith({bool? appLockEnabled, bool? sodiumAlertsEnabled}) {
    return AppSettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      sodiumAlertsEnabled: sodiumAlertsEnabled ?? this.sodiumAlertsEnabled,
    );
  }
}

abstract class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
