import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/errors/failures.dart';
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
}
