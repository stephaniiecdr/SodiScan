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

    final report = await UploadConsumptions(local, server)();

    expect(report.total, 2);
    expect(report.hasFailures, isFalse);
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

  group('Issue #1 upload melanjutkan dan melaporkan catatan yang gagal', () {
    test('satu catatan gagal tidak menghentikan catatan berikutnya', () async {
      final local = FakeConsumptionRepository(items: [
        _item('a', 'Roti', fixedNow),
        _item('b', 'Sosis', fixedNow),
        _item('c', 'Keju', fixedNow),
      ]);
      final server = FakeConsumptionSyncRepository()..failIds = {'b'};

      final report = await UploadConsumptions(local, server)();

      expect(server.uploadCalls, 3);
      expect(server.items.map((item) => item.id), unorderedEquals(['a', 'c']));
      expect(report.total, 3);
      expect(report.successCount, 2);
      expect(report.failed.single.productName, 'Sosis');
    });

    test('semua catatan gagal melempar error pertama agar penyebab terlihat', () async {
      final local = FakeConsumptionRepository(items: [_item('a', 'Roti', fixedNow), _item('b', 'Sosis', fixedNow)]);
      final server = FakeConsumptionSyncRepository()..failWith = const NetworkFailure('offline');

      await expectLater(UploadConsumptions(local, server)(), throwsA(isA<NetworkFailure>()));
      expect(server.uploadCalls, 2);
    });

    test('data lokal kosong menghasilkan laporan 0 tanpa error', () async {
      final report = await UploadConsumptions(FakeConsumptionRepository(), FakeConsumptionSyncRepository())();

      expect(report.total, 0);
      expect(report.hasFailures, isFalse);
    });

    test('mengulang upload setelah server pulih mengirim catatan yang tadinya gagal', () async {
      final local = FakeConsumptionRepository(items: [_item('a', 'Roti', fixedNow), _item('b', 'Sosis', fixedNow)]);
      final server = FakeConsumptionSyncRepository()..failIds = {'b'};

      await UploadConsumptions(local, server)();
      server.failIds = {};
      final retry = await UploadConsumptions(local, server)();

      expect(retry.hasFailures, isFalse);
      expect(server.items.map((item) => item.id), unorderedEquals(['a', 'b']));
    });
  });

  test('RestoreConsumptions gagal tidak mengubah data lokal', () async {
    final local = FakeConsumptionRepository(items: [indomieConsumption()]);
    final server = FakeConsumptionSyncRepository()..failWith = const NetworkFailure('offline');

    await expectLater(RestoreConsumptions(server, local)(), throwsA(isA<NetworkFailure>()));
    expect(local.items.single.sodiumMg, 750);
  });
}
