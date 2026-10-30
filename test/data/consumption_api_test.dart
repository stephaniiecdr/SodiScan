import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/data/datasources/remote/consumption_remote_data_source.dart';
import 'package:sodiscan/data/models/food_consumption_model.dart';
import 'package:sodiscan/data/repositories/consumption_sync_repository_impl.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';

import '../helpers/fake_consumption_repository.dart';

void main() {
  const baseUrl = 'http://localhost:8080';

  final validJson = {
    'id': 'indomie-1',
    'barcode': '089686010947',
    'productName': 'Indomie Mi Goreng',
    'sodiumMg': 750,
    'source': 'scan',
    'consumedAt': '2026-10-01T10:30:00.000',
  };

  late List<http.Request> requests;

  ConsumptionRemoteDataSource dataSource(http.Response Function() respond) {
    requests = [];
    return ConsumptionRemoteDataSource(
      MockClient((request) async {
        requests.add(request);
        return respond();
      }),
      baseUrl: baseUrl,
    );
  }

  group('Unit test wajib Pertemuan 6', () {
    test('1. Model valid: JSON lengkap diubah menjadi model dan entity', () {
      final model = FoodConsumptionModel.fromJson(validJson);
      final entity = model.toEntity();

      expect(entity.id, 'indomie-1');
      expect(entity.barcode, '089686010947');
      expect(entity.productName, 'Indomie Mi Goreng');
      expect(entity.sodiumMg, 750);
      expect(entity.source, ConsumptionSource.scan);
      expect(entity.consumedAt, DateTime(2026, 10, 1, 10, 30));
      expect(model.toJson(), validJson);
    });

    test('2. Model invalid: field wajib hilang atau salah tipe ditolak dengan FormatException', () {
      final invalidSamples = <Object?>[
        null,
        'bukan objek',
        {...validJson}..remove('id'),
        {...validJson, 'productName': '   '},
        {...validJson, 'sodiumMg': -5},
        {...validJson, 'sodiumMg': '750'},
        {...validJson, 'source': 'robot'},
        {...validJson, 'consumedAt': 'kemarin'},
      ];

      for (final sample in invalidSamples) {
        expect(() => FoodConsumptionModel.fromJson(sample), throwsFormatException, reason: '$sample');
      }
    });

    test('3. API sukses: GET memuat daftar dan PUT mengirim JSON ke endpoint yang benar', () async {
      final source = dataSource(() => http.Response(jsonEncode({'data': [validJson]}), 200));

      final items = await source.fetchAll();
      await source.upsert(FoodConsumptionModel.fromJson(validJson));

      expect(items.single.productName, 'Indomie Mi Goreng');
      expect(requests.first.method, 'GET');
      expect(requests.first.url.toString(), '$baseUrl/api/consumptions');
      expect(requests.last.method, 'PUT');
      expect(requests.last.url.toString(), '$baseUrl/api/consumptions/indomie-1');
      expect(requests.last.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(requests.last.body), validJson);
    });

    test('4. Data kosong: server mengembalikan daftar kosong', () async {
      final repository = ConsumptionSyncRepositoryImpl(dataSource(() => http.Response('{"data": []}', 200)));

      expect(await repository.fetchFromServer(), isEmpty);
    });

    test('5. HTTP gagal: status 500, offline, dan timeout menjadi NetworkFailure', () async {
      final serverError = dataSource(() => http.Response('{"error":"internal"}', 500));
      final offline = ConsumptionRemoteDataSource(
        MockClient((request) => throw http.ClientException('offline', request.url)),
        baseUrl: baseUrl,
      );
      final slow = ConsumptionRemoteDataSource(
        MockClient((_) => Future.delayed(const Duration(milliseconds: 200), () => http.Response('{"data":[]}', 200))),
        baseUrl: baseUrl,
        timeout: const Duration(milliseconds: 20),
      );

      await expectLater(serverError.fetchAll(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 500)));
      for (final source in [serverError, offline, slow]) {
        await expectLater(
          ConsumptionSyncRepositoryImpl(source).fetchFromServer(),
          throwsA(isA<NetworkFailure>()),
        );
      }
      await expectLater(
        ConsumptionSyncRepositoryImpl(serverError).uploadToServer(indomieConsumption()),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('6. JSON rusak: body bukan JSON, tanpa "data", atau item tidak valid menjadi DataFormatFailure', () async {
      final bodies = [
        '{"data": [',
        '<html>Bad Gateway</html>',
        '{"items": []}',
        jsonEncode({'data': [{...validJson, 'sodiumMg': null}]}),
      ];

      for (final body in bodies) {
        final repository = ConsumptionSyncRepositoryImpl(dataSource(() => http.Response(body, 200)));
        await expectLater(repository.fetchFromServer(), throwsA(isA<DataFormatFailure>()), reason: body);
      }
    });
  });
}
