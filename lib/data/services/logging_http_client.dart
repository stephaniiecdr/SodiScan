import 'package:http/http.dart' as http;

import '../../core/logging/app_log.dart';

/// Membungkus [http.Client] untuk mencatat setiap request: method, URL,
/// status, dan durasi. Isi body tidak dicatat agar data pengguna tidak bocor ke log.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient(this._inner, {Stopwatch Function()? stopwatch}) : _stopwatch = stopwatch ?? Stopwatch.new;

  static const String tag = 'HTTP';

  final http.Client _inner;
  final Stopwatch Function() _stopwatch;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final label = '${request.method} ${request.url}';
    final watch = _stopwatch()..start();
    try {
      final response = await _inner.send(request);
      final summary = '$label -> ${response.statusCode} (${watch.elapsedMilliseconds} ms)';
      if (response.statusCode >= 400) {
        AppLog.w(tag, summary);
      } else {
        AppLog.i(tag, summary);
      }
      return response;
    } catch (error, stack) {
      AppLog.w(tag, '$label gagal (${watch.elapsedMilliseconds} ms)', error, stack);
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}
