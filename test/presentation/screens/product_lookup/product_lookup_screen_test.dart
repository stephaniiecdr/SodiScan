import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/usecases/get_product_by_barcode.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/presentation/providers/product_lookup_notifier.dart';
import 'package:sodiscan/presentation/screens/product_lookup/product_lookup_screen.dart';

import '../../../helpers/fake_consumption_repository.dart';
import '../../../helpers/fake_product_repository.dart';

void main() {
  late FakeProductRepository productRepository;
  late FakeConsumptionRepository consumptionRepository;
  late ProductLookupNotifier notifier;
  bool? popResult;

  setUp(() {
    productRepository = FakeProductRepository(product: indomieProduct);
    consumptionRepository = FakeConsumptionRepository();
    popResult = null;
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    notifier = ProductLookupNotifier(
      getProductByBarcode: GetProductByBarcode(productRepository),
      recordConsumption: RecordConsumption(consumptionRepository, clock: () => fixedNow),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popResult = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(value: notifier, child: const ProductLookupScreen()),
                  ),
                );
              },
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
  }

  Finder byKey(String key) => find.byKey(Key(key));

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(byKey(key));
    await tester.pump();
    await tester.tap(byKey(key));
    await tester.pump();
  }

  Future<void> searchBarcode(WidgetTester tester, String barcode) async {
    await tester.enterText(byKey('barcodeField'), barcode);
    await tapKey(tester, 'searchButton');
  }

  tearDown(() => notifier.dispose());

  testWidgets('Idle - menampilkan petunjuk sebelum pencarian', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Cari Produk Kemasan'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Validasi barcode - menolak kosong, bukan angka, dan panjang salah', (tester) async {
    await pumpScreen(tester);

    await tapKey(tester, 'searchButton');
    expect(find.text('Kode barcode wajib diisi.'), findsOneWidget);

    await searchBarcode(tester, '12ab5678');
    expect(find.text('Kode barcode hanya boleh berisi angka.'), findsOneWidget);

    await searchBarcode(tester, '12345');
    expect(find.text('Kode barcode harus 8 sampai 13 digit.'), findsOneWidget);

    expect(productRepository.lookupCalls, 0);
  });

  testWidgets('Loading - menampilkan indikator dan menonaktifkan tombol cari', (tester) async {
    productRepository.lookupGate = Completer<void>();
    await pumpScreen(tester);

    await searchBarcode(tester, '089686010947');

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Mencari produk...'), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(byKey('searchButton')).onPressed, isNull);

    productRepository.lookupGate!.complete();
    await tester.pumpAndSettle();
    expect(productRepository.lookupCalls, 1);
  });

  testWidgets('Success - menampilkan data produk dan form porsi', (tester) async {
    await pumpScreen(tester);

    await searchBarcode(tester, '089686010947');
    await tester.pump();

    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
    expect(find.text('750 mg'), findsOneWidget);
    expect(find.text('882 mg'), findsOneWidget);
    expect(find.text('Jumlah Porsi'), findsOneWidget);
    expect(find.text('Simpan Konsumsi'), findsOneWidget);
  });

  testWidgets('Empty - produk tidak ditemukan dan produk tanpa data natrium', (tester) async {
    productRepository.product = null;
    await pumpScreen(tester);

    await searchBarcode(tester, '0000000000000');
    await tester.pump();
    expect(find.text('Produk Tidak Ditemukan'), findsOneWidget);
    expect(find.text('Input Manual'), findsOneWidget);
    expect(find.text('Terjadi Kesalahan'), findsNothing);

    productRepository.product = noSodiumProduct;
    await searchBarcode(tester, '8991002101234');
    await tester.pump();
    expect(find.text('Data Natrium Tidak Tersedia'), findsOneWidget);

    await tester.tap(find.text('Input Manual'));
    await tester.pumpAndSettle();
    expect(popResult, isFalse);
  });

  testWidgets('Error + Retry - tombol Coba Lagi mencari ulang barcode yang sama', (tester) async {
    productRepository.failLookup = true;
    await pumpScreen(tester);

    await searchBarcode(tester, '089686010947');
    await tester.pump();
    expect(find.text('Terjadi Kesalahan'), findsOneWidget);
    expect(find.text(ProductLookupNotifier.networkErrorText), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);

    productRepository
      ..failLookup = false
      ..lookupGate = Completer<void>();
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();

    expect(productRepository.lookupCalls, 2);
    expect(productRepository.lastBarcode, '089686010947');
    expect(find.text('Mencari produk...'), findsOneWidget);

    productRepository.lookupGate!.complete();
    await tester.pump();
    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
  });

  testWidgets('Validasi porsi - menolak kosong, bukan angka, dan nol', (tester) async {
    await pumpScreen(tester);
    await searchBarcode(tester, '089686010947');
    await tester.pump();

    await tapKey(tester, 'saveProductButton');
    expect(find.text('Jumlah porsi wajib diisi.'), findsOneWidget);

    await tester.enterText(byKey('amountField'), 'dua');
    await tapKey(tester, 'saveProductButton');
    expect(find.text('Jumlah porsi harus berupa angka.'), findsOneWidget);

    await tester.enterText(byKey('amountField'), '0');
    await tapKey(tester, 'saveProductButton');
    expect(find.text('Jumlah porsi harus lebih dari 0.'), findsOneWidget);

    expect(consumptionRepository.saveCalls, 0);
  });

  testWidgets('Perhitungan natrium - memakai data per 100 g untuk produk tanpa data per saji', (tester) async {
    productRepository.product = chitatoProduct;
    await pumpScreen(tester);
    await searchBarcode(tester, '089686600742');
    await tester.pump();

    expect(find.text('Berat Dikonsumsi'), findsOneWidget);
    await tester.enterText(byKey('amountField'), '50');
    await tester.pump();

    expect(find.text('Perkiraan natrium: 260 mg'), findsOneWidget);
  });

  testWidgets('Submit loading - tombol nonaktif, double tap dicegah, lalu kembali dengan hasil true', (tester) async {
    consumptionRepository.saveGate = Completer<void>();
    await pumpScreen(tester);
    await searchBarcode(tester, '089686010947');
    await tester.pump();

    await tester.enterText(byKey('amountField'), '2');
    await tester.pump();
    expect(find.text('Perkiraan natrium: 1500 mg'), findsOneWidget);

    await tapKey(tester, 'saveProductButton');

    expect(find.text('Menyimpan...'), findsOneWidget);
    expect(tester.widget<FilledButton>(byKey('saveProductButton')).onPressed, isNull);
    expect(tester.widget<ButtonStyleButton>(byKey('searchButton')).onPressed, isNull);

    await tapKey(tester, 'saveProductButton');
    final secondSubmit = notifier.submit(2);
    expect(consumptionRepository.saveCalls, 1);

    consumptionRepository.saveGate!.complete();
    expect(await secondSubmit, isFalse);
    await tester.pumpAndSettle();

    expect(consumptionRepository.saveCalls, 1);
    final saved = consumptionRepository.items.single;
    expect(saved.sodiumMg, 1500);
    expect(saved.source, ConsumptionSource.scan);
    expect(saved.barcode, '089686010947');
    expect(popResult, isTrue);
    expect(find.text('Konsumsi berhasil disimpan.'), findsOneWidget);
  });

  testWidgets('Submit error - pesan gagal tampil dan form tetap bisa digunakan', (tester) async {
    consumptionRepository.failSave = true;
    await pumpScreen(tester);
    await searchBarcode(tester, '089686010947');
    await tester.pump();

    await tester.enterText(byKey('amountField'), '1');
    await tapKey(tester, 'saveProductButton');
    await tester.pump();

    expect(find.text(ProductLookupNotifier.submitErrorText), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(tester.widget<FilledButton>(byKey('saveProductButton')).onPressed, isNotNull);
    expect(popResult, isNull);
  });
}
