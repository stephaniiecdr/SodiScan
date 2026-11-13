import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/presentation/providers/base_notifier.dart';

class _CounterNotifier extends StateNotifier<int> {
  _CounterNotifier() : super(0);

  void set(int value) => emit(value);
}

void main() {
  group('StateNotifier', () {
    test('emit mengganti state dan memberi tahu listener', () {
      final notifier = _CounterNotifier();
      var calls = 0;
      notifier.addListener(() => calls++);

      notifier.set(3);

      expect(notifier.state, 3);
      expect(calls, 1);
    });

    test('emit setelah dispose diabaikan tanpa error', () {
      final notifier = _CounterNotifier()..dispose();
      expect(() => notifier.set(5), returnsNormally);
      expect(notifier.state, 0);
    });
  });

  group('runSubmit', () {
    test('mengembalikan null jika aksi berhasil', () async {
      expect(await runSubmit(() async {}, fallbackMessage: 'gagal'), isNull);
    });

    test('mengembalikan pesan ValidationFailure apa adanya', () async {
      final error = await runSubmit(() async => throw const ValidationFailure('Nama wajib'), fallbackMessage: 'gagal');
      expect(error, 'Nama wajib');
    });

    test('mengembalikan pesan cadangan untuk exception lain', () async {
      final error = await runSubmit(() async => throw const StorageFailure('disk penuh'), fallbackMessage: 'gagal');
      expect(error, 'gagal');
    });
  });
}
