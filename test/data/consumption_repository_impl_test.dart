import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/data/datasources/local/consumption_local_data_source.dart';
import 'package:sodiscan/data/repositories/consumption_repository_impl.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';

import '../helpers/fake_consumption_repository.dart';

void main() {
  late Directory tempDir;
  late Box<Map> box;
  late ConsumptionRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sodiscan_hive_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<Map>(ConsumptionLocalDataSource.boxName);
    repository = ConsumptionRepositoryImpl(ConsumptionLocalDataSource(box));
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('menyimpan konsumsi ke Hive dan membacanya kembali per tanggal', () async {
    final yesterday = FoodConsumption(
      id: 'old',
      productName: 'Keripik Kemarin',
      sodiumMg: 300,
      source: ConsumptionSource.manual,
      consumedAt: fixedNow.subtract(const Duration(days: 1)),
    );

    await repository.saveConsumption(indomieConsumption());
    await repository.saveConsumption(yesterday);

    final today = await repository.getConsumptionsByDate(fixedNow);

    expect(box.length, 2);
    expect(today, hasLength(1));
    expect(today.single.productName, 'Indomie Mi Goreng');
    expect(today.single.sodiumMg, 750);
    expect(today.single.barcode, '089686010947');
    expect(today.single.source, ConsumptionSource.scan);
  });

  test('membaca seluruh riwayat konsumsi dari Hive', () async {
    final yesterday = FoodConsumption(
      id: 'old',
      productName: 'Keripik Kemarin',
      sodiumMg: 300,
      source: ConsumptionSource.manual,
      consumedAt: fixedNow.subtract(const Duration(days: 1)),
    );
    await repository.saveConsumption(indomieConsumption());
    await repository.saveConsumption(yesterday);

    final all = await repository.getAllConsumptions();

    expect(all.map((item) => item.id), unorderedEquals(['indomie-1', 'old']));
  });

  test('menghapus konsumsi dari Hive berdasarkan id', () async {
    await repository.saveConsumption(indomieConsumption());

    await repository.deleteConsumption('indomie-1');

    expect(box.isEmpty, isTrue);
    expect(await repository.getAllConsumptions(), isEmpty);
  });

  test('mengubah nama dan sodium konsumsi tanpa mengubah id dan waktu', () async {
    await repository.saveConsumption(indomieConsumption());

    await repository.updateConsumption(indomieConsumption().copyWith(productName: 'Indomie Soto', sodiumMg: 820));

    final updated = (await repository.getAllConsumptions()).single;
    expect(box.length, 1);
    expect(updated.id, 'indomie-1');
    expect(updated.productName, 'Indomie Soto');
    expect(updated.sodiumMg, 820);
    expect(updated.consumedAt, indomieConsumption().consumedAt);
  });

  test('mengubah konsumsi yang tidak ada menghasilkan StorageFailure', () async {
    await expectLater(repository.updateConsumption(indomieConsumption()), throwsA(isA<StorageFailure>()));
    expect(box.isEmpty, isTrue);
  });
}
