import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/daily_nutrition.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/entities/risk_status.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';

import '../helpers/fake_consumption_repository.dart';
import '../helpers/fake_product_repository.dart';

FoodConsumption _consumption(String id, double sodiumMg) {
  return FoodConsumption(
    id: id,
    productName: 'Makanan $id',
    sodiumMg: sodiumMg,
    source: ConsumptionSource.manual,
    consumedAt: fixedNow,
  );
}

DailyNutrition _summaryOf(List<double> sodiumValues) {
  final items = [for (var i = 0; i < sodiumValues.length; i++) _consumption('item-$i', sodiumValues[i])];
  return DailyNutrition.fromConsumptions(fixedNow, items);
}

void main() {
  group('BR2 - Product.sodiumFor', () {
    test('menolak jumlah nol, negatif, dan tidak berhingga', () {
      for (final amount in [0.0, -1.0, double.nan, double.infinity]) {
        expect(() => indomieProduct.sodiumFor(amount), throwsA(isA<ValidationFailure>()));
        expect(() => chitatoProduct.sodiumFor(amount), throwsA(isA<ValidationFailure>()));
      }
    });

    test('produk tanpa data natrium menghasilkan 0 untuk jumlah valid', () {
      expect(noSodiumProduct.sodiumFor(1), 0);
    });
  });

  group('BR3 - RecordConsumption batas maksimal per catatan', () {
    test('menerima natrium tepat 10000 mg', () async {
      final repository = FakeConsumptionRepository();

      final saved = await RecordConsumption(repository, clock: () => fixedNow)(productName: 'Garam', sodiumMg: 10000);

      expect(saved.sodiumMg, 10000);
      expect(repository.items, hasLength(1));
    });

    test('menolak natrium di atas 10000 mg tanpa menyimpan', () async {
      final repository = FakeConsumptionRepository();
      final recordConsumption = RecordConsumption(repository, clock: () => fixedNow);

      await expectLater(
        recordConsumption(productName: 'Salah Ketik', sodiumMg: 10001),
        throwsA(isA<ValidationFailure>().having((f) => f.message, 'message', contains('10000 mg'))),
      );
      expect(repository.saveCalls, 0);
    });

    test('menyimpan barcode dan sumber scan', () async {
      final repository = FakeConsumptionRepository();

      final saved = await RecordConsumption(repository, clock: () => fixedNow)(
        productName: indomieProduct.name,
        sodiumMg: indomieProduct.sodiumFor(2),
        source: ConsumptionSource.scan,
        barcode: indomieProduct.barcode,
      );

      expect(saved.sodiumMg, 1500);
      expect(saved.source, ConsumptionSource.scan);
      expect(saved.barcode, indomieProduct.barcode);
      expect(saved.id, fixedNow.microsecondsSinceEpoch.toString());
    });
  });

  group('BR4 - RiskStatus batas tepat', () {
    test('1500 Aman, 1500.1 Mendekati Batas, 2000 Mendekati Batas, 2000.1 Bahaya', () {
      expect(RiskStatus.fromTotal(0), RiskStatus.safe);
      expect(RiskStatus.fromTotal(1500), RiskStatus.safe);
      expect(RiskStatus.fromTotal(1500.1), RiskStatus.nearLimit);
      expect(RiskStatus.fromTotal(2000), RiskStatus.nearLimit);
      expect(RiskStatus.fromTotal(2000.1), RiskStatus.danger);
    });
  });

  group('BR5 - DailyNutrition sisa, kelebihan, dan progres', () {
    test('hari kosong: sisa 2000 mg, progres 0, tidak melebihi batas', () {
      final summary = _summaryOf([]);

      expect(summary.totalSodiumMg, 0);
      expect(summary.remainingMg, 2000);
      expect(summary.exceededMg, 0);
      expect(summary.progress, 0);
      expect(summary.isOverLimit, isFalse);
      expect(summary.riskStatus, RiskStatus.safe);
    });

    test('di bawah batas: sisa dan progres dihitung dari total', () {
      final summary = _summaryOf([750, 900]);

      expect(summary.totalSodiumMg, 1650);
      expect(summary.remainingMg, 350);
      expect(summary.exceededMg, 0);
      expect(summary.progress, closeTo(0.825, 1e-9));
      expect(summary.riskStatus, RiskStatus.nearLimit);
    });

    test('tepat di batas: sisa 0, belum melebihi batas, progres 1', () {
      final summary = _summaryOf([2000]);

      expect(summary.remainingMg, 0);
      expect(summary.exceededMg, 0);
      expect(summary.progress, 1);
      expect(summary.isOverLimit, isFalse);
    });

    test('melebihi batas: sisa tidak negatif dan progres dibatasi 1', () {
      final summary = _summaryOf([1500, 800]);

      expect(summary.isOverLimit, isTrue);
      expect(summary.remainingMg, 0);
      expect(summary.exceededMg, 300);
      expect(summary.progress, 1);
      expect(summary.riskStatus, RiskStatus.danger);
    });

    test('tanggal dinormalisasi ke awal hari', () {
      expect(_summaryOf([100]).date, DateTime(2026, 10, 1));
    });
  });
}
