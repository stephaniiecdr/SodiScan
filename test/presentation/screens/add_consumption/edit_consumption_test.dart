import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/domain/usecases/update_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/screens/home/home_screen.dart';

import '../../../helpers/fake_consumption_repository.dart';

void main() {
  late FakeConsumptionRepository repository;

  Future<void> pumpScreen(WidgetTester tester) async {
    final notifier = AddConsumptionNotifier(
      getDailySummary: GetDailySummary(repository),
      recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
      updateConsumption: UpdateConsumption(repository),
      deleteConsumption: DeleteConsumption(repository),
      clock: () => fixedNow,
    );
    addTearDown(notifier.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier..load(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder dailyTotal() => find.byKey(const Key('dailyTotalText'));

  Future<void> openEdit(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('editConsumption-indomie-1')));
    await tester.pumpAndSettle();
  }

  testWidgets('form edit terisi data lama lalu perubahan tampil di Beranda', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    await pumpScreen(tester);

    await openEdit(tester);
    expect(find.text('Edit Konsumsi'), findsOneWidget);
    expect(tester.widget<TextFormField>(find.byKey(const Key('productNameField'))).controller!.text, 'Indomie Mi Goreng');
    expect(tester.widget<TextFormField>(find.byKey(const Key('sodiumField'))).controller!.text, '750');

    await tester.enterText(find.byKey(const Key('productNameField')), 'Indomie Soto');
    await tester.enterText(find.byKey(const Key('sodiumField')), '1800');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Konsumsi'), findsNothing);
    expect(find.text('Indomie Soto'), findsOneWidget);
    expect(tester.widget<Text>(dailyTotal()).data, '1800 mg / 2000 mg');
    expect(find.text('Mendekati Batas'), findsOneWidget);
    expect(find.text('Perubahan berhasil disimpan.'), findsOneWidget);
    expect(repository.items, hasLength(1));
  });

  testWidgets('validasi form edit mencegah sodium kosong', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    await pumpScreen(tester);

    await openEdit(tester);
    await tester.enterText(find.byKey(const Key('sodiumField')), '');
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    expect(find.text('Jumlah sodium wajib diisi.'), findsOneWidget);
    expect(repository.updateCalls, 0);
  });
}
