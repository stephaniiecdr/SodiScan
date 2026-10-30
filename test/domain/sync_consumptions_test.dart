import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/usecases/sync_consumptions.dart';

import '../helpers/fake_consumption_repository.dart';
import '../helpers/fake_consumption_sync_repository.dart';

FoodConsumption _item(String id, String name, DateTime consumedAt) {
  return FoodConsumption(
    id: id,
    productName: name,
    sodiumMg: 500,
    source: ConsumptionSource.manual,
    consumedAt: consumedAt,
  );
}

void main() {
  test('GetServerConsumptions mengurutkan data server dari yang terbaru', () async {
    final server = FakeConsumptionSyncRepository(items: [
      _item('lama', 'Roti', fixedNow.subtract(const Duration(days: 1))),
      _item('baru', 'Sosis', fixedNow),
    ]);

    final items = await GetServerConsumptions(server)();

    expect(items.map((item) => item.id), ['baru', 'lama']);
  });

  test('UploadConsumptions mengirim semua data lokal tanpa duplikasi di server', () async {
    final local = FakeConsumptionRepository(items: [indomieConsumption(), _item('roti', 'Roti', fixedNow)]);
    final server = FakeConsumptionSyncRepository(items: [indomieConsumption()]);

    final count = await UploadConsumptions(local, server)();

    expect(count, 2);
    expect(server.items.map((item) => item.id), unorderedEquals(['indomie-1', 'roti']));
  });

  test('RestoreConsumptions menyimpan data baru dan memperbarui data yang sudah ada di perangkat', () async {
    final local = FakeConsumptionRepository(items: [indomieConsumption()]);
    final server = FakeConsumptionSyncRepository(items: [
      indomieConsumption().copyWith(sodiumMg: 820),
      _item('roti', 'Roti', fixedNow),
    ]);

    final count = await RestoreConsumptions(server, local)();

    expect(count, 2);
    expect(local.items, hasLength(2));
    expect(local.items.firstWhere((item) => item.id == 'indomie-1').sodiumMg, 820);
  });

  test('RestoreConsumptions gagal tidak mengubah data lokal', () async {
    final local = FakeConsumptionRepository(items: [indomieConsumption()]);
    final server = FakeConsumptionSyncRepository()..failWith = const NetworkFailure('offline');

    await expectLater(RestoreConsumptions(server, local)(), throwsA(isA<NetworkFailure>()));
    expect(local.items.single.sodiumMg, 750);
  });
}
