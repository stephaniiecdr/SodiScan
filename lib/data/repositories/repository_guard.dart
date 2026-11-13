import '../../core/errors/failures.dart';

/// Membungkus akses penyimpanan lokal: error apa pun menjadi [StorageFailure].
Future<T> guardStorage<T>(String action, Future<T> Function() run) async {
  try {
    return await run();
  } on Failure {
    rethrow;
  } catch (error) {
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
  } on FormatException catch (error) {
    throw DataFormatFailure('Data dari server rusak saat $action: ${error.message}');
  } on TypeError catch (error) {
    throw DataFormatFailure('Data dari server rusak saat $action: $error');
  } catch (error) {
    throw NetworkFailure('Gagal $action: $error');
  }
}
