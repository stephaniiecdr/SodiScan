import 'package:flutter/foundation.dart';

import 'app_log.dart';

/// Menangkap semua error yang tidak tertangani (error widget/framework dan
/// error async) lalu mencatatnya ke [AppLog], termasuk pada build release.
void installErrorReporting() {
  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    AppLog.e('FlutterError', details.exceptionAsString(), details.exception, details.stack);
    previousFlutterHandler?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.e('Uncaught', 'Error async tidak tertangani', error, stack);
    return true;
  };
}
