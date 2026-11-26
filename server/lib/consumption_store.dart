import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// File data server tidak bisa dibaca sebagai daftar JSON.
class StoreCorruptedException implements Exception {
  const StoreCorruptedException(this.message);

  final String message;

  @override
  String toString() => 'StoreCorruptedException: $message';
}

class ConsumptionStore {
  ConsumptionStore(this._file);

  final File _file;
  Future<void> _queue = Future.value();

  Future<List<Map<String, dynamic>>> readAll() async {
    if (!await _file.exists()) return [];
    final text = await _file.readAsString();
    if (text.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) throw const FormatException('Isi file bukan daftar.');
      return decoded.cast<Map<String, dynamic>>();
    } on FormatException catch (error) {
      throw StoreCorruptedException('File data ${_file.path} rusak: ${error.message}');
    } on TypeError catch (error) {
      throw StoreCorruptedException('File data ${_file.path} rusak: $error');
    }
  }

  Future<Map<String, dynamic>> upsert(Map<String, dynamic> item) {
    return _serialized(() async {
      final items = await readAll();
      final index = items.indexWhere((existing) => existing['id'] == item['id']);
      if (index >= 0) {
        items[index] = item;
      } else {
        items.add(item);
      }
      await _write(items);
      return item;
    });
  }

  Future<bool> delete(String id) {
    return _serialized(() async {
      final items = await readAll();
      final before = items.length;
      items.removeWhere((item) => item['id'] == id);
      if (items.length == before) return false;
      await _write(items);
      return true;
    });
  }

  /// Read-modify-write dijalankan satu per satu agar request bersamaan tidak
  /// saling menimpa (lost update).
  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _write(List<Map<String, dynamic>> items) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(const JsonEncoder.withIndent('  ').convert(items));
  }
}
