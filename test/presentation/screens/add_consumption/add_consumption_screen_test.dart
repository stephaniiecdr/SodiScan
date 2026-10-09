import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/screens/add_consumption/add_consumption_screen.dart';

import '../../../helpers/fake_consumption_repository.dart';

void main() {
  late FakeConsumptionRepository repository;
  late AddConsumptionNotifier notifier;

  Future<void> pumpScreen(WidgetTester tester) async {
    notifier = AddConsumptionNotifier(
      getDailySummary: GetDailySummary(repository),
      recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
      clock: () => fixedNow,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier,
        child: const MaterialApp(home: AddConsumptionScreen()),
      ),
    );
    unawaited(notifier.load());
    await tester.pump();
  }

  Finder submitButton() => find.byKey(const Key('submitButton'));

  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.ensureVisible(submitButton());
    await tester.tap(submitButton(), warnIfMissed: false);
    await tester.pump();
  }

  Future<void> fillForm(WidgetTester tester, {required String name, required String sodium}) async {
    await tester.enterText(find.byKey(const Key('productNameField')), name);
    await tester.enterText(find.byKey(const Key('sodiumField')), sodium);
  }

  tearDown(() => notifier.dispose());

  testWidgets('State 1 - menampilkan loading saat data pertama kali dimuat', (tester) async {
    repository = FakeConsumptionRepository()..loadGate = Completer<void>();
    await pumpScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Memuat data...'), findsOneWidget);
    expect(find.byType(Form), findsNothing);

    repository.loadGate!.complete();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('State 2 - menampilkan data konsumsi hari ini saat berhasil dimuat', (tester) async {
    repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    await pumpScreen(tester);

    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
    expect(find.text('750 mg'), findsOneWidget);
    expect(find.text('750 mg / 2000 mg'), findsOneWidget);
    expect(find.text('Aman'), findsOneWidget);
    expect(find.text('Belum Ada Data'), findsNothing);
  });

  testWidgets('State 3 - menampilkan empty state saat belum ada data', (tester) async {
    repository = FakeConsumptionRepository();
    await pumpScreen(tester);

    expect(find.text('Belum Ada Data'), findsOneWidget);
    expect(find.text('Belum ada makanan yang tercatat hari ini.'), findsOneWidget);
    expect(find.text('Terjadi Kesalahan'), findsNothing);
    expect(find.text('Simpan Konsumsi'), findsOneWidget);
  });

  testWidgets('State 4 - menampilkan error dan tombol Coba Lagi memuat ulang data', (tester) async {
    repository = FakeConsumptionRepository()..failLoad = true;
    await pumpScreen(tester);

    expect(find.text('Terjadi Kesalahan'), findsOneWidget);
    expect(find.text('Data tidak dapat dimuat.'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
    expect(repository.loadCalls, 1);

    repository
      ..failLoad = false
      ..items.add(indomieConsumption())
      ..loadGate = Completer<void>();
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();

    expect(repository.loadCalls, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.loadGate!.complete();
    await tester.pump();

    expect(find.text('Terjadi Kesalahan'), findsNothing);
    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
  });

  testWidgets('State 5 - validasi form menolak input kosong, bukan angka, dan nol', (tester) async {
    repository = FakeConsumptionRepository();
    await pumpScreen(tester);

    await tapSubmit(tester);
    expect(find.text('Nama makanan wajib diisi.'), findsOneWidget);
    expect(find.text('Jumlah sodium wajib diisi.'), findsOneWidget);

    await fillForm(tester, name: 'Indomie Mi Goreng', sodium: 'abc');
    await tapSubmit(tester);
    expect(find.text('Nama makanan wajib diisi.'), findsNothing);
    expect(find.text('Jumlah sodium harus berupa angka.'), findsOneWidget);

    await fillForm(tester, name: 'Indomie Mi Goreng', sodium: '0');
    await tapSubmit(tester);
    expect(find.text('Jumlah sodium harus lebih dari 0.'), findsOneWidget);

    await fillForm(tester, name: 'Indomie Mi Goreng', sodium: '-50');
    await tapSubmit(tester);
    expect(find.text('Jumlah sodium harus lebih dari 0.'), findsOneWidget);

    expect(repository.saveCalls, 0);
  });

  testWidgets('State 6 - submit menampilkan loading, menonaktifkan tombol, dan mencegah double submit', (tester) async {
    repository = FakeConsumptionRepository()..saveGate = Completer<void>();
    await pumpScreen(tester);

    await fillForm(tester, name: 'Indomie Mi Goreng', sodium: '750');
    await tapSubmit(tester);

    expect(find.text('Menyimpan...'), findsOneWidget);
    expect(find.descendant(of: submitButton(), matching: find.byType(CircularProgressIndicator)), findsOneWidget);
    expect(tester.widget<FilledButton>(submitButton()).onPressed, isNull);
    expect(notifier.state.isSubmitting, isTrue);

    await tapSubmit(tester);
    final secondSubmit = notifier.submit(productName: 'Indomie Mi Goreng', sodiumMg: 750);
    expect(repository.saveCalls, 1);

    repository.saveGate!.complete();
    expect(await secondSubmit, isFalse);
    await tester.pumpAndSettle();

    expect(repository.saveCalls, 1);
    expect(repository.items, hasLength(1));
    expect(find.text('Konsumsi berhasil disimpan.'), findsOneWidget);
    expect(find.text('Simpan Konsumsi'), findsOneWidget);
    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
    expect(find.text('750 mg / 2000 mg'), findsOneWidget);
    expect(tester.widget<FilledButton>(submitButton()).onPressed, isNotNull);
  });

  testWidgets('Submit error - pesan gagal tampil dan form tetap bisa digunakan', (tester) async {
    repository = FakeConsumptionRepository()..failSave = true;
    await pumpScreen(tester);

    await fillForm(tester, name: 'Chitato Sapi Panggang', sodium: '210');
    await tapSubmit(tester);
    await tester.pump();

    expect(find.text('Konsumsi gagal disimpan. Silakan coba lagi.'), findsOneWidget);
    expect(find.text('Belum Ada Data'), findsOneWidget);
    expect(find.text('Chitato Sapi Panggang'), findsOneWidget);
    expect(find.text('210'), findsOneWidget);
    expect(tester.widget<FilledButton>(submitButton()).onPressed, isNotNull);
  });
}
