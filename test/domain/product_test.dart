import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/entities/product.dart';
import 'package:sodiscan/domain/usecases/get_product_by_barcode.dart';

import '../helpers/fake_consumption_repository.dart';
import '../helpers/fake_product_repository.dart';

void main() {
  group('Product', () {
    test('memakai data per saji jika tersedia', () {
      expect(indomieProduct.unit, ConsumptionUnit.serving);
      expect(indomieProduct.sodiumFor(2), 1500);
      expect(indomieProduct.sodiumFor(0.5), 375);
    });

    test('memakai data per 100 g jika data per saji tidak ada', () {
      expect(chitatoProduct.unit, ConsumptionUnit.gram);
      expect(chitatoProduct.sodiumFor(50), 260);
    });

    test('mendeteksi produk tanpa data natrium', () {
      expect(indomieProduct.hasSodiumData, isTrue);
      expect(noSodiumProduct.hasSodiumData, isFalse);
    });
  });

  group('GetProductByBarcode', () {
    test('meneruskan barcode valid yang sudah di-trim ke repository', () async {
      final repository = FakeProductRepository(product: indomieProduct);

      final product = await GetProductByBarcode(repository)(' 089686010947 ');

      expect(product, indomieProduct);
      expect(repository.lastBarcode, '089686010947');
    });

    test('menolak barcode yang bukan 8 sampai 13 digit angka tanpa memanggil repository', () {
      final repository = FakeProductRepository(product: indomieProduct);
      final getProduct = GetProductByBarcode(repository);

      for (final barcode in ['', 'abc', '1234567', '12345678901234', '12345abc']) {
        expect(() => getProduct(barcode), throwsA(isA<ValidationFailure>()));
      }
      expect(repository.lookupCalls, 0);
    });
  });

  group('GetProductByBarcode - ingat produk dari Input Manual', () {
    FoodConsumption record(
      String id, {
      String? barcode = '8991002101234',
      String name = 'Air Mineral 600 ml',
      double sodium = 15,
      ConsumptionSource source = ConsumptionSource.manual,
      DateTime? consumedAt,
      DateTime? updatedAt,
    }) {
      return FoodConsumption(
        id: id,
        barcode: barcode,
        productName: name,
        sodiumMg: sodium,
        source: source,
        consumedAt: consumedAt ?? DateTime(2026, 10, 1, 8),
        updatedAt: updatedAt,
      );
    }

    test('barcode yang pernah diinput manual dikenali tanpa memanggil Open Food Facts', () async {
      final products = FakeProductRepository();
      final history = FakeConsumptionRepository(items: [record('a')]);

      final product = await GetProductByBarcode(products, history: history)('8991002101234');

      expect(product, isNotNull);
      expect(product!.isFromHistory, isTrue);
      expect(product.name, 'Air Mineral 600 ml');
      expect(product.sodiumPerServingMg, 15);
      expect(product.unit, ConsumptionUnit.serving);
      expect(product.sodiumFor(2), 30);
      expect(products.lookupCalls, 0);
    });

    test('memakai catatan manual yang paling baru diubah', () async {
      final history = FakeConsumptionRepository(items: [
        record('lama', sodium: 15, consumedAt: DateTime(2026, 10, 1)),
        record('baru', sodium: 20, consumedAt: DateTime(2026, 10, 2)),
        record('diedit', sodium: 25, consumedAt: DateTime(2026, 9, 30), updatedAt: DateTime(2026, 10, 3)),
      ]);

      final product = await GetProductByBarcode(FakeProductRepository(), history: history)('8991002101234');

      expect(product!.sodiumPerServingMg, 25);
    });

    test('catatan hasil scan dan catatan tanpa barcode diabaikan, lalu lanjut ke Open Food Facts', () async {
      final products = FakeProductRepository(product: noSodiumProduct);
      final history = FakeConsumptionRepository(items: [
        record('scan', source: ConsumptionSource.scan, sodium: 1500),
        record('tanpa-barcode', barcode: null),
        record('barcode-lain', barcode: '12345678'),
      ]);

      final product = await GetProductByBarcode(products, history: history)('8991002101234');

      expect(product, noSodiumProduct);
      expect(product!.isFromHistory, isFalse);
      expect(products.lookupCalls, 1);
    });

    test('penyimpanan lokal gagal dibaca tetap lanjut ke Open Food Facts', () async {
      final products = FakeProductRepository(product: indomieProduct);
      final history = FakeConsumptionRepository()..failLoad = true;

      final product = await GetProductByBarcode(products, history: history)('089686010947');

      expect(product, indomieProduct);
    });
  });
}
