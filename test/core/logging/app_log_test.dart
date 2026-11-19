import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/logging/app_log.dart';
import 'package:sodiscan/core/logging/log_entry.dart';
import 'package:sodiscan/core/logging/log_store.dart';

void main() {
  late InMemoryLogStore store;
  late List<String> printed;
  final now = DateTime(2026, 11, 20, 9, 5, 7);

  setUp(() {
    store = InMemoryLogStore();
    printed = [];
    AppLog.configure(store: store, minLevel: LogLevel.debug, printer: printed.add, clock: () => now);
  });

  tearDown(AppLog.reset);

  group('AppLog', () {
    test('mencatat ke store dan mencetak ke konsol', () {
      AppLog.i('App', 'dimulai');

      final entry = store.readAll().single;
      expect(entry.level, LogLevel.info);
      expect(entry.tag, 'App');
      expect(entry.message, 'dimulai');
      expect(entry.time, now);
      expect(printed.single, contains('[INFO] App: dimulai'));
    });

    test('log di bawah minLevel diabaikan (mode release)', () {
      AppLog.configure(minLevel: LogLevel.info);

      AppLog.d('App', 'detail');
      AppLog.w('App', 'peringatan');

      expect(store.readAll().map((e) => e.level), [LogLevel.warning]);
      expect(printed, hasLength(1));
    });

    test('error dan stack trace ikut tersimpan', () {
      AppLog.e('Repo', 'gagal', StateError('box tertutup'), StackTrace.fromString('#0 main'));

      final entry = store.readAll().single;
      expect(entry.error, contains('box tertutup'));
      expect(entry.stackTrace, '#0 main');
      expect(printed.single, contains('#0 main'));
    });

    test('store yang error tidak membuat aplikasi crash', () {
      AppLog.configure(store: _BrokenStore());

      expect(() => AppLog.e('App', 'tetap aman'), returnsNormally);
    });
  });

  group('InMemoryLogStore', () {
    test('membuang log tertua jika melebihi batas', () {
      final small = InMemoryLogStore(maxEntries: 2);
      for (final message in ['a', 'b', 'c']) {
        small.write(LogEntry(time: now, level: LogLevel.info, tag: 't', message: message));
      }

      expect(small.readAll().map((e) => e.message), ['b', 'c']);
    });
  });

  group('LogEntry', () {
    test('toMap lalu tryFromMap menghasilkan data yang sama', () {
      final entry = LogEntry(time: now, level: LogLevel.error, tag: 'HTTP', message: 'GET', error: 'timeout');

      final restored = LogEntry.tryFromMap(entry.toMap())!;

      expect(restored.format(), entry.format());
      expect(restored.error, 'timeout');
    });

    test('data rusak menghasilkan null', () {
      expect(LogEntry.tryFromMap({'time': 'bukan-tanggal', 'level': 'info', 'tag': 't', 'message': 'm'}), isNull);
      expect(LogEntry.tryFromMap({'time': now.toIso8601String(), 'level': 'fatal', 'tag': 't', 'message': 'm'}), isNull);
      expect(LogEntry.tryFromMap({}), isNull);
    });
  });
}

class _BrokenStore implements LogStore {
  @override
  Future<void> clear() async {}

  @override
  List<LogEntry> readAll() => const [];

  @override
  void write(LogEntry entry) => throw StateError('disk penuh');
}
