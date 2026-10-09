import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/usecases/get_product_by_barcode.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/presentation/providers/product_lookup_notifier.dart';
import 'package:sodiscan/presentation/providers/product_lookup_state.dart';

import '../../helpers/fake_consumption_repository.dart';
import '../../helpers/fake_product_repository.dart';

void main() {
  late FakeProductRepository productRepository;
  late FakeConsumptionRepository consumptionRepository;
  late ProductLookupNotifier notifier;

  setUp(() {
    productRepository = FakeProductRepository(product: indomieProduct);
    consumptionRepository = FakeConsumptionRepository();
    notifier = ProductLookupNotifier(
      getProductByBarcode: GetProductByBarcode(productRepository),
      recordConsumption: RecordConsumption(consumptionRepository, clock: () => fixedNow),
    );
  });

  test('state awal idle', () {
    expect(notifier.state.status, LookupStatus.idle);
  });

  test('search menghasilkan success, empty, atau error', () async {
    await notifier.search('089686010947');
    expect(notifier.state.status, LookupStatus.success);
    expect(notifier.state.product, indomieProduct);

    productRepository.product = null;
    await notifier.search('089686010947');
    expect(notifier.state.status, LookupStatus.empty);
    expect(notifier.state.message, ProductLookupNotifier.notFoundText);

    productRepository.product = noSodiumProduct;
    await notifier.search('8991002101234');
    expect(notifier.state.status, LookupStatus.empty);
    expect(notifier.state.message, ProductLookupNotifier.noSodiumText);

    productRepository.failLookup = true;
    await notifier.search('089686010947');
    expect(notifier.state.status, LookupStatus.error);
  });

  test('retry mencari ulang barcode terakhir', () async {
    productRepository.failLookup = true;
    await notifier.search('089686010947');

    productRepository.failLookup = false;
    await notifier.retry();

    expect(productRepository.lookupCalls, 2);
    expect(productRepository.lastBarcode, '089686010947');
    expect(notifier.state.status, LookupStatus.success);
  });

  test('pencarian kedua saat loading diabaikan', () async {
    productRepository.lookupGate = Completer<void>();
    final first = notifier.search('089686010947');
    final second = notifier.search('089686010947');

    expect(productRepository.lookupCalls, 1);
    productRepository.lookupGate!.complete();
    await Future.wait([first, second]);
    expect(productRepository.lookupCalls, 1);
  });

  test('submit menyimpan konsumsi hasil scan satu kali walaupun dipanggil dua kali', () async {
    await notifier.search('089686010947');
    consumptionRepository.saveGate = Completer<void>();

    final first = notifier.submit(2);
    final second = notifier.submit(2);

    expect(notifier.state.isSubmitting, isTrue);
    expect(await second, isFalse);
    consumptionRepository.saveGate!.complete();
    expect(await first, isTrue);

    expect(consumptionRepository.saveCalls, 1);
    final saved = consumptionRepository.items.single;
    expect(saved.productName, 'Indomie Mi Goreng');
    expect(saved.sodiumMg, 1500);
    expect(saved.source, ConsumptionSource.scan);
    expect(saved.barcode, '089686010947');
    expect(notifier.state.isSubmitting, isFalse);
  });

  test('submit gagal menyimpan pesan error', () async {
    await notifier.search('089686010947');
    consumptionRepository.failSave = true;

    expect(await notifier.submit(1), isFalse);
    expect(notifier.state.submitErrorMessage, ProductLookupNotifier.submitErrorText);
    expect(notifier.state.isSubmitting, isFalse);
  });
}
