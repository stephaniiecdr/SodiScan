import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'consumption_store.dart';

const _jsonHeaders = {'content-type': 'application/json'};
const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, PUT, DELETE, OPTIONS',
  'access-control-allow-headers': 'content-type',
};

/// Batas yang sama dengan validasi di aplikasi (lib/domain/validation/consumption_rules.dart).
const num maxSodiumMg = 10000;
const int maxProductNameLength = 80;

Handler buildHandler(ConsumptionStore store) {
  final router = Router()
    ..get('/api/health', (Request request) => _json({'status': 'ok'}))
    ..get('/api/consumptions', (Request request) async => _json({'data': await store.readAll()}))
    ..put('/api/consumptions/<id>', (Request request, String id) async {
      final Object? body;
      try {
        body = jsonDecode(await request.readAsString());
      } on FormatException {
        return _json({'error': 'Body bukan JSON yang valid.'}, status: 400);
      }
      final error = validateConsumption(body, id);
      if (error != null) return _json({'error': error}, status: 422);
      return _json({'data': await store.upsert(body as Map<String, dynamic>)});
    })
    ..delete('/api/consumptions/<id>', (Request request, String id) async {
      final deleted = await store.delete(id);
      return deleted ? Response(204, headers: _corsHeaders) : _json({'error': 'Data tidak ditemukan.'}, status: 404);
    });

  return const Pipeline().addMiddleware(logRequests()).addMiddleware(_cors()).addHandler(router.call);
}

String? validateConsumption(Object? body, String id) {
  if (body is! Map<String, dynamic>) return 'Body harus berupa objek JSON.';
  if (body['id'] != id) return 'Field id harus sama dengan id di URL.';
  final name = body['productName'];
  if (name is! String || name.trim().isEmpty) return 'productName wajib diisi.';
  if (name.trim().length > maxProductNameLength) return 'productName maksimal $maxProductNameLength karakter.';
  final sodium = body['sodiumMg'];
  if (sodium is! num || !sodium.isFinite || sodium <= 0) return 'sodiumMg harus angka lebih dari 0.';
  if (sodium > maxSodiumMg) return 'sodiumMg maksimal $maxSodiumMg mg per catatan.';
  if (body['source'] != 'scan' && body['source'] != 'manual') return 'source harus scan atau manual.';
  final consumedAt = body['consumedAt'];
  if (consumedAt is! String || DateTime.tryParse(consumedAt) == null) return 'consumedAt harus tanggal ISO 8601.';
  final updatedAt = body['updatedAt'];
  if (updatedAt != null && (updatedAt is! String || DateTime.tryParse(updatedAt) == null)) {
    return 'updatedAt harus tanggal ISO 8601 atau null.';
  }
  return null;
}

Response _json(Object body, {int status = 200}) {
  return Response(status, body: jsonEncode(body), headers: {..._jsonHeaders, ..._corsHeaders});
}

Middleware _cors() {
  return (inner) => (request) {
        if (request.method == 'OPTIONS') return Response.ok(null, headers: _corsHeaders);
        return inner(request);
      };
}
