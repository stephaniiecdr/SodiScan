import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/domain/usecases/update_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/screens/home/home_screen.dart';

import '../../../helpers/fake_consumption_repository.dart';

void main() {
  late FakeConsumptionRepository repository;

  FoodConsumption keripik() {
    return FoodConsumption(
      id: 'keripik-1',
      productName: 'Keripik Kentang',
      sodiumMg: 900,
      source: ConsumptionSource.manual,
      consumedAt: fixedNow.subtract(const Duration(hours: 1)),
    );
  }

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

  Future<void> tapDelete(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('deleteConsumption-$id')));
    await tester.pumpAndSettle();
  }

  testWidgets('hapus konsumsi setelah konfirmasi lalu total dan status dihitung ulang', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption(), keripik()]);
    await pumpScreen(tester);
    expect(tester.widget<Text>(dailyTotal()).data, '1650 mg / 2000 mg');
    expect(find.text('Mendekati Batas'), findsOneWidget);

    await tapDelete(tester, 'keripik-1');
    expect(find.text('Hapus Konsumsi?'), findsOneWidget);
    expect(find.text('Keripik Kentang (900 mg) akan dihapus dari catatan.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmDeleteButton')));
    await tester.pumpAndSettle();

    expect(repository.items.map((item) => item.id), ['indomie-1']);
    expect(find.text('Keripik Kentang'), findsNothing);
    expect(tester.widget<Text>(dailyTotal()).data, '750 mg / 2000 mg');
    expect(find.text('Aman'), findsOneWidget);
    expect(find.text('Konsumsi dihapus.'), findsOneWidget);
  });

  testWidgets('menekan Batal tidak menghapus apa pun', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    await pumpScreen(tester);

    await tapDelete(tester, 'indomie-1');
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(repository.items, hasLength(1));
    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
  });

  testWidgets('menghapus konsumsi terakhir menampilkan empty state', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    await pumpScreen(tester);

    await tapDelete(tester, 'indomie-1');
    await tester.tap(find.byKey(const Key('confirmDeleteButton')));
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Data'), findsOneWidget);
  });

  testWidgets('gagal menghapus menampilkan pesan error dan data tetap ada', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption()])..failDelete = true;
    await pumpScreen(tester);

    await tapDelete(tester, 'indomie-1');
    await tester.tap(find.byKey(const Key('confirmDeleteButton')));
    await tester.pumpAndSettle();

    expect(find.text(AddConsumptionNotifier.deleteErrorText), findsOneWidget);
    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
    expect(tester.widget<Text>(dailyTotal()).data, '750 mg / 2000 mg');
  });
}
