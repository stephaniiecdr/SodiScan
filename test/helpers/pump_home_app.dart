import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/core/theme/app_theme.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_consumption_history.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/get_product_by_barcode.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/domain/usecases/sync_consumptions.dart';
import 'package:sodiscan/domain/usecases/update_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/screens/home/home_screen.dart';
import 'package:sodiscan/presentation/screens/scanner/scan_result.dart';

import 'fake_consumption_repository.dart';
import 'fake_consumption_sync_repository.dart';
import 'fake_product_repository.dart';

const Size phonePortrait = Size(390, 844);
const Size phoneLandscape = Size(844, 390);
const Size tabletLandscape = Size(1280, 800);

void useLogicalSize(WidgetTester tester, Size size, {double pixelRatio = 1}) {
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
}

Future<void> pumpHomeApp(
  WidgetTester tester, {
  required FakeConsumptionRepository repository,
  FakeProductRepository? products,
  FakeConsumptionSyncRepository? server,
  Size size = phonePortrait,
  double textScale = 1,
  ScanResult? scanResult,
  double pixelRatio = 1,
  TransitionBuilder? overlay,
}) async {
  useLogicalSize(tester, size, pixelRatio: pixelRatio);
  final syncRepository = server ?? FakeConsumptionSyncRepository();
  final recordConsumption = RecordConsumption(repository, clock: () => fixedNow);
  final notifier = AddConsumptionNotifier(
    getDailySummary: GetDailySummary(repository),
    recordConsumption: recordConsumption,
    updateConsumption: UpdateConsumption(repository),
    deleteConsumption: DeleteConsumption(repository),
    clock: () => fixedNow,
  );
  addTearDown(notifier.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider.value(value: recordConsumption),
        Provider.value(value: GetProductByBarcode(products ?? FakeProductRepository(product: indomieProduct))),
        Provider.value(value: GetConsumptionHistory(repository)),
        Provider.value(value: GetServerConsumptions(syncRepository)),
        Provider.value(value: UploadConsumptions(repository, syncRepository)),
        Provider.value(value: RestoreConsumptions(syncRepository, repository)),
        Provider<ScanBarcode>.value(value: (_) async => scanResult),
        ChangeNotifierProvider.value(value: notifier..load()),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: overlay?.call(context, child) ?? child!,
        ),
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
