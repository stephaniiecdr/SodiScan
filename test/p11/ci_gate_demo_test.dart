import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/entities/daily_nutrition.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/entities/risk_status.dart';

import '../helpers/fake_consumption_repository.dart';

/// Demo Pertemuan 11: "unit test failed -> efeknya gimana".
///
/// Normalnya test ini lulus. Jalankan dengan
///   flutter test --dart-define=DEMO_FAIL=true test/p11/ci_gate_demo_test.dart
/// untuk mensimulasikan regresi (catatan tercatat dua kali). Test menjadi merah,
/// dan di GitHub Actions job `build-apk` serta `deploy` otomatis di-skip.
const bool _demoFail = bool.fromEnvironment('DEMO_FAIL');

List<FoodConsumption> _recordedToday() {
  final items = [
    indomieConsumption(),
    FoodConsumption(
      id: 'roti-1',
      productName: 'Roti Tawar',
      sodiumMg: 300,
      source: ConsumptionSource.manual,
      consumedAt: fixedNow,
    ),
  ];
  return _demoFail ? [...items, indomieConsumption()] : items;
}

void main() {
  test('CI gate: total natrium harian = jumlah semua catatan tanpa duplikasi', () {
    final summary = DailyNutrition.fromConsumptions(fixedNow, _recordedToday());

    expect(summary.totalSodiumMg, 1050);
    expect(summary.riskStatus, RiskStatus.safe);
  });
}
