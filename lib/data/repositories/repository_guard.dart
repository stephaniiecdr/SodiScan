import '../../core/errors/failures.dart';
import '../../core/logging/app_log.dart';

const String _tag = 'Repository';

/// Membungkus akses penyimpanan lokal: error apa pun menjadi [StorageFailure].
Future<T> guardStorage<T>(String action, Future<T> Function() run) async {
  try {
    return await run();
  } on Failure {
    rethrow;
  } catch (error, stack) {
    AppLog.e(_tag, 'Gagal $action (penyimpanan lokal)', error, stack);
    throw StorageFailure('Gagal $action: $error');
  }
}

/// Membungkus request API: JSON/struktur rusak menjadi [DataFormatFailure],
/// error lain (status gagal, offline, timeout) menjadi [NetworkFailure].
Future<T> guardRemote<T>(String action, Future<T> Function() run) async {
  try {
    return await run();
  } on Failure {
    rethrow;
  } on FormatException catch (error, stack) {
    AppLog.e(_tag, 'Data rusak saat $action', error, stack);
    throw DataFormatFailure('Data dari server rusak saat $action: ${error.message}');
  } on TypeError catch (error, stack) {
    AppLog.e(_tag, 'Data rusak saat $action', error, stack);
    throw DataFormatFailure('Data dari server rusak saat $action: $error');
  } catch (error) {
    AppLog.w(_tag, 'Gagal $action (jaringan)', error);
    throw NetworkFailure('Gagal $action: $error');
  }
}
