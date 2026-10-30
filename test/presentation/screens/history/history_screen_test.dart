import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_consumption_history.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/domain/usecases/update_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/screens/home/home_screen.dart';

import '../../../helpers/fake_consumption_repository.dart';

void main() {
  late FakeConsumptionRepository repository;

  Future<void> openHistory(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('openHistoryButton')));
    await tester.pumpAndSettle();
  }

  Future<void> pumpHome(WidgetTester tester) async {
    final notifier = AddConsumptionNotifier(
      getDailySummary: GetDailySummary(repository),
      recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
      updateConsumption: UpdateConsumption(repository),
      deleteConsumption: DeleteConsumption(repository),
      clock: () => fixedNow,
    );
    addTearDown(notifier.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: GetConsumptionHistory(repository)),
          ChangeNotifierProvider.value(value: notifier..load()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan konsumsi per tanggal beserta total dan status risiko', (tester) async {
    repository = FakeConsumptionRepository(items: [
      indomieConsumption(),
      FoodConsumption(
        id: 'kemarin',
        productName: 'Keripik Kentang',
        sodiumMg: 1800,
        source: ConsumptionSource.manual,
        consumedAt: fixedNow.subtract(const Duration(days: 1)),
      ),
    ]);
    await pumpHome(tester);
    await openHistory(tester);

    expect(find.text('Riwayat Konsumsi'), findsOneWidget);
    expect(find.text('Kamis, 1 Okt 2026'), findsOneWidget);
    expect(find.text('Rabu, 30 Sep 2026'), findsOneWidget);
    expect(find.text('Total 750 mg / 2000 mg'), findsOneWidget);
    expect(find.text('Total 1800 mg / 2000 mg'), findsOneWidget);
    expect(find.text('Aman'), findsOneWidget);
    expect(find.text('Mendekati Batas'), findsOneWidget);
    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
    expect(find.text('Keripik Kentang'), findsOneWidget);
  });

  testWidgets('menampilkan empty state jika belum ada riwayat', (tester) async {
    repository = FakeConsumptionRepository();
    await pumpHome(tester);
    await openHistory(tester);

    expect(find.text('Belum Ada Riwayat'), findsOneWidget);
  });

  testWidgets('menampilkan error dan bisa coba lagi', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    await pumpHome(tester);
    repository.failLoad = true;
    await openHistory(tester);

    expect(find.text('Riwayat tidak dapat dimuat.'), findsOneWidget);

    repository.failLoad = false;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Kamis, 1 Okt 2026'), findsOneWidget);
    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
  });
}
