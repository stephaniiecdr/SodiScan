import 'package:hive/hive.dart';

import '../../../core/logging/log_entry.dart';
import '../../../core/logging/log_store.dart';

/// Menyimpan log ke Hive agar tetap ada setelah aplikasi ditutup atau crash,
/// sehingga masalah saat aplikasi berjalan bisa ditelusuri setelahnya.
class HiveLogStore implements LogStore {
  HiveLogStore(this._box, {this.maxEntries = 500});

  static const String boxName = 'app_logs';

  final Box<Map> _box;
  final int maxEntries;

  @override
  List<LogEntry> readAll() => _box.values.map(LogEntry.tryFromMap).whereType<LogEntry>().toList();

  @override
  void write(LogEntry entry) {
    _box.add(entry.toMap());
    final overflow = _box.length - maxEntries;
    if (overflow > 0) _box.deleteAll(_box.keys.take(overflow).toList());
  }

  @override
  Future<void> clear() => _box.clear();
}
