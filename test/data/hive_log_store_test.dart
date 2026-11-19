import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sodiscan/core/logging/log_entry.dart';
import 'package:sodiscan/data/datasources/local/hive_log_store.dart';

void main() {
  late Directory tempDir;

  Future<HiveLogStore> openStore({int maxEntries = 500}) async {
    Hive.init(tempDir.path);
    return HiveLogStore(await Hive.openBox<Map>(HiveLogStore.boxName), maxEntries: maxEntries);
  }

  LogEntry entry(String message, {LogLevel level = LogLevel.info}) =>
      LogEntry(time: DateTime(2026, 11, 20), level: level, tag: 'Test', message: message);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sodiscan_log_test');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('log tetap ada setelah aplikasi ditutup dan dibuka kembali', () async {
    var store = await openStore();
    store.write(entry('sebelum crash', level: LogLevel.error));
    await Hive.close();

    store = await openStore();

    expect(store.readAll().single.message, 'sebelum crash');
    expect(store.readAll().single.level, LogLevel.error);
  });

  test('hanya menyimpan log terbaru sesuai batas', () async {
    final store = await openStore(maxEntries: 3);
    for (var i = 1; i <= 5; i++) {
      store.write(entry('log $i'));
    }

    expect(store.readAll().map((e) => e.message), ['log 3', 'log 4', 'log 5']);
  });

  test('baris rusak dilewati, log lain tetap terbaca', () async {
    final store = await openStore();
    await Hive.box<Map>(HiveLogStore.boxName).add({'rusak': true});
    store.write(entry('valid'));

    expect(store.readAll().map((e) => e.message), ['valid']);
  });

  test('clear menghapus semua log', () async {
    final store = await openStore();
    store.write(entry('a'));
    await store.clear();

    expect(store.readAll(), isEmpty);
  });
}
