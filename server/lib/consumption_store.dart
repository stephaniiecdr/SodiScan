import 'dart:convert';
import 'dart:io';

class ConsumptionStore {
  ConsumptionStore(this._file);

  final File _file;

  Future<List<Map<String, dynamic>>> readAll() async {
    if (!await _file.exists()) return [];
    final text = await _file.readAsString();
    if (text.trim().isEmpty) return [];
    return (jsonDecode(text) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> upsert(Map<String, dynamic> item) async {
    final items = await readAll();
    final index = items.indexWhere((existing) => existing['id'] == item['id']);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await _write(items);
    return item;
  }

  Future<bool> delete(String id) async {
    final items = await readAll();
    final before = items.length;
    items.removeWhere((item) => item['id'] == id);
    if (items.length == before) return false;
    await _write(items);
    return true;
  }

  Future<void> _write(List<Map<String, dynamic>> items) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(const JsonEncoder.withIndent('  ').convert(items));
  }
}
