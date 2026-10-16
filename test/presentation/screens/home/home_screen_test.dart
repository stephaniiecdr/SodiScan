import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_consumption_history.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/get_product_by_barcode.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/screens/home/home_screen.dart';

import '../../../helpers/fake_consumption_repository.dart';
import '../../../helpers/fake_product_repository.dart';

void main() {
  late FakeConsumptionRepository repository;
  late FakeProductRepository productRepository;

  Future<void> pumpHome(WidgetTester tester) async {
    productRepository = FakeProductRepository();
    final recordConsumption = RecordConsumption(repository, clock: () => fixedNow);
    final notifier = AddConsumptionNotifier(
      getDailySummary: GetDailySummary(repository),
      recordConsumption: recordConsumption,
      deleteConsumption: DeleteConsumption(repository),
      clock: () => fixedNow,
    );
    addTearDown(notifier.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: recordConsumption),
          Provider.value(value: GetProductByBarcode(productRepository)),
          Provider.value(value: GetConsumptionHistory(repository)),
          ChangeNotifierProvider.value(value: notifier..load()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  double progressValue(WidgetTester tester) {
    return tester.widget<LinearProgressIndicator>(find.byKey(const Key('dailyProgress'))).value!;
  }

  testWidgets('Beranda menampilkan tanggal, total, progres, sisa batas, dan tombol aksi', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    await pumpHome(tester);

    expect(find.text('SodiScan'), findsOneWidget);
    expect(find.text('Kamis, 1 Okt 2026'), findsOneWidget);
    expect(find.text('750 mg / 2000 mg'), findsOneWidget);
    expect(find.text('Aman'), findsOneWidget);
    expect(progressValue(tester), 0.375);
    expect(find.text('Sisa 1250 mg dari batas harian'), findsOneWidget);
    expect(find.text('Pindai Barcode'), findsOneWidget);
    expect(find.text('Input Manual'), findsOneWidget);
    expect(find.text('Konsumsi Hari Ini'), findsOneWidget);
    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
  });

  testWidgets('Beranda menampilkan kelebihan batas dan progres penuh saat status Bahaya', (tester) async {
    repository = FakeConsumptionRepository(items: [
      FoodConsumption(
        id: 'sosis',
        productName: 'Sosis Bakar',
        sodiumMg: 2300,
        source: ConsumptionSource.manual,
        consumedAt: fixedNow,
      ),
    ]);
    await pumpHome(tester);

    expect(find.text('Bahaya'), findsOneWidget);
    expect(progressValue(tester), 1.0);
    expect(find.text('Melebihi batas 300 mg'), findsOneWidget);
  });

  testWidgets('tombol Input Manual membuka form, simpan kembali ke Beranda dengan total baru', (tester) async {
    repository = FakeConsumptionRepository();
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('manualInputButton')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Input Manual'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('productNameField')), 'Keripik Kentang');
    await tester.enterText(find.byKey(const Key('sodiumField')), '900');
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pumpAndSettle();

    expect(find.text('SodiScan'), findsOneWidget);
    expect(find.text('900 mg / 2000 mg'), findsOneWidget);
    expect(find.text('Keripik Kentang'), findsOneWidget);
  });

  testWidgets('tombol Pindai Barcode membuka Cari Produk, produk tidak ditemukan diarahkan ke Input Manual', (tester) async {
    repository = FakeConsumptionRepository();
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('scanBarcodeButton')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Cari Produk'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('barcodeField')), '12345678');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();
    expect(find.text('Produk Tidak Ditemukan'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Input Manual'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Input Manual'), findsOneWidget);
    expect(find.byKey(const Key('productNameField')), findsOneWidget);
  });
}
