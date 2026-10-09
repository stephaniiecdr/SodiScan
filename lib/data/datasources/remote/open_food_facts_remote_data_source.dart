import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/product_model.dart';

class OpenFoodFactsRemoteDataSource {
  OpenFoodFactsRemoteDataSource(this._client, {this.timeout = const Duration(seconds: 10)});

  static const String _host = 'world.openfoodfacts.org';
  static const String _fields = 'code,product_name,brands,serving_size,nutriments';

  final http.Client _client;
  final Duration timeout;

  Future<ProductModel?> fetchProduct(String barcode) async {
    final uri = Uri.https(_host, '/api/v2/product/$barcode.json', {'fields': _fields});
    final response = await _client.get(uri).timeout(timeout);

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw http.ClientException('Open Food Facts merespons ${response.statusCode}', uri);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final product = body['product'];
    if (body['status'] != 1 || product is! Map<String, dynamic>) return null;

    return ProductModel.fromOpenFoodFactsJson(barcode, product);
  }
}
