import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/presentation/screens/scanner/scan_result.dart';

import '../../helpers/fake_consumption_repository.dart';
import '../../helpers/pump_home_app.dart';

void main() {
  FakeConsumptionRepository repositoryWithHistory() {
    return FakeConsumptionRepository(items: [
      indomieConsumption(),
      for (var day = 1; day <= 3; day++)
        FoodConsumption(
          id: 'hari-$day',
          productName: 'Keripik $day',
          sodiumMg: 500,
          source: ConsumptionSource.manual,
          consumedAt: fixedNow.subtract(Duration(days: day)),
        ),
    ]);
  }

  testWidgets('HP portrait - Beranda satu kolom', (tester) async {
    await pumpHomeApp(tester, repository: repositoryWithHistory());

    expect(find.byKey(const Key('homeSinglePane')), findsOneWidget);
    expect(find.byKey(const Key('homeTwoPane')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HP landscape - Beranda dua kolom: ringkasan di kiri, daftar di kanan', (tester) async {
    await pumpHomeApp(tester, repository: repositoryWithHistory(), size: phoneLandscape);

    expect(find.byKey(const Key('homeTwoPane')), findsOneWidget);
    final summaryLeft = tester.getCenter(find.byKey(const Key('dailyTotalText'))).dx;
    final listLeft = tester.getCenter(find.text('Indomie Mi Goreng')).dx;
    expect(summaryLeft, lessThan(listLeft));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tablet - konten satu kolom dibatasi lebarnya agar form tidak melebar', (tester) async {
    await pumpHomeApp(tester, repository: repositoryWithHistory(), size: const Size(800, 1280));

    expect(find.byKey(const Key('homeSinglePane')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('scanBarcodeButton'))).width, lessThan(400));

    await tester.tap(find.byKey(const Key('manualInputButton')));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('productNameField'))).width, lessThanOrEqualTo(640));
  });

  testWidgets('Tablet landscape - Riwayat tampil dua kartu per baris', (tester) async {
    await pumpHomeApp(tester, repository: repositoryWithHistory(), size: tabletLandscape);

    await tester.tap(find.byKey(const Key('openHistoryButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('historyGrid')), findsOneWidget);
    final today = tester.getTopLeft(find.byKey(Key('historyDay-${DateTime(2026, 10, 1).toIso8601String()}')));
    final yesterday = tester.getTopLeft(find.byKey(Key('historyDay-${DateTime(2026, 9, 30).toIso8601String()}')));
    expect(today.dy, yesterday.dy);
    expect(today.dx, lessThan(yesterday.dx));
  });

  testWidgets('Tablet landscape - Cari Produk: form di kiri, hasil di kanan', (tester) async {
    await pumpHomeApp(
      tester,
      repository: repositoryWithHistory(),
      size: tabletLandscape,
      scanResult: const ScanResult.barcode('089686010947'),
    );

    await tester.tap(find.byKey(const Key('scanBarcodeButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lookupTwoPane')), findsOneWidget);
    final searchField = tester.getCenter(find.byKey(const Key('barcodeField'))).dx;
    final portionField = tester.getCenter(find.byKey(const Key('amountField'))).dx;
    expect(searchField, lessThan(portionField));
    expect(tester.takeException(), isNull);
  });
}
