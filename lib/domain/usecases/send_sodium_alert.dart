import '../../core/utils/sodium_format.dart';
import '../entities/daily_nutrition.dart';
import '../entities/risk_status.dart';
import '../repositories/settings_repository.dart';
import '../services/notification_service.dart';

class SendSodiumAlert {
  const SendSodiumAlert(this._settingsRepository, this._notificationService);

  final SettingsRepository _settingsRepository;
  final NotificationService _notificationService;

  Future<bool> call({required DailyNutrition? previous, required DailyNutrition current}) async {
    if (!shouldAlert(previous, current)) return false;
    final settings = await _settingsRepository.load();
    if (!settings.sodiumAlertsEnabled) return false;

    final total = formatSodiumMg(current.totalSodiumMg);
    final limit = formatSodiumMg(current.dailyLimitMg);
    if (current.riskStatus == RiskStatus.danger) {
      await _notificationService.showSodiumAlert(
        title: 'Natrium hari ini melebihi batas',
        body: 'Total $total, lebih ${formatSodiumMg(current.exceededMg)} dari batas $limit.',
      );
    } else {
      await _notificationService.showSodiumAlert(
        title: 'Natrium hari ini mendekati batas',
        body: 'Total $total dari batas $limit. Sisa ${formatSodiumMg(current.remainingMg)}.',
      );
    }
    return true;
  }

  static bool shouldAlert(DailyNutrition? previous, DailyNutrition current) {
    if (previous == null || previous.date != current.date) return false;
    if (current.riskStatus == RiskStatus.safe) return false;
    return current.riskStatus.index > previous.riskStatus.index;
  }
}
