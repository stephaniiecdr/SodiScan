import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:sodiscan_server/api.dart';
import 'package:sodiscan_server/consumption_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late Handler handler;

  final item = {
    'id': 'a1',
    'barcode': null,
    'productName': 'Indomie',
    'sodiumMg': 750,
    'source': 'manual',
    'consumedAt': '2026-10-01T10:30:00.000',
  };

  Future<Response> send(String method, String path, [Object? body]) async {
    final payload = body == null ? null : (body is String ? body : jsonEncode(body));
    return handler(Request(method, Uri.parse('http://localhost$path'), body: payload));
  }

  Future<List<dynamic>> getAll() async {
    final body = jsonDecode(await (await send('GET', '/api/consumptions')).readAsString()) as Map<String, dynamic>;
    return body['data'] as List<dynamic>;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sodiscan_server_test');
    handler = buildHandler(ConsumptionStore(File('${tempDir.path}/consumptions.json')));
  });

  tearDown(() => tempDir.delete(recursive: true));

  test('PUT menyimpan lalu GET memuat data yang sama', () async {
    expect((await send('PUT', '/api/consumptions/a1', item)).statusCode, 200);

    expect(await getAll(), [item]);
  });

  test('PUT dengan id sama mengganti data, bukan menambah', () async {
    await send('PUT', '/api/consumptions/a1', item);
    await send('PUT', '/api/consumptions/a1', {...item, 'sodiumMg': 900});

    final all = await getAll();
    expect(all, hasLength(1));
    expect(all.single['sodiumMg'], 900);
  });

  test('menolak JSON rusak dan data tidak valid', () async {
    expect((await send('PUT', '/api/consumptions/a1', '{rusak')).statusCode, 400);
    expect((await send('PUT', '/api/consumptions/a1', {...item, 'sodiumMg': -1})).statusCode, 422);
    expect((await send('PUT', '/api/consumptions/b2', item)).statusCode, 422);
    expect(await getAll(), isEmpty);
  });

  test('DELETE menghapus data, id yang tidak ada menghasilkan 404', () async {
    await send('PUT', '/api/consumptions/a1', item);

    expect((await send('DELETE', '/api/consumptions/a1')).statusCode, 204);
    expect((await send('DELETE', '/api/consumptions/a1')).statusCode, 404);
  });
}
