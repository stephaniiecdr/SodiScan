import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';

import '../test/helpers/fake_consumption_repository.dart';
import '../test/helpers/fake_consumption_sync_repository.dart';
import '../test/helpers/pump_home_app.dart';
import 'screenshot_helpers.dart';

void main() {
  const keyboardHeight = 300.0;

  late FakeConsumptionRepository repository;

  setUpAll(loadAppFonts);

  setUp(() {
    repository = FakeConsumptionRepository(items: [
      indomieConsumption(),
      FoodConsumption(
        id: 'keripik',
        productName: 'Keripik Kentang',
        sodiumMg: 900,
        source: ConsumptionSource.manual,
        consumedAt: fixedNow.subtract(const Duration(hours: 1)),
      ),
    ]);
  });

  Future<void> capture(String name) => captureScreen('../docs/screenshots/pertemuan8/$name.png');

  Widget simulatedKeyboard(BuildContext context, Widget? child) {
    return Stack(
      children: [
        child!,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: keyboardHeight,
          child: const Material(
            color: Color(0xFFD1D5DB),
            child: Center(
              child: Text(
                'Keyboard (simulasi)',
                style: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: Color(0xFF374151)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  captureTest('01 layout adaptif - tablet landscape', (tester) async {
    await pumpHomeApp(tester, repository: repository, size: tabletLandscape, pixelRatio: 2);
    await capture('01_adaptive_tablet');
  });

  captureTest('01b layout adaptif - HP landscape', (tester) async {
    await pumpHomeApp(tester, repository: repository, size: phoneLandscape, pixelRatio: 3);
    await capture('01b_adaptive_phone_landscape');
  });

  captureTest('02 keyboard-safe - field dan tombol simpan tetap terlihat', (tester) async {
    await pumpHomeApp(tester, repository: repository, size: const Size(360, 640), pixelRatio: 3, overlay: simulatedKeyboard);
    await tester.tap(find.byKey(const Key('manualInputButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('productNameField')), 'Bakso');
    await tester.tap(find.byKey(const Key('sodiumField')));
    tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight * 3);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await capture('02_keyboard_safe');
  });

  captureTest('03 aksesibilitas - teks diperbesar 200%', (tester) async {
    await pumpHomeApp(tester, repository: repository, textScale: 2, pixelRatio: 3);
    await capture('03_accessibility_large_text');
  });

  captureTest('04 feedback aksi - tombol yang ditekan menunjukkan proses', (tester) async {
    final server = FakeConsumptionSyncRepository(items: [indomieConsumption()]);
    await pumpHomeApp(tester, repository: repository, server: server, pixelRatio: 3);
    await tester.tap(find.byKey(const Key('openServerSyncButton')));
    await tester.pumpAndSettle();

    server.gate = Completer<void>();
    await tester.tap(find.byKey(const Key('uploadButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await capture('04_feedback_syncing');

    server.gate!.complete();
    server.gate = null;
    await tester.pumpAndSettle();
    await capture('04b_feedback_result');
  });
}
