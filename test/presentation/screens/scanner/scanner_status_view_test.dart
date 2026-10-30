import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sodiscan/presentation/screens/scanner/scanner_screen.dart';

void main() {
  late int retries;
  late int manualEntries;

  Future<void> pumpError(WidgetTester tester, MobileScannerErrorCode code) async {
    retries = 0;
    manualEntries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScannerStatusView.error(
            error: code,
            onRetry: () => retries++,
            onTypeManually: () => manualEntries++,
          ),
        ),
      ),
    );
  }

  testWidgets('Loading - menampilkan indikator saat kamera disiapkan', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ScannerStatusView.loading())));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Menyiapkan kamera...'), findsOneWidget);
  });

  testWidgets('Izin ditolak - menjelaskan cara mengizinkan dan menyediakan Coba Lagi serta Ketik Barcode', (tester) async {
    await pumpError(tester, MobileScannerErrorCode.permissionDenied);

    expect(find.text('Izin Kamera Ditolak'), findsOneWidget);
    expect(find.textContaining('Pengaturan HP > Aplikasi > SodiScan > Izin'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('scannerRetryButton')));
    await tester.tap(find.byKey(const Key('scannerRetryButton')));
    await tester.tap(find.text('Ketik Barcode'));

    expect(retries, 1);
    expect(manualEntries, 1);
  });

  testWidgets('Kamera tidak didukung - hanya menawarkan Ketik Barcode', (tester) async {
    await pumpError(tester, MobileScannerErrorCode.unsupported);

    expect(find.text('Kamera Tidak Tersedia'), findsOneWidget);
    expect(find.byKey(const Key('scannerRetryButton')), findsNothing);
    expect(find.text('Ketik Barcode'), findsOneWidget);
  });

  testWidgets('Error lain - kamera gagal dibuka dengan tombol Coba Lagi', (tester) async {
    await pumpError(tester, MobileScannerErrorCode.genericError);

    expect(find.text('Kamera Gagal Dibuka'), findsOneWidget);
    expect(find.byKey(const Key('scannerRetryButton')), findsOneWidget);
  });
}
