import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/entities/risk_status.dart';
import 'package:sodiscan/domain/usecases/get_consumption_history.dart';

import '../helpers/fake_consumption_repository.dart';

FoodConsumption _item(String id, double sodiumMg, DateTime consumedAt) {
  return FoodConsumption(
    id: id,
    productName: 'Produk $id',
    sodiumMg: sodiumMg,
    source: ConsumptionSource.manual,
    consumedAt: consumedAt,
  );
}

void main() {
  test('mengelompokkan konsumsi per tanggal dengan tanggal terbaru di atas', () async {
    final repository = FakeConsumptionRepository(items: [
      _item('a', 500, DateTime(2026, 9, 29, 8)),
      _item('b', 900, DateTime(2026, 10, 1, 7)),
      _item('c', 700, DateTime(2026, 10, 1, 19)),
      _item('d', 2100, DateTime(2026, 9, 30, 12)),
    ]);

    final days = await GetConsumptionHistory(repository)();

    expect(days.map((day) => day.date), [DateTime(2026, 10, 1), DateTime(2026, 9, 30), DateTime(2026, 9, 29)]);
    expect(days.map((day) => day.totalSodiumMg), [1600, 2100, 500]);
    expect(days.map((day) => day.riskStatus), [RiskStatus.nearLimit, RiskStatus.danger, RiskStatus.safe]);
  });

  test('konsumsi di dalam satu tanggal diurutkan dari yang terbaru', () async {
    final repository = FakeConsumptionRepository(items: [
      _item('pagi', 100, DateTime(2026, 10, 1, 7)),
      _item('malam', 200, DateTime(2026, 10, 1, 21)),
    ]);

    final days = await GetConsumptionHistory(repository)();

    expect(days.single.consumptions.map((item) => item.id), ['malam', 'pagi']);
  });

  test('menghasilkan list kosong jika belum ada konsumsi', () async {
    expect(await GetConsumptionHistory(FakeConsumptionRepository())(), isEmpty);
  });
}
