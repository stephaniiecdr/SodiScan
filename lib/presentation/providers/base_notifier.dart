import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../core/logging/app_log.dart';

/// Mencegah `notifyListeners` dipanggil setelah notifier di-dispose
/// (misalnya ketika proses async selesai setelah layar ditutup).
mixin SafeNotifier on ChangeNotifier {
  bool _isDisposed = false;

  @protected
  bool get isDisposed => _isDisposed;

  @protected
  void notifySafely() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// Notifier dengan satu objek state immutable yang diganti lewat [emit].
abstract class StateNotifier<T> extends ChangeNotifier with SafeNotifier {
  StateNotifier(this._state);

  T _state;

  T get state => _state;

  @protected
  void emit(T newState) {
    if (isDisposed) return;
    _state = newState;
    notifyListeners();
  }
}

/// Menjalankan aksi simpan dan mengubah exception menjadi pesan untuk UI.
/// Mengembalikan `null` jika berhasil.
Future<String?> runSubmit(
  Future<void> Function() action, {
  required String fallbackMessage,
  String tag = 'Submit',
}) async {
  try {
    await action();
    AppLog.i(tag, 'Simpan berhasil');
    return null;
  } on ValidationFailure catch (failure) {
    AppLog.d(tag, 'Validasi gagal: ${failure.message}');
    return failure.message;
  } on Exception catch (error) {
    AppLog.w(tag, 'Simpan gagal', error);
    return fallbackMessage;
  }
}
