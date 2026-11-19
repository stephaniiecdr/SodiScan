enum LogLevel { debug, info, warning, error }

extension LogLevelLabel on LogLevel {
  String get label => switch (this) {
        LogLevel.debug => 'DEBUG',
        LogLevel.info => 'INFO',
        LogLevel.warning => 'WARN',
        LogLevel.error => 'ERROR',
      };
}

class LogEntry {
  const LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;
  final String? error;
  final String? stackTrace;

  Map<String, dynamic> toMap() => {
        'time': time.toIso8601String(),
        'level': level.name,
        'tag': tag,
        'message': message,
        if (error != null) 'error': error,
        if (stackTrace != null) 'stackTrace': stackTrace,
      };

  /// Mengembalikan `null` jika data tersimpan rusak, agar satu baris rusak
  /// tidak membuat seluruh log gagal dibaca.
  static LogEntry? tryFromMap(Map<dynamic, dynamic> map) {
    final time = DateTime.tryParse('${map['time']}');
    final level = LogLevel.values.asNameMap()[map['level']];
    final tag = map['tag'];
    final message = map['message'];
    if (time == null || level == null || tag is! String || message is! String) return null;
    return LogEntry(
      time: time,
      level: level,
      tag: tag,
      message: message,
      error: map['error'] as String?,
      stackTrace: map['stackTrace'] as String?,
    );
  }

  String format({bool withStackTrace = false}) {
    final buffer = StringBuffer('${time.toIso8601String()} [${level.label}] $tag: $message');
    if (error != null) buffer.write(' | $error');
    if (withStackTrace && stackTrace != null) buffer.write('\n$stackTrace');
    return buffer.toString();
  }
}
