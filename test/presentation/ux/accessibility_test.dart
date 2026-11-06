import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';

import '../../helpers/fake_consumption_repository.dart';
import '../../helpers/pump_home_app.dart';

void main() {
  late FakeConsumptionRepository repository;

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

  Future<void> expectMeetsGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  testWidgets('Beranda memenuhi guideline ukuran tombol, label, dan kontras teks', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHomeApp(tester, repository: repository);

    await expectMeetsGuidelines(tester);
    semantics.dispose();
  });

  testWidgets('Form Input Manual memenuhi guideline aksesibilitas', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHomeApp(tester, repository: repository);
    await tester.tap(find.byKey(const Key('manualInputButton')));
    await tester.pumpAndSettle();

    await expectMeetsGuidelines(tester);
    semantics.dispose();
  });

  testWidgets('pembaca layar membaca ringkasan harian sebagai satu kalimat lengkap', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHomeApp(tester, repository: repository);

    expect(
      find.bySemanticsLabel(
        'Ringkasan Kamis, 1 Okt 2026. Total natrium 1650 mg dari batas 2000 mg. '
        'Status Mendekati Batas. Sisa 350 mg dari batas harian.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('item konsumsi dibaca lengkap dan tombolnya menyebut nama makanan', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHomeApp(tester, repository: repository);

    expect(find.bySemanticsLabel(RegExp(r'^Indomie Mi Goreng, 750 mg, pukul ')), findsOneWidget);
    expect(find.byTooltip('Ubah Indomie Mi Goreng'), findsOneWidget);
    expect(find.byTooltip('Hapus Indomie Mi Goreng'), findsOneWidget);
    expect(find.bySemanticsLabel('Konsumsi Hari Ini'), findsOneWidget);
    expect(tester.getSemantics(find.text('Konsumsi Hari Ini')).flagsCollection.isHeader, isTrue);
    semantics.dispose();
  });

  testWidgets('teks diperbesar 200% - tidak overflow dan tombol aksi disusun vertikal', (tester) async {
    await pumpHomeApp(tester, repository: repository, textScale: 2);

    expect(find.byKey(const Key('actionButtonsStacked'), skipOffstage: false), findsOneWidget);
    await tester.drag(find.byKey(const Key('homeSinglePane')), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byKey(const Key('homeSinglePane')), const Offset(0, 2000));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('manualInputButton'), skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manualInputButton')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('teks diperbesar 200% di Riwayat dan Sinkronisasi - tidak overflow', (tester) async {
    await pumpHomeApp(tester, repository: repository, textScale: 2);

    await tester.tap(find.byKey(const Key('openHistoryButton')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openServerSyncButton')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
