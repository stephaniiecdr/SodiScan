import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/data/datasources/local/consumption_local_data_source.dart';
import 'package:sodiscan/data/models/food_consumption_model.dart';
import 'package:sodiscan/data/repositories/consumption_repository_impl.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/entities/product.dart';
import 'package:sodiscan/domain/entities/sync_report.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_consumption_history.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/get_product_by_barcode.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/domain/usecases/update_consumption.dart';
import 'package:sodiscan/domain/validation/consumption_rules.dart';
import 'package:sodiscan/domain/validation/product_rules.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/providers/product_lookup_notifier.dart';
import 'package:sodiscan/presentation/providers/server_sync_notifier.dart';

import '../helpers/fake_consumption_repository.dart';
import '../helpers/fake_product_repository.dart';

FoodConsumption _item(String id, String name) {
  return FoodConsumption(
    id: id,
    productName: name,
    sodiumMg: 500,
    source: ConsumptionSource.manual,
    consumedAt: fixedNow,
  );
}

void main() {
  group('Issue #1 pesan hasil "Kirim ke Server"', () {
    test('semua berhasil memakai pesan lama', () {
      expect(ServerSyncNotifier.uploadMessage(const UploadReport(total: 4)), '4 catatan dikirim ke server.');
    });

    test('sebagian gagal menyebut jumlah berhasil, jumlah gagal, dan nama catatan', () {
      final message = ServerSyncNotifier.uploadMessage(UploadReport(total: 3, failed: [_item('b', 'Sosis')]));

      expect(message, contains('2 dari 3 catatan dikirim'));
      expect(message, contains('1 gagal (Sosis)'));
      expect(message, contains('lagi untuk mengulang'));
    });

    test('lebih dari tiga catatan gagal diringkas dengan "dan lainnya"', () {
      final failed = [for (var i = 0; i < 5; i++) _item('$i', 'Item$i')];
      final message = ServerSyncNotifier.uploadMessage(UploadReport(total: 6, failed: failed));

      expect(message, contains('Item0, Item1, Item2, dan lainnya'));
      expect(message, isNot(contains('Item3')));
    });
  });

  group('Issue #2 pesan hasil "Ambil ke HP" dan updatedAt saat edit', () {
    test('tanpa konflik memakai pesan lama', () {
      expect(
        ServerSyncNotifier.restoreMessage(const RestoreReport(added: 1, updated: 2)),
        '3 catatan dari server disimpan ke perangkat.',
      );
    });

    test('konflik menyebut catatan lokal yang dipertahankan', () {
      final message = ServerSyncNotifier.restoreMessage(const RestoreReport(added: 1, keptLocal: 2));

      expect(message, contains('1 catatan dari server disimpan'));
      expect(message, contains('2 catatan lokal yang lebih baru dipertahankan'));
    });

    test('UpdateConsumption mengisi updatedAt dengan waktu edit', () async {
      final editTime = fixedNow.add(const Duration(hours: 1));
      final repository = FakeConsumptionRepository(items: [indomieConsumption()]);

      final updated = await UpdateConsumption(repository, clock: () => editTime)(
        indomieConsumption(),
        productName: 'Indomie Soto',
        sodiumMg: 820,
      );

      expect(updated.updatedAt, editTime);
      expect(repository.items.single.lastModifiedAt, editTime);
      expect(updated.consumedAt, indomieConsumption().consumedAt);
    });

    test('RecordConsumption membuat catatan baru tanpa updatedAt', () async {
      final repository = FakeConsumptionRepository();

      final created = await RecordConsumption(repository, clock: () => fixedNow)(productName: 'Roti', sodiumMg: 200);

      expect(created.updatedAt, isNull);
      expect(created.lastModifiedAt, fixedNow);
    });
  });

  group('Issue #3 porsi/berat ekstrem tidak menghasilkan Infinity', () {
    test('jumlah porsi di atas batas ditolak', () {
      expect(validateAmount('20', ConsumptionUnit.serving), isNull);
      expect(validateAmount('21', ConsumptionUnit.serving), amountTooLargeMessage(ConsumptionUnit.serving));
      expect(validateAmount('1e308', ConsumptionUnit.serving), amountTooLargeMessage(ConsumptionUnit.serving));
    });

    test('berat di atas batas ditolak', () {
      expect(validateAmount('5000', ConsumptionUnit.gram), isNull);
      expect(validateAmount('5000,5', ConsumptionUnit.gram), amountTooLargeMessage(ConsumptionUnit.gram));
    });

    test('pesan batas menyebut satuan yang benar', () {
      expect(amountTooLargeMessage(ConsumptionUnit.serving), 'Jumlah porsi maksimal 20 porsi.');
      expect(amountTooLargeMessage(ConsumptionUnit.gram), 'Berat maksimal 5000 g.');
    });

    test('angka yang tidak terbatas (Infinity) ditolak parser', () {
      expect(validateAmount('1e400', ConsumptionUnit.gram), notNumberMessageFor(ConsumptionUnit.gram));
    });

    test('Product.sodiumFor melempar ValidationFailure jika hasil kali menjadi Infinity', () {
      expect(() => indomieProduct.sodiumFor(1e308), throwsA(isA<ValidationFailure>()));
    });

    test('sodium Infinity ditolak dengan pesan "maksimal", NaN dengan pesan "lebih dari 0"', () {
      expect(sodiumRangeError(double.infinity), sodiumTooLargeMessage);
      expect(sodiumRangeError(double.nan), sodiumNotPositiveMessage);
      expect(sodiumRangeError(double.negativeInfinity), sodiumNotPositiveMessage);
    });

    test('RecordConsumption tidak menyimpan Infinity ke penyimpanan', () async {
      final repository = FakeConsumptionRepository();

      await expectLater(
        RecordConsumption(repository)(productName: 'Garam', sodiumMg: double.infinity),
        throwsA(isA<ValidationFailure>()),
      );
      expect(repository.saveCalls, 0);
    });

    test('ProductLookupNotifier menampilkan pesan error jika porsi membuat sodium terlalu besar', () async {
      final repository = FakeConsumptionRepository();
      final notifier = ProductLookupNotifier(
        getProductByBarcode: GetProductByBarcode(FakeProductRepository(product: indomieProduct)),
        recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
      );
      await notifier.search(indomieProduct.barcode);

      final ok = await notifier.submit(20);

      expect(ok, isFalse);
      expect(notifier.state.submitErrorMessage, sodiumTooLargeMessage);
      expect(repository.items, isEmpty);
    });
  });

  group('Issue #4 hapus gagal menyimpan pesan error di state', () {
    AddConsumptionNotifier buildNotifier(FakeConsumptionRepository repository) {
      return AddConsumptionNotifier(
        getDailySummary: GetDailySummary(repository),
        recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
        updateConsumption: UpdateConsumption(repository),
        deleteConsumption: DeleteConsumption(repository),
        clock: () => fixedNow,
      );
    }

    test('gagal hapus: return false, pesan error tersimpan, data tetap ada', () async {
      final repository = FakeConsumptionRepository(items: [indomieConsumption()])..failDelete = true;
      final notifier = buildNotifier(repository);
      await notifier.load();

      final deleted = await notifier.delete('indomie-1');

      expect(deleted, isFalse);
      expect(notifier.state.deleteErrorMessage, AddConsumptionNotifier.deleteErrorText);
      expect(notifier.state.isDeleting, isFalse);
      expect(repository.items, hasLength(1));
    });

    test('hapus berhasil membersihkan pesan error sebelumnya', () async {
      final repository = FakeConsumptionRepository(items: [indomieConsumption()])..failDelete = true;
      final notifier = buildNotifier(repository);
      await notifier.delete('indomie-1');

      repository.failDelete = false;
      final deleted = await notifier.delete('indomie-1');

      expect(deleted, isTrue);
      expect(notifier.state.deleteErrorMessage, isNull);
      expect(repository.items, isEmpty);
    });

    test('clearDeleteError menghapus pesan setelah ditampilkan', () async {
      final repository = FakeConsumptionRepository(items: [indomieConsumption()])..failDelete = true;
      final notifier = buildNotifier(repository);
      await notifier.delete('indomie-1');

      notifier.clearDeleteError();

      expect(notifier.state.deleteErrorMessage, isNull);
    });

    test('hapus ganda saat proses berjalan diabaikan', () async {
      final gate = Completer<void>();
      final repository = _GatedDeleteRepository(gate, items: [indomieConsumption()]);
      final notifier = buildNotifier(repository);

      final first = notifier.delete('indomie-1');
      expect(notifier.state.deletingId, 'indomie-1');
      final second = await notifier.delete('indomie-1');
      gate.complete();

      expect(second, isFalse);
      expect(await first, isTrue);
      expect(repository.deleteCalls, 1);
    });
  });

  group('Issue #5 riwayat dikelompokkan menurut zona waktu lokal', () {
    test('data UTC dikelompokkan ke tanggal lokal yang sama dengan waktunya', () async {
      final utcTime = DateTime.utc(2026, 10, 1, 23, 30);
      final repository = FakeConsumptionRepository(items: [
        FoodConsumption(
          id: 'utc',
          productName: 'Bakso',
          sodiumMg: 800,
          source: ConsumptionSource.manual,
          consumedAt: utcTime,
        ),
      ]);

      final days = await GetConsumptionHistory(repository)();
      final local = utcTime.toLocal();

      expect(days.single.date, DateTime(local.year, local.month, local.day));
    });

    test('data dari server dengan akhiran Z disimpan sebagai waktu lokal', () {
      final model = FoodConsumptionModel.fromJson({
        'id': 'x',
        'productName': 'Bakso',
        'sodiumMg': 800,
        'source': 'manual',
        'consumedAt': '2026-10-01T23:30:00.000Z',
      });

      expect(model.consumedAt.isUtc, isFalse);
      expect(model.toEntity().consumedAt, DateTime.utc(2026, 10, 1, 23, 30).toLocal());
    });
  });

  group('Issue #11 satu catatan Hive rusak tidak merusak seluruh riwayat', () {
    late Directory tempDir;
    late Box<Map> box;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sodiscan_corrupt_test');
      Hive.init(tempDir.path);
      box = await Hive.openBox<Map>(ConsumptionLocalDataSource.boxName);
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('catatan tanpa field wajib dilewati, catatan lain tetap dimuat', () async {
      final repository = ConsumptionRepositoryImpl(ConsumptionLocalDataSource(box));
      await repository.saveConsumption(indomieConsumption());
      await box.put('rusak', {'id': 'rusak', 'productName': 'Tanpa sodium'});

      final all = await repository.getAllConsumptions();

      expect(all.map((item) => item.id), ['indomie-1']);
    });

    test('catatan dengan tanggal tidak valid dilewati', () async {
      final repository = ConsumptionRepositoryImpl(ConsumptionLocalDataSource(box));
      await repository.saveConsumption(indomieConsumption());
      await box.put('tanggal', {
        'id': 'tanggal',
        'productName': 'Roti',
        'sodiumMg': 100,
        'source': 'manual',
        'consumedAt': 'kemarin',
      });

      final today = await repository.getConsumptionsByDate(fixedNow);

      expect(today.single.id, 'indomie-1');
    });

    test('box yang seluruhnya rusak menghasilkan daftar kosong, bukan error', () async {
      await box.put('a', {'id': 1});
      await box.put('b', {'sodiumMg': 'banyak'});

      expect(ConsumptionLocalDataSource(box).getAll(), isEmpty);
    });
  });

  group('Issue #12 nama makanan dibatasi 80 karakter', () {
    test('nama tepat 80 karakter diterima, 81 karakter ditolak', () {
      expect(validateProductName('a' * 80), isNull);
      expect(validateProductName('a' * 81), productNameTooLongMessage);
    });

    test('spasi di awal/akhir tidak dihitung', () {
      expect(validateProductName('  ${'a' * 80}  '), isNull);
    });

    test('validateConsumptionInput melempar ValidationFailure untuk nama terlalu panjang', () {
      expect(
        () => validateConsumptionInput(productName: 'a' * 81, sodiumMg: 100),
        throwsA(isA<ValidationFailure>().having((f) => f.message, 'message', productNameTooLongMessage)),
      );
    });

    test('clampProductName memotong nama produk panjang menjadi 80 karakter', () {
      expect(clampProductName('a' * 120), hasLength(80));
      expect(clampProductName('  Indomie  '), 'Indomie');
    });

    test('produk hasil scan dengan nama sangat panjang tetap bisa disimpan', () async {
      final repository = FakeConsumptionRepository();
      final longProduct = Product(
        barcode: indomieProduct.barcode,
        name: 'Mi Instan ${'Rasa Spesial ' * 10}',
        sodiumPerServingMg: 750,
      );
      final notifier = ProductLookupNotifier(
        getProductByBarcode: GetProductByBarcode(FakeProductRepository(product: longProduct)),
        recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
      );
      await notifier.search(longProduct.barcode);

      expect(await notifier.submit(1), isTrue);
      expect(repository.items.single.productName.length, lessThanOrEqualTo(maxProductNameLength));
    });
  });
}

String notNumberMessageFor(ConsumptionUnit unit) => '${amountLabel(unit)} harus berupa angka.';

class _GatedDeleteRepository extends FakeConsumptionRepository {
  _GatedDeleteRepository(this.gate, {super.items});

  final Completer<void> gate;
  int deleteCalls = 0;

  @override
  Future<void> deleteConsumption(String id) async {
    deleteCalls++;
    await gate.future;
    await super.deleteConsumption(id);
  }
}
