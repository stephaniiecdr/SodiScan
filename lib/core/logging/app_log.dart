import 'package:flutter/foundation.dart';

import 'log_entry.dart';
import 'log_store.dart';

typedef LogPrinter = void Function(String line);

/// Logger aplikasi. Setiap log dicetak ke konsol (terlihat di `flutter logs`
/// atau `adb logcat` dengan tag `flutter`, juga pada build release) dan
/// disimpan ke [LogStore] agar bisa dilihat dari layar Log Aplikasi.
class AppLog {
  AppLog._();

  static LogStore _store = InMemoryLogStore();
  static LogLevel _minLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;
  static LogPrinter _printer = debugPrint;
  static DateTime Function() _clock = DateTime.now;

  static LogStore get store => _store;
  static LogLevel get minLevel => _minLevel;

  static void configure({LogStore? store, LogLevel? minLevel, LogPrinter? printer, DateTime Function()? clock}) {
    if (store != null) _store = store;
    if (minLevel != null) _minLevel = minLevel;
    if (printer != null) _printer = printer;
    if (clock != null) _clock = clock;
  }

  @visibleForTesting
  static void reset() {
    _store = InMemoryLogStore();
    _minLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;
    _printer = debugPrint;
    _clock = DateTime.now;
  }

  static void d(String tag, String message) => _log(LogLevel.debug, tag, message);

  static void i(String tag, String message) => _log(LogLevel.info, tag, message);

  static void w(String tag, String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.warning, tag, message, error, stackTrace);

  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, tag, message, error, stackTrace);

  static void _log(LogLevel level, String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (level.index < _minLevel.index) return;
    final entry = LogEntry(
      time: _clock(),
      level: level,
      tag: tag,
      message: message,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );
    try {
      _printer('[SodiScan] ${entry.format(withStackTrace: level == LogLevel.error)}');
      _store.write(entry);
    } catch (_) {
      // Logging tidak boleh membuat aplikasi crash.
    }
  }
}
