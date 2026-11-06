import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sodiscan/presentation/screens/scanner/scanner_screen.dart';

import '../../helpers/fake_consumption_repository.dart';
import '../../helpers/fake_consumption_sync_repository.dart';
import '../../helpers/pump_home_app.dart';

void main() {
  late FakeConsumptionRepository repository;
  late FakeConsumptionSyncRepository server;

  setUp(() {
    repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    server = FakeConsumptionSyncRepository(items: [indomieConsumption()]);
  });

  Future<void> openServerSync(WidgetTester tester) async {
    await pumpHomeApp(tester, repository: repository, server: server);
    await tester.tap(find.byKey(const Key('openServerSyncButton')));
    await tester.pumpAndSettle();
  }

  ButtonStyleButton button(WidgetTester tester, String key) => tester.widget<ButtonStyleButton>(find.byKey(Key(key)));

  testWidgets('Kirim ke Server - tombol yang ditekan berubah jadi "Mengirim..." lalu muncul hasil', (tester) async {
    await openServerSync(tester);
    server.gate = Completer<void>();

    await tester.tap(find.byKey(const Key('uploadButton')));
    await tester.pump();

    expect(find.text('Mengirim...'), findsOneWidget);
    expect(find.text('Ambil ke HP'), findsOneWidget);
    expect(find.byKey(const Key('syncProgress')), findsOneWidget);
    expect(button(tester, 'uploadButton').onPressed, isNull);
    expect(button(tester, 'restoreButton').onPressed, isNull);

    server.gate!.complete();
    server.gate = null;
    await tester.pumpAndSettle();

    expect(find.text('1 catatan dikirim ke server.'), findsOneWidget);
    expect(find.text('Kirim ke Server'), findsOneWidget);
  });

  testWidgets('Ambil ke HP - tombol yang ditekan berubah jadi "Mengambil..."', (tester) async {
    await openServerSync(tester);
    server.gate = Completer<void>();

    await tester.tap(find.byKey(const Key('restoreButton')));
    await tester.pump();

    expect(find.text('Mengambil...'), findsOneWidget);
    expect(find.text('Kirim ke Server'), findsOneWidget);

    server.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('1 catatan dari server disimpan ke perangkat.'), findsOneWidget);
  });

  testWidgets('Hapus - konfirmasi lalu pesan hasil, item hilang dari daftar', (tester) async {
    await pumpHomeApp(tester, repository: repository);

    await tester.tap(find.byKey(const Key('deleteConsumption-indomie-1')));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Konsumsi?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmDeleteButton')));
    await tester.pumpAndSettle();
    expect(find.text('Konsumsi dihapus.'), findsOneWidget);
    expect(find.text('Belum ada makanan yang tercatat hari ini.'), findsOneWidget);
  });

  group('Tombol senter menunjukkan statusnya', () {
    Future<void> pumpTorch(WidgetTester tester, TorchState state) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(appBar: AppBar(actions: [TorchButton(torchState: state, onPressed: () {})])),
        ),
      );
    }

    IconButton torch(WidgetTester tester) => tester.widget<IconButton>(find.byKey(const Key('torchButton')));

    testWidgets('mati', (tester) async {
      await pumpTorch(tester, TorchState.off);
      expect(torch(tester).tooltip, 'Nyalakan senter');
      expect(torch(tester).isSelected, isFalse);
    });

    testWidgets('menyala', (tester) async {
      await pumpTorch(tester, TorchState.on);
      expect(torch(tester).tooltip, 'Matikan senter');
      expect(torch(tester).isSelected, isTrue);
    });

    testWidgets('tidak tersedia - tombol nonaktif', (tester) async {
      await pumpTorch(tester, TorchState.unavailable);
      expect(torch(tester).tooltip, 'Senter tidak tersedia');
      expect(torch(tester).onPressed, isNull);
    });
  });
}
