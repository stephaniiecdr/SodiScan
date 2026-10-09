import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/product.dart';
import 'package:sodiscan/domain/usecases/get_product_by_barcode.dart';

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
}
