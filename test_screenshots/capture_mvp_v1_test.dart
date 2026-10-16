import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/core/theme/app_theme.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_consumption_history.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/screens/home/home_screen.dart';

import '../test/helpers/fake_consumption_repository.dart';
import 'screenshot_helpers.dart';

FoodConsumption _item(String id, String name, double sodiumMg, DateTime consumedAt) {
  return FoodConsumption(
    id: id,
    productName: name,
    sodiumMg: sodiumMg,
    source: ConsumptionSource.manual,
    consumedAt: consumedAt,
  );
}

void main() {
  late FakeConsumptionRepository repository;

  setUpAll(loadAppFonts);

  Future<void> pumpApp(WidgetTester tester) async {
    usePhoneView(tester);
    final notifier = AddConsumptionNotifier(
      getDailySummary: GetDailySummary(repository),
      recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
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
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildAppTheme(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(String name) => captureScreen('../docs/screenshots/pertemuan5/$name.png');

  List<FoodConsumption> sampleItems() => [
        indomieConsumption(),
        _item('keripik', 'Keripik Kentang', 900, fixedNow.subtract(const Duration(hours: 1))),
        _item('sosis', 'Sosis Bakar', 1400, fixedNow.subtract(const Duration(days: 1, hours: 3))),
        _item('kecap', 'Nasi Goreng Kecap', 800, fixedNow.subtract(const Duration(days: 1, hours: 6))),
        _item('roti', 'Roti Tawar', 400, fixedNow.subtract(const Duration(days: 2))),
      ];

  captureTest('01 history success', (tester) async {
    repository = FakeConsumptionRepository(items: sampleItems());
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('openHistoryButton')));
    await tester.pumpAndSettle();
    await capture('01_history_success');
  });

  captureTest('02 history empty', (tester) async {
    repository = FakeConsumptionRepository();
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('openHistoryButton')));
    await tester.pumpAndSettle();
    await capture('02_history_empty');
  });

  captureTest('03 delete before', (tester) async {
    repository = FakeConsumptionRepository(items: sampleItems());
    await pumpApp(tester);
    await capture('03_delete_before');
  });

  captureTest('04 delete confirm and after', (tester) async {
    repository = FakeConsumptionRepository(items: sampleItems());
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('deleteConsumption-keripik')));
    await tester.pumpAndSettle();
    await capture('04_delete_confirm');

    await tester.tap(find.byKey(const Key('confirmDeleteButton')));
    await tester.pumpAndSettle();
    await capture('05_delete_after');
  });

  captureTest('06 home dashboard', (tester) async {
    repository = FakeConsumptionRepository(items: [
      indomieConsumption(),
      _item('keripik', 'Keripik Kentang', 900, fixedNow.subtract(const Duration(hours: 1))),
      _item('sosis', 'Sosis Bakar', 600, fixedNow.subtract(const Duration(minutes: 20))),
    ]);
    await pumpApp(tester);
    await capture('06_home_danger');
  });

  captureTest('07 home empty', (tester) async {
    repository = FakeConsumptionRepository();
    await pumpApp(tester);
    await capture('07_home_empty');
  });

  captureTest('08 input manual', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('manualInputButton')));
    await tester.pumpAndSettle();
    await capture('08_input_manual');
  });
}
