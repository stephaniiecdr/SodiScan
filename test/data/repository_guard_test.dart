import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/core/logging/app_log.dart';
import 'package:sodiscan/core/logging/log_entry.dart';
import 'package:sodiscan/core/logging/log_store.dart';
import 'package:sodiscan/data/repositories/repository_guard.dart';

void main() {
  group('guardStorage', () {
    test('meneruskan hasil jika berhasil', () async {
      expect(await guardStorage('membaca', () async => 42), 42);
    });

    test('mengubah error apa pun menjadi StorageFailure', () async {
      await expectLater(guardStorage('membaca', () async => throw StateError('box tertutup')), throwsA(isA<StorageFailure>()));
    });

    test('Failure yang sudah spesifik tidak dibungkus ulang', () async {
      await expectLater(
        guardStorage('membaca', () async => throw const ValidationFailure('x')),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('guardRemote', () {
    test('JSON rusak menjadi DataFormatFailure', () async {
      await expectLater(guardRemote('memuat', () async => throw const FormatException('bad')), throwsA(isA<DataFormatFailure>()));
    });

    test('timeout dan error lain menjadi NetworkFailure', () async {
      await expectLater(guardRemote('memuat', () async => throw TimeoutException('lama')), throwsA(isA<NetworkFailure>()));
      await expectLater(guardRemote('memuat', () async => throw Exception('offline')), throwsA(isA<NetworkFailure>()));
    });
  });

  group('logging', () {
    late InMemoryLogStore store;

    setUp(() {
      store = InMemoryLogStore();
      AppLog.configure(store: store, minLevel: LogLevel.debug, printer: (_) {});
    });

    tearDown(AppLog.reset);

    test('error penyimpanan dicatat sebagai ERROR', () async {
      await expectLater(guardStorage('membaca', () async => throw StateError('box tertutup')), throwsA(isA<StorageFailure>()));

      final entry = store.readAll().single;
      expect(entry.level, LogLevel.error);
      expect(entry.tag, 'Repository');
      expect(entry.error, contains('box tertutup'));
    });

    test('error jaringan dicatat sebagai WARN', () async {
      await expectLater(guardRemote('memuat', () async => throw Exception('offline')), throwsA(isA<NetworkFailure>()));

      expect(store.readAll().single.level, LogLevel.warning);
    });

    test('operasi sukses tidak menghasilkan log', () async {
      await guardStorage('membaca', () async => 1);

      expect(store.readAll(), isEmpty);
    });
  });
}
