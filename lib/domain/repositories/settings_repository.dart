class AppSettings {
  const AppSettings({
    this.appLockEnabled = false,
    this.sodiumAlertsEnabled = false,
    this.dailyLimitMg = defaultDailyLimitMg,
  });

  static const int defaultDailyLimitMg = 2000;

  final bool appLockEnabled;
  final bool sodiumAlertsEnabled;

  /// Target natrium harian pilihan pengguna, dalam mg (1000–3000).
  final int dailyLimitMg;

  AppSettings copyWith({bool? appLockEnabled, bool? sodiumAlertsEnabled, int? dailyLimitMg}) {
    return AppSettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      sodiumAlertsEnabled: sodiumAlertsEnabled ?? this.sodiumAlertsEnabled,
      dailyLimitMg: dailyLimitMg ?? this.dailyLimitMg,
    );
  }
}

abstract class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
