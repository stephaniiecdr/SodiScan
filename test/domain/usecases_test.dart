import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/entities/risk_status.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';

import '../helpers/fake_consumption_repository.dart';

void main() {
  group('RecordConsumption', () {
    test('menyimpan konsumsi manual dengan nama yang sudah di-trim', () async {
      final repository = FakeConsumptionRepository();
      final recordConsumption = RecordConsumption(repository, clock: () => fixedNow);

      final saved = await recordConsumption(productName: '  Indomie Mi Goreng  ', sodiumMg: 750);

      expect(repository.items, hasLength(1));
      expect(saved.productName, 'Indomie Mi Goreng');
      expect(saved.sodiumMg, 750);
      expect(saved.source, ConsumptionSource.manual);
      expect(saved.consumedAt, fixedNow);
    });

    test('menolak sodium nol, negatif, dan bukan angka berhingga tanpa menyimpan', () async {
      final repository = FakeConsumptionRepository();
      final recordConsumption = RecordConsumption(repository, clock: () => fixedNow);

      for (final sodium in [0.0, -10.0, double.nan, double.infinity]) {
        await expectLater(
          recordConsumption(productName: 'Indomie', sodiumMg: sodium),
          throwsA(isA<ValidationFailure>()),
        );
      }
      expect(repository.saveCalls, 0);
    });

    test('menolak nama makanan kosong', () async {
      final recordConsumption = RecordConsumption(FakeConsumptionRepository(), clock: () => fixedNow);

      await expectLater(recordConsumption(productName: '   ', sodiumMg: 100), throwsA(isA<ValidationFailure>()));
    });
  });

  group('GetDailySummary', () {
    test('menjumlahkan sodium hari ini saja dan menentukan status risiko', () async {
      final yesterday = FoodConsumption(
        id: 'old',
        productName: 'Keripik Kemarin',
        sodiumMg: 900,
        source: ConsumptionSource.manual,
        consumedAt: fixedNow.subtract(const Duration(days: 1)),
      );
      final snack = FoodConsumption(
        id: 'snack',
        productName: 'Chitato Sapi Panggang',
        sodiumMg: 900,
        source: ConsumptionSource.manual,
        consumedAt: fixedNow,
      );
      final repository = FakeConsumptionRepository(items: [yesterday, indomieConsumption(), snack]);

      final summary = await GetDailySummary(repository)(fixedNow);

      expect(summary.totalSodiumMg, 1650);
      expect(summary.dailyLimitMg, 2000);
      expect(summary.riskStatus, RiskStatus.nearLimit);
      expect(summary.consumptions.map((item) => item.id), ['snack', 'indomie-1']);
    });
  });
}
