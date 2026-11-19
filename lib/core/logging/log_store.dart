import 'log_entry.dart';

/// Tempat menyimpan log agar bisa dibaca kembali dari layar Log Aplikasi.
abstract class LogStore {
  List<LogEntry> readAll();

  void write(LogEntry entry);

  Future<void> clear();
}

/// Penyimpanan log di memori dengan batas jumlah baris (log tertua dibuang).
class InMemoryLogStore implements LogStore {
  InMemoryLogStore({this.maxEntries = 300});

  final int maxEntries;
  final List<LogEntry> _entries = [];

  @override
  List<LogEntry> readAll() => List.unmodifiable(_entries);

  @override
  void write(LogEntry entry) {
    _entries.add(entry);
    if (_entries.length > maxEntries) _entries.removeRange(0, _entries.length - maxEntries);
  }

  @override
  Future<void> clear() async => _entries.clear();
}
