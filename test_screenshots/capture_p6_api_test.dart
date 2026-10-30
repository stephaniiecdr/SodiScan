import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/core/theme/app_theme.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_consumption_history.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/domain/usecases/sync_consumptions.dart';
import 'package:sodiscan/domain/usecases/update_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/screens/home/home_screen.dart';

import '../test/helpers/fake_consumption_repository.dart';
import '../test/helpers/fake_consumption_sync_repository.dart';
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
  late FakeConsumptionRepository local;
  late FakeConsumptionSyncRepository server;

  setUpAll(loadAppFonts);

  setUp(() {
    local = FakeConsumptionRepository(items: [
      indomieConsumption(),
      _item('keripik', 'Keripik Kentang', 900, fixedNow.subtract(const Duration(hours: 1))),
      _item('sosis', 'Sosis Bakar', 1400, fixedNow.subtract(const Duration(days: 1, hours: 3))),
    ]);
    server = FakeConsumptionSyncRepository();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    usePhoneView(tester);
    final notifier = AddConsumptionNotifier(
      getDailySummary: GetDailySummary(local),
      recordConsumption: RecordConsumption(local, clock: () => fixedNow),
      updateConsumption: UpdateConsumption(local),
      deleteConsumption: DeleteConsumption(local),
      clock: () => fixedNow,
    );
    addTearDown(notifier.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: GetConsumptionHistory(local)),
          Provider.value(value: GetServerConsumptions(server)),
          Provider.value(value: UploadConsumptions(local, server)),
          Provider.value(value: RestoreConsumptions(server, local)),
          ChangeNotifierProvider.value(value: notifier..load()),
        ],
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildAppTheme(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSync(WidgetTester tester, {bool settle = true}) async {
    await tester.tap(find.byKey(const Key('openServerSyncButton')));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> capture(String name) => captureScreen('../docs/screenshots/pertemuan6/$name.png');

  captureTest('01 home entry', (tester) async {
    await pumpHome(tester);
    await capture('01_home_sync_button');
  });

  captureTest('02 loading', (tester) async {
    server.gate = Completer<void>();
    await pumpHome(tester);
    await openSync(tester, settle: false);
    await capture('02_loading');
    server.gate!.complete();
    await tester.pumpAndSettle();
  });

  captureTest('03 empty', (tester) async {
    await pumpHome(tester);
    await openSync(tester);
    await capture('03_empty');
  });

  captureTest('04 error', (tester) async {
    server.failWith = const NetworkFailure('offline');
    await pumpHome(tester);
    await openSync(tester);
    await capture('04_error_retry');
  });

  captureTest('05 upload success', (tester) async {
    await pumpHome(tester);
    await openSync(tester);
    await tester.tap(find.byKey(const Key('uploadButton')));
    await tester.pumpAndSettle();
    await capture('05_upload_success');
  });

  captureTest('06 restore', (tester) async {
    server.items.addAll(local.items);
    local.items.clear();
    await pumpHome(tester);
    await openSync(tester);
    await tester.tap(find.byKey(const Key('restoreButton')));
    await tester.pumpAndSettle();
    await capture('06_restore_success');
  });
}
