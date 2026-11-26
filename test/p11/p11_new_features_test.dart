import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/data/datasources/local/consumption_local_data_source.dart';
import 'package:sodiscan/data/datasources/remote/consumption_remote_data_source.dart';
import 'package:sodiscan/data/repositories/consumption_repository_impl.dart';
import 'package:sodiscan/data/repositories/consumption_sync_repository_impl.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/entities/sync_report.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/sync_consumptions.dart';
import 'package:sodiscan/presentation/providers/server_sync_notifier.dart';

import '../helpers/fake_consumption_repository.dart';
import '../helpers/fake_consumption_sync_repository.dart';

FoodConsumption _item(String id, String name, {double sodium = 500, DateTime? at}) {
  return FoodConsumption(
    id: id,
    productName: name,
    sodiumMg: sodium,
    source: ConsumptionSource.manual,
    consumedAt: at ?? fixedNow,
  );
}

void main() {
  group('Bug #18 catatan yang dihapus muncul lagi setelah "Ambil ke HP"', () {
    test('menghapus catatan menyimpan tombstone', () async {
      final repository = FakeConsumptionRepository(items: [indomieConsumption()]);

      await DeleteConsumption(repository)('indomie-1');

      expect(await repository.getDeletedIds(), {'indomie-1'});
    });

    test('"Ambil ke HP" tidak mengembalikan catatan yang sudah dihapus', () async {
      final local = FakeConsumptionRepository(items: [indomieConsumption(), _item('roti', 'Roti')]);
      final server = FakeConsumptionSyncRepository(items: [indomieConsumption(), _item('roti', 'Roti')]);
      await local.deleteConsumption('indomie-1');

      final report = await RestoreConsumptions(server, local)();

      expect(report.skippedDeleted, 1);
      expect(local.items.map((item) => item.id), ['roti']);
    });

    test('"Kirim ke Server" ikut menghapus catatan di server lalu melupakan tombstone', () async {
      final local = FakeConsumptionRepository(items: [indomieConsumption(), _item('roti', 'Roti')]);
      final server = FakeConsumptionSyncRepository(items: [indomieConsumption(), _item('roti', 'Roti')]);
      await local.deleteConsumption('indomie-1');

      final report = await UploadConsumptions(local, server)();

      expect(report.deleted, 1);
      expect(server.items.map((item) => item.id), ['roti']);
      expect(await local.getDeletedIds(), isEmpty);
    });

    test('hapus di server gagal: tombstone tetap ada untuk dicoba lagi', () async {
      final local = FakeConsumptionRepository(items: [_item('roti', 'Roti')]);
      final server = FakeConsumptionSyncRepository(items: [indomieConsumption()])..failDeleteIds = {'indomie-1'};
      local.deletedIds.add('indomie-1');

      final report = await UploadConsumptions(local, server)();

      expect(report.failedDeletes, 1);
      expect(report.hasFailures, isTrue);
      expect(await local.getDeletedIds(), {'indomie-1'});
    });

    test('hanya ada penghapusan dan semuanya gagal: error dilempar agar penyebab terlihat', () async {
      final local = FakeConsumptionRepository()..deletedIds.add('indomie-1');
      final server = FakeConsumptionSyncRepository()..failWith = const NetworkFailure('offline');

      await expectLater(UploadConsumptions(local, server)(), throwsA(isA<NetworkFailure>()));
    });

    test('pesan upload menyebut catatan yang ikut dihapus di server', () {
      expect(
        ServerSyncNotifier.uploadMessage(const UploadReport(total: 2, deleted: 1)),
        '2 catatan dikirim ke server. 1 catatan yang dihapus juga dihapus dari server.',
      );
      expect(
        ServerSyncNotifier.uploadMessage(const UploadReport(total: 2, failedDeletes: 1)),
        contains('1 penghapusan belum terkirim'),
      );
    });

    test('pesan restore menyebut catatan terhapus yang tidak dikembalikan', () {
      expect(
        ServerSyncNotifier.restoreMessage(const RestoreReport(added: 1, skippedDeleted: 2)),
        '1 catatan dari server disimpan ke perangkat. 2 catatan yang sudah Anda hapus tidak dikembalikan.',
      );
    });

    group('Hive', () {
      late Directory tempDir;

      Future<ConsumptionRepositoryImpl> open() async {
        Hive.init(tempDir.path);
        final box = await Hive.openBox<Map>(ConsumptionLocalDataSource.boxName);
        final deletedBox = await Hive.openBox<dynamic>(ConsumptionLocalDataSource.deletedBoxName);
        return ConsumptionRepositoryImpl(ConsumptionLocalDataSource(box, deletedBox: deletedBox));
      }

      setUp(() async => tempDir = await Directory.systemTemp.createTemp('sodiscan_tombstone_test'));

      tearDown(() async {
        await Hive.close();
        await tempDir.delete(recursive: true);
      });

      test('tombstone tetap ada setelah aplikasi ditutup dan dibuka kembali', () async {
        var repository = await open();
        await repository.saveConsumption(indomieConsumption());
        await repository.deleteConsumption('indomie-1');
        await Hive.close();

        repository = await open();

        expect(await repository.getAllConsumptions(), isEmpty);
        expect(await repository.getDeletedIds(), {'indomie-1'});
      });

      test('forgetDeleted dan menyimpan ulang id yang sama menghapus tombstone', () async {
        final repository = await open();
        await repository.saveConsumption(indomieConsumption());
        await repository.deleteConsumption('indomie-1');
        await repository.saveConsumption(indomieConsumption());
        expect(await repository.getDeletedIds(), isEmpty);

        await repository.deleteConsumption('indomie-1');
        await repository.forgetDeleted('indomie-1');
        expect(await repository.getDeletedIds(), isEmpty);
      });
    });

    group('API DELETE', () {
      ConsumptionSyncRepositoryImpl repositoryResponding(int status, List<http.Request> requests) {
        return ConsumptionSyncRepositoryImpl(
          ConsumptionRemoteDataSource(
            MockClient((request) async {
              requests.add(request);
              return http.Response('', status);
            }),
            baseUrl: 'http://localhost:8080',
          ),
        );
      }

      test('204 berhasil dan memanggil endpoint yang benar', () async {
        final requests = <http.Request>[];

        await repositoryResponding(204, requests).deleteFromServer('indomie-1');

        expect(requests.single.method, 'DELETE');
        expect(requests.single.url.toString(), 'http://localhost:8080/api/consumptions/indomie-1');
      });

      test('404 dianggap berhasil karena data sudah tidak ada di server', () async {
        await repositoryResponding(404, []).deleteFromServer('indomie-1');
      });

      test('500 menjadi NetworkFailure', () async {
        await expectLater(repositoryResponding(500, []).deleteFromServer('indomie-1'), throwsA(isA<NetworkFailure>()));
      });
    });
  });
}
