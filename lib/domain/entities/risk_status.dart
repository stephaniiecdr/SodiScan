import '../../core/constants/sodium_constants.dart';

enum RiskStatus {
  safe,
  nearLimit,
  danger;

  static RiskStatus fromTotal(double totalSodiumMg, {double limitMg = dailySodiumLimitMg}) {
    if (totalSodiumMg <= limitMg * nearLimitRatio) return RiskStatus.safe;
    if (totalSodiumMg <= limitMg) return RiskStatus.nearLimit;
    return RiskStatus.danger;
  }
}
