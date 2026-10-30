import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/usecases/sync_consumptions.dart';
import 'package:sodiscan/presentation/providers/server_sync_notifier.dart';
import 'package:sodiscan/presentation/screens/server_sync/server_sync_screen.dart';

import '../../../helpers/fake_consumption_repository.dart';
import '../../../helpers/fake_consumption_sync_repository.dart';

void main() {
  late FakeConsumptionRepository local;
  late FakeConsumptionSyncRepository server;

  Future<void> pumpScreen(WidgetTester tester, {bool settle = true}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: GetServerConsumptions(server)),
          Provider.value(value: UploadConsumptions(local, server)),
          Provider.value(value: RestoreConsumptions(server, local)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(ServerSyncScreen.route(context)),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
  }

  setUp(() {
    local = FakeConsumptionRepository(items: [indomieConsumption()]);
    server = FakeConsumptionSyncRepository();
  });

  testWidgets('Loading - indikator tampil selama data server dimuat', (tester) async {
    server.gate = Completer<void>();
    await pumpScreen(tester, settle: false);

    expect(find.text('Memuat data dari server...'), findsOneWidget);

    server.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Success - menampilkan data dari server', (tester) async {
    server.items.add(indomieConsumption());
    await pumpScreen(tester);

    expect(find.text('1 catatan tersimpan di server'), findsOneWidget);
    expect(find.text('Indomie Mi Goreng'), findsOneWidget);
  });

  testWidgets('Empty - server belum memiliki data', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Server Masih Kosong'), findsOneWidget);
  });

  testWidgets('Error + Retry - gagal terhubung lalu berhasil setelah Coba Lagi', (tester) async {
    server.failWith = const NetworkFailure('offline');
    await pumpScreen(tester);

    expect(find.text('Gagal Memuat'), findsOneWidget);
    expect(find.text(ServerSyncNotifier.networkErrorText), findsOneWidget);

    server
      ..failWith = null
      ..items.add(indomieConsumption());
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('1 catatan tersimpan di server'), findsOneWidget);
    expect(server.fetchCalls, 2);
  });

  testWidgets('Error JSON rusak menampilkan pesan data tidak valid', (tester) async {
    server.failWith = const DataFormatFailure('rusak');
    await pumpScreen(tester);

    expect(find.text(ServerSyncNotifier.formatErrorText), findsOneWidget);
  });

  testWidgets('Kirim ke Server menyimpan data lokal ke backend lalu memuat ulang', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Server Masih Kosong'), findsOneWidget);

    await tester.tap(find.byKey(const Key('uploadButton')));
    await tester.pumpAndSettle();

    expect(server.items.single.id, 'indomie-1');
    expect(find.text('1 catatan dikirim ke server.'), findsOneWidget);
    expect(find.text('1 catatan tersimpan di server'), findsOneWidget);
  });

  testWidgets('tombol sinkronisasi nonaktif selama proses agar tidak double tap', (tester) async {
    await pumpScreen(tester);
    server.gate = Completer<void>();

    await tester.tap(find.byKey(const Key('uploadButton')));
    await tester.pump();

    expect(find.byKey(const Key('syncProgress')), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('uploadButton'))).onPressed, isNull);
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('restoreButton'))).onPressed, isNull);

    server.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Ambil ke HP menyimpan data server ke perangkat', (tester) async {
    local.items.clear();
    server.items.add(indomieConsumption());
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('restoreButton')));
    await tester.pumpAndSettle();

    expect(local.items.single.id, 'indomie-1');
    expect(find.text('1 catatan dari server disimpan ke perangkat.'), findsOneWidget);
  });
}
