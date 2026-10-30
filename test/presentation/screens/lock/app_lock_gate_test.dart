import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/domain/repositories/settings_repository.dart';
import 'package:sodiscan/domain/services/device_authenticator.dart';
import 'package:sodiscan/presentation/providers/app_lock_notifier.dart';
import 'package:sodiscan/presentation/screens/lock/app_lock_gate.dart';

import '../../../helpers/fake_device_services.dart';

void main() {
  late FakeSettingsRepository settings;
  late FakeDeviceAuthenticator authenticator;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppLockNotifier(settingsRepository: settings, authenticator: authenticator)..init(),
        child: MaterialApp(
          builder: (_, child) => AppLockGate(child: child!),
          home: const Scaffold(body: Text('Isi Beranda')),
        ),
      ),
    );
  }

  setUp(() {
    settings = FakeSettingsRepository(const AppSettings(appLockEnabled: true));
    authenticator = FakeDeviceAuthenticator();
  });

  testWidgets('kunci mati - Beranda langsung tampil', (tester) async {
    settings.settings = const AppSettings();
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Isi Beranda'), findsOneWidget);
    expect(find.text('SodiScan Terkunci'), findsNothing);
  });

  testWidgets('menunggu autentikasi - layar kunci dengan loading menutupi Beranda', (tester) async {
    authenticator.gate = Completer<void>();
    await pumpApp(tester);
    await tester.pump();

    expect(find.text('SodiScan Terkunci'), findsOneWidget);
    expect(find.text('Menunggu autentikasi...'), findsOneWidget);
    expect(find.text('Isi Beranda'), findsNothing);

    authenticator.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Isi Beranda'), findsOneWidget);
  });

  testWidgets('dibatalkan - pesan tampil, tombol Buka Kunci membuka aplikasi', (tester) async {
    authenticator.result = DeviceAuthResult.cancelled;
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text(AppLockNotifier.cancelledText), findsOneWidget);
    expect(find.text('Isi Beranda'), findsNothing);

    authenticator.result = DeviceAuthResult.success;
    await tester.tap(find.byKey(const Key('unlockButton')));
    await tester.pumpAndSettle();

    expect(find.text('Isi Beranda'), findsOneWidget);
  });

  testWidgets('HP tanpa kunci layar - aplikasi terbuka dengan pesan penjelasan', (tester) async {
    authenticator.result = DeviceAuthResult.notAvailable;
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Isi Beranda'), findsOneWidget);
    expect(find.text(AppLockNotifier.notAvailableText), findsOneWidget);
  });
}
