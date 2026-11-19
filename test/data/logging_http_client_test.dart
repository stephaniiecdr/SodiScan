import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sodiscan/core/logging/app_log.dart';
import 'package:sodiscan/core/logging/log_entry.dart';
import 'package:sodiscan/core/logging/log_store.dart';
import 'package:sodiscan/data/services/logging_http_client.dart';

void main() {
  late InMemoryLogStore store;

  setUp(() {
    store = InMemoryLogStore();
    AppLog.configure(store: store, minLevel: LogLevel.debug, printer: (_) {});
  });

  tearDown(AppLog.reset);

  final url = Uri.parse('http://localhost:8080/api/consumptions');

  test('request sukses dicatat sebagai INFO dengan status', () async {
    final client = LoggingHttpClient(MockClient((_) async => http.Response('{"data":[]}', 200)));

    final response = await client.get(url);

    expect(response.statusCode, 200);
    final entry = store.readAll().single;
    expect(entry.level, LogLevel.info);
    expect(entry.message, startsWith('GET $url -> 200'));
  });

  test('status error dicatat sebagai WARN', () async {
    final client = LoggingHttpClient(MockClient((_) async => http.Response('gagal', 500)));

    await client.get(url);

    expect(store.readAll().single.level, LogLevel.warning);
    expect(store.readAll().single.message, contains('-> 500'));
  });

  test('error koneksi dicatat lalu diteruskan ke pemanggil', () async {
    final client = LoggingHttpClient(MockClient((_) async => throw const SocketException('offline')));

    await expectLater(client.get(url), throwsA(isA<SocketException>()));

    final entry = store.readAll().single;
    expect(entry.level, LogLevel.warning);
    expect(entry.message, contains('gagal'));
    expect(entry.error, contains('offline'));
  });

  test('isi body tidak ikut dicatat', () async {
    final client = LoggingHttpClient(MockClient((_) async => http.Response('ok', 200)));

    await client.put(url, body: '{"productName":"Rahasia"}');

    expect(store.readAll().single.format(), isNot(contains('Rahasia')));
  });
}
