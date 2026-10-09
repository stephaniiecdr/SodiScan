import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/core/theme/app_theme.dart';
import 'package:sodiscan/domain/usecases/get_product_by_barcode.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/presentation/providers/product_lookup_notifier.dart';
import 'package:sodiscan/presentation/screens/product_lookup/product_lookup_screen.dart';

import '../test/helpers/fake_consumption_repository.dart';
import '../test/helpers/fake_product_repository.dart';
import 'screenshot_helpers.dart';

void main() {
  late FakeProductRepository productRepository;
  late FakeConsumptionRepository consumptionRepository;
  late ProductLookupNotifier notifier;

  setUpAll(loadAppFonts);

  setUp(() {
    productRepository = FakeProductRepository(product: indomieProduct);
    consumptionRepository = FakeConsumptionRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    usePhoneView(tester);
    notifier = ProductLookupNotifier(
      getProductByBarcode: GetProductByBarcode(productRepository),
      recordConsumption: RecordConsumption(consumptionRepository, clock: () => fixedNow),
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        initialRoute: '/lookup',
        routes: {
          '/': (_) => const Scaffold(),
          '/lookup': (_) => ChangeNotifierProvider.value(value: notifier, child: const ProductLookupScreen()),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(String name) => captureScreen('../docs/screenshots/add_consumption/$name.png');

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> search(WidgetTester tester, String barcode) async {
    await tester.enterText(find.byKey(const Key('barcodeField')), barcode);
    await tester.pumpAndSettle();
    await tapKey(tester, 'searchButton');
  }

  Future<void> fillAmount(WidgetTester tester, String amount) async {
    await tester.enterText(find.byKey(const Key('amountField')), amount);
    await tester.pumpAndSettle();
  }

  tearDown(() => notifier.dispose());

  captureTest('01 idle', (tester) async {
    await pumpScreen(tester);
    await capture('01_idle');
  });

  captureTest('02 barcode validation', (tester) async {
    await pumpScreen(tester);
    await search(tester, '12ab5');
    await capture('02_barcode_validation');
  });

  captureTest('03 loading', (tester) async {
    productRepository.lookupGate = Completer<void>();
    await pumpScreen(tester);
    await search(tester, '089686010947');
    await capture('03_loading');
    productRepository.lookupGate!.complete();
    await tester.pumpAndSettle();
  });

  captureTest('04 success', (tester) async {
    await pumpScreen(tester);
    await search(tester, '089686010947');
    await fillAmount(tester, '2');
    await capture('04_success');
  });

  captureTest('05 empty', (tester) async {
    productRepository.product = null;
    await pumpScreen(tester);
    await search(tester, '0000000000000');
    await capture('05_empty');
  });

  captureTest('06 error retry', (tester) async {
    productRepository.failLookup = true;
    await pumpScreen(tester);
    await search(tester, '089686010947');
    await capture('06_error_retry');
  });

  captureTest('07 portion validation', (tester) async {
    await pumpScreen(tester);
    await search(tester, '089686010947');
    await fillAmount(tester, '0');
    await tapKey(tester, 'saveProductButton');
    await capture('07_portion_validation');
  });

  captureTest('08 submit loading', (tester) async {
    consumptionRepository.saveGate = Completer<void>();
    await pumpScreen(tester);
    await search(tester, '089686010947');
    await fillAmount(tester, '2');
    await tapKey(tester, 'saveProductButton');
    await capture('08_submit_loading');
    consumptionRepository.saveGate!.complete();
    await tester.pumpAndSettle();
  });

  captureTest('09 submit error', (tester) async {
    consumptionRepository.failSave = true;
    await pumpScreen(tester);
    await search(tester, '089686010947');
    await fillAmount(tester, '1');
    await tapKey(tester, 'saveProductButton');
    await capture('09_submit_error');
  });
}
