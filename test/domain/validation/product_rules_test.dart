import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/product.dart';
import 'package:sodiscan/domain/validation/consumption_rules.dart';
import 'package:sodiscan/domain/validation/input_rules.dart';
import 'package:sodiscan/domain/validation/product_rules.dart';

void main() {
  group('input_rules', () {
    test('parseDecimal menerima koma sebagai pemisah desimal dan menolak bukan angka', () {
      expect(parseDecimal(' 0,5 '), 0.5);
      expect(parseDecimal('1.25'), 1.25);
      expect(parseDecimal('abc'), isNull);
      expect(parseDecimal('Infinity'), isNull);
    });

    test('validatePositiveNumber memakai label yang sama untuk semua pesan', () {
      String? check(String? value) => validatePositiveNumber(value, label: 'Berat', parse: parseDecimal);
      expect(check(''), 'Berat wajib diisi.');
      expect(check('x'), 'Berat harus berupa angka.');
      expect(check('0'), 'Berat harus lebih dari 0.');
      expect(check('2'), isNull);
    });
  });

  group('validateBarcode', () {
    test('menerima 8 sampai 13 digit', () {
      expect(validateBarcode('12345678'), isNull);
      expect(validateBarcode(' 089686010947 '), isNull);
    });

    test('menolak kosong, huruf, dan panjang salah', () {
      expect(validateBarcode(null), barcodeRequiredMessage);
      expect(validateBarcode('12ab5678'), barcodeNotNumberMessage);
      expect(validateBarcode('1234567'), barcodeLengthMessage);
      expect(validateBarcode('12345678901234'), barcodeLengthMessage);
    });
  });

  group('validateAmount', () {
    test('label mengikuti satuan produk', () {
      expect(validateAmount('', ConsumptionUnit.serving), 'Jumlah porsi wajib diisi.');
      expect(validateAmount('-1', ConsumptionUnit.gram), 'Berat harus lebih dari 0.');
      expect(validateAmount('0,5', ConsumptionUnit.serving), isNull);
    });
  });

  group('validateConsumptionInput (dipakai use case)', () {
    test('memakai pesan yang sama dengan validator form', () {
      expect(
        () => validateConsumptionInput(productName: ' ', sodiumMg: 100),
        throwsA(isA<ValidationFailure>().having((f) => f.message, 'message', productNameRequiredMessage)),
      );
      expect(
        () => validateConsumptionInput(productName: 'Mi', sodiumMg: 10001),
        throwsA(isA<ValidationFailure>().having((f) => f.message, 'message', sodiumTooLargeMessage)),
      );
      expect(validateConsumptionInput(productName: '  Mi  ', sodiumMg: 100), 'Mi');
    });
  });
}
