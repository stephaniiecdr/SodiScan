import '../../core/constants/sodium_constants.dart';
import '../../core/logging/app_log.dart';
import '../repositories/settings_repository.dart';

/// Membaca target natrium harian pengguna. Jika pengaturan tidak tersedia atau
/// gagal dibaca, ringkasan tetap tampil memakai batas default 2000 mg.
Future<double> loadDailyLimit(SettingsRepository? settingsRepository) async {
  if (settingsRepository == null) return dailySodiumLimitMg;
  try {
    return (await settingsRepository.load()).dailyLimitMg.toDouble();
  } on Exception catch (error) {
    AppLog.w('Pengaturan', 'Target natrium gagal dibaca, memakai default', error);
    return dailySodiumLimitMg;
  }
}
