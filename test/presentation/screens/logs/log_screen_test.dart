import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/core/logging/app_log.dart';
import 'package:sodiscan/core/logging/log_entry.dart';
import 'package:sodiscan/core/logging/log_store.dart';
import 'package:sodiscan/presentation/screens/logs/log_screen.dart';

void main() {
  late InMemoryLogStore store;
  String? clipboardText;

  LogEntry entry(LogLevel level, String message) =>
      LogEntry(time: DateTime(2026, 11, 20, 8, 30), level: level, tag: 'Test', message: message);

  setUp(() {
    store = InMemoryLogStore();
    AppLog.configure(store: store, printer: (_) {});
    clipboardText = null;
  });

  tearDown(AppLog.reset);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboardText = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(
      Provider<LogStore>.value(
        value: store,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(onPressed: () => Navigator.of(context).push(LogScreen.route(context)), child: const Text('buka')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('empty state saat belum ada log', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Belum Ada Log'), findsOneWidget);
  });

  testWidgets('menampilkan log terbaru paling atas', (tester) async {
    store
      ..write(entry(LogLevel.info, 'pertama'))
      ..write(entry(LogLevel.error, 'terakhir'));
    await pumpScreen(tester);

    final first = tester.getTopLeft(find.text('Test: terakhir')).dy;
    final second = tester.getTopLeft(find.text('Test: pertama')).dy;
    expect(first, lessThan(second));
  });

  testWidgets('filter level hanya menampilkan error', (tester) async {
    store
      ..write(entry(LogLevel.info, 'info biasa'))
      ..write(entry(LogLevel.error, 'crash'));
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('logFilter_error')));
    await tester.pumpAndSettle();

    expect(find.text('Test: crash'), findsOneWidget);
    expect(find.text('Test: info biasa'), findsNothing);
  });

  testWidgets('salin log ke clipboard dan tampilkan feedback', (tester) async {
    store.write(entry(LogLevel.warning, 'timeout'));
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Salin log'));
    await tester.pump();

    expect(clipboardText, contains('[WARN] Test: timeout'));
    expect(find.text(LogScreen.copiedText), findsOneWidget);
  });

  testWidgets('hapus log setelah konfirmasi', (tester) async {
    store.write(entry(LogLevel.info, 'lama'));
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Hapus log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Test: lama'), findsNothing);
    expect(find.text(LogScreen.clearedText), findsOneWidget);
  });

  testWidgets('batal hapus tidak mengubah log', (tester) async {
    store.write(entry(LogLevel.info, 'tetap'));
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Hapus log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Test: tetap'), findsOneWidget);
    expect(store.readAll(), hasLength(1));
  });
}
