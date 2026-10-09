import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/core/theme/app_theme.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/screens/add_consumption/add_consumption_screen.dart';

import '../test/helpers/fake_consumption_repository.dart';
import 'screenshot_helpers.dart';

void main() {
  late FakeConsumptionRepository repository;
  late AddConsumptionNotifier notifier;

  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester) async {
    usePhoneView(tester);

    notifier = AddConsumptionNotifier(
      getDailySummary: GetDailySummary(repository),
      recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
      clock: () => fixedNow,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const AddConsumptionScreen(),
        ),
      ),
    );
    unawaited(notifier.load());
    await tester.pump();
  }

  Future<void> capture(String name) => captureScreen('../docs/screenshots/$name.png');

  Future<void> fillAndSubmit(WidgetTester tester, String name, String sodium) async {
    await tester.enterText(find.byKey(const Key('productNameField')), name);
    await tester.enterText(find.byKey(const Key('sodiumField')), sodium);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('submitButton')));
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  tearDown(() => notifier.dispose());

  captureTest('01 initial loading', (tester) async {
    repository = FakeConsumptionRepository()..loadGate = Completer<void>();
    await pumpScreen(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await capture('01_initial_loading');
    repository.loadGate!.complete();
  });

  captureTest('02 success', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    await pumpScreen(tester);
    await capture('02_success');
  });

  captureTest('03 empty', (tester) async {
    repository = FakeConsumptionRepository();
    await pumpScreen(tester);
    await capture('03_empty');
  });

  captureTest('04 error retry', (tester) async {
    repository = FakeConsumptionRepository()..failLoad = true;
    await pumpScreen(tester);
    await capture('04_error_retry');
  });

  captureTest('05 form validation', (tester) async {
    repository = FakeConsumptionRepository();
    await pumpScreen(tester);
    await fillAndSubmit(tester, '', 'abc');
    expect(find.text('Nama makanan wajib diisi.'), findsOneWidget);
    expect(find.text('Jumlah sodium harus berupa angka.'), findsOneWidget);
    await capture('05_form_validation');
  });

  captureTest('06 submit loading', (tester) async {
    repository = FakeConsumptionRepository()..saveGate = Completer<void>();
    await pumpScreen(tester);
    await fillAndSubmit(tester, 'Indomie Mi Goreng', '750');
    await capture('06_submit_loading');
    repository.saveGate!.complete();
    await tester.pumpAndSettle();
  });

  captureTest('07 submit success', (tester) async {
    repository = FakeConsumptionRepository();
    await pumpScreen(tester);
    await fillAndSubmit(tester, 'Indomie Mi Goreng', '750');
    await capture('07_submit_success');
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  captureTest('08 submit error', (tester) async {
    repository = FakeConsumptionRepository()..failSave = true;
    await pumpScreen(tester);
    await fillAndSubmit(tester, 'Chitato Sapi Panggang', '210');
    await capture('08_submit_error');
  });
}
