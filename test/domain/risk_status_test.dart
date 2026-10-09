import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/entities/risk_status.dart';

void main() {
  test('status aman sampai 1500 mg', () {
    expect(RiskStatus.fromTotal(0), RiskStatus.safe);
    expect(RiskStatus.fromTotal(1500), RiskStatus.safe);
  });

  test('status mendekati batas di atas 1500 mg sampai 2000 mg', () {
    expect(RiskStatus.fromTotal(1501), RiskStatus.nearLimit);
    expect(RiskStatus.fromTotal(2000), RiskStatus.nearLimit);
  });

  test('status bahaya di atas 2000 mg', () {
    expect(RiskStatus.fromTotal(2001), RiskStatus.danger);
  });
}
