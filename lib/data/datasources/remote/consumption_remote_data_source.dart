import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/food_consumption_model.dart';

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ConsumptionRemoteDataSource {
  ConsumptionRemoteDataSource(this._client, {required this.baseUrl, this.timeout = const Duration(seconds: 10)});

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  Uri _uri(String path) => Uri.parse('$baseUrl/api/consumptions$path');

  Future<List<FoodConsumptionModel>> fetchAll() async {
    final response = await _client.get(_uri('')).timeout(timeout);
    _ensureSuccess(response);

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['data'] is! List) {
      throw const FormatException('Respons server tidak memiliki daftar "data".');
    }
    return (body['data'] as List).map(FoodConsumptionModel.fromJson).toList();
  }

  Future<void> upsert(FoodConsumptionModel model) async {
    final response = await _client
        .put(
          _uri('/${Uri.encodeComponent(model.id)}'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(model.toJson()),
        )
        .timeout(timeout);
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(response.statusCode, 'Server merespons ${response.statusCode}');
  }
}
