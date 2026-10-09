import '../../core/constants/sodium_constants.dart';

enum RiskStatus {
  safe,
  nearLimit,
  danger;

  static RiskStatus fromTotal(double totalSodiumMg) {
    if (totalSodiumMg <= nearLimitThresholdMg) return RiskStatus.safe;
    if (totalSodiumMg <= dailySodiumLimitMg) return RiskStatus.nearLimit;
    return RiskStatus.danger;
  }
}
