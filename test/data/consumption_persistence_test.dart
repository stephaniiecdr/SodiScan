import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sodiscan/data/datasources/local/consumption_local_data_source.dart';
import 'package:sodiscan/data/repositories/consumption_repository_impl.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';

import '../helpers/fake_consumption_repository.dart';

void main() {
  late Directory tempDir;

  Future<ConsumptionRepositoryImpl> openApp() async {
    Hive.init(tempDir.path);
    final box = await Hive.openBox<Map>(ConsumptionLocalDataSource.boxName);
    return ConsumptionRepositoryImpl(ConsumptionLocalDataSource(box));
  }

  Future<void> closeApp() => Hive.close();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sodiscan_persistence_test');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('Create: data tetap ada setelah aplikasi ditutup dan dibuka kembali', () async {
    var repository = await openApp();
    await repository.saveConsumption(indomieConsumption());
    await closeApp();

    repository = await openApp();
    final all = await repository.getAllConsumptions();

    expect(all, hasLength(1));
    expect(all.single.id, 'indomie-1');
    expect(all.single.productName, 'Indomie Mi Goreng');
    expect(all.single.sodiumMg, 750);
    expect(all.single.source, ConsumptionSource.scan);
    expect(all.single.consumedAt, indomieConsumption().consumedAt);
  });

  test('Update: perubahan tetap tersimpan setelah aplikasi dibuka kembali', () async {
    var repository = await openApp();
    await repository.saveConsumption(indomieConsumption());
    await repository.updateConsumption(indomieConsumption().copyWith(productName: 'Indomie Soto', sodiumMg: 820));
    await closeApp();

    repository = await openApp();
    final all = await repository.getAllConsumptions();

    expect(all, hasLength(1));
    expect(all.single.productName, 'Indomie Soto');
    expect(all.single.sodiumMg, 820);
  });

  test('Delete: data yang dihapus tidak muncul lagi setelah aplikasi dibuka kembali', () async {
    var repository = await openApp();
    await repository.saveConsumption(indomieConsumption());
    await repository.deleteConsumption('indomie-1');
    await closeApp();

    repository = await openApp();

    expect(await repository.getAllConsumptions(), isEmpty);
  });
}
