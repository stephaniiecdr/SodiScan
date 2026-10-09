import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/data/datasources/remote/open_food_facts_remote_data_source.dart';
import 'package:sodiscan/data/repositories/product_repository_impl.dart';

void main() {
  const barcode = '089686010947';
  late Uri requestedUri;

  OpenFoodFactsRemoteDataSource dataSource(http.Response Function() respond) {
    return OpenFoodFactsRemoteDataSource(
      MockClient((request) async {
        requestedUri = request.url;
        return respond();
      }),
    );
  }

  test('mengambil produk dan mengubah natrium dari gram ke mg', () async {
    final body = jsonEncode({
      'code': barcode,
      'status': 1,
      'status_verbose': 'product found',
      'product': {
        'product_name': 'Indomie Mi Goreng',
        'brands': 'Indomie',
        'serving_size': '85 g',
        'nutriments': {'sodium_100g': 0.882, 'sodium_serving': 0.75, 'sodium_unit': 'g'},
      },
    });

    final model = await dataSource(() => http.Response(body, 200)).fetchProduct(barcode);

    expect(requestedUri.host, 'world.openfoodfacts.org');
    expect(requestedUri.path, '/api/v2/product/$barcode.json');
    expect(model!.name, 'Indomie Mi Goreng');
    expect(model.brand, 'Indomie');
    expect(model.servingSize, '85 g');
    expect(model.sodiumPer100gMg, closeTo(882, 0.001));
    expect(model.sodiumPerServingMg, closeTo(750, 0.001));
  });

  test('produk tanpa data natrium menghasilkan nilai natrium null', () async {
    final body = jsonEncode({
      'status': 1,
      'product': {'product_name': 'Air Mineral', 'nutriments': <String, dynamic>{}},
    });

    final model = await dataSource(() => http.Response(body, 200)).fetchProduct(barcode);

    expect(model!.sodiumPer100gMg, isNull);
    expect(model.sodiumPerServingMg, isNull);
    expect(model.toEntity().hasSodiumData, isFalse);
  });

  test('status 404 atau status 0 berarti produk tidak ditemukan', () async {
    final notFound = jsonEncode({'code': barcode, 'status': 0, 'status_verbose': 'product not found'});

    expect(await dataSource(() => http.Response(notFound, 404)).fetchProduct(barcode), isNull);
    expect(await dataSource(() => http.Response(notFound, 200)).fetchProduct(barcode), isNull);
  });

  test('repository mengubah error server dan timeout menjadi NetworkFailure', () async {
    final serverError = ProductRepositoryImpl(dataSource(() => http.Response('error', 500)));
    final slowServer = ProductRepositoryImpl(
      OpenFoodFactsRemoteDataSource(
        MockClient((_) => Future.delayed(const Duration(milliseconds: 200), () => http.Response('{}', 200))),
        timeout: const Duration(milliseconds: 20),
      ),
    );
    final offline = ProductRepositoryImpl(
      OpenFoodFactsRemoteDataSource(MockClient((request) => throw http.ClientException('offline', request.url))),
    );

    await expectLater(serverError.getProductByBarcode(barcode), throwsA(isA<NetworkFailure>()));
    await expectLater(slowServer.getProductByBarcode(barcode), throwsA(isA<NetworkFailure>()));
    await expectLater(offline.getProductByBarcode(barcode), throwsA(isA<NetworkFailure>()));
  });
}
