import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/presentation/screens/add_consumption/consumption_form_validators.dart';

void main() {
  group('validateSodiumMg', () {
    test('menerima nilai 1 sampai 10000 mg', () {
      for (final value in ['1', '750', ' 10000 ']) {
        expect(validateSodiumMg(value), isNull);
      }
    });

    test('menolak nilai di atas 10000 mg', () {
      expect(validateSodiumMg('10001'), sodiumTooLargeMessage);
      expect(validateSodiumMg('75000'), sodiumTooLargeMessage);
    });

    test('menolak kosong, bukan angka, dan nol atau negatif', () {
      expect(validateSodiumMg(null), sodiumRequiredMessage);
      expect(validateSodiumMg('  '), sodiumRequiredMessage);
      expect(validateSodiumMg('abc'), sodiumNotNumberMessage);
      expect(validateSodiumMg('0'), sodiumNotPositiveMessage);
      expect(validateSodiumMg('-5'), sodiumNotPositiveMessage);
    });
  });

  group('validateProductName', () {
    test('menolak nama kosong dan menerima nama berisi', () {
      expect(validateProductName(''), productNameRequiredMessage);
      expect(validateProductName('   '), productNameRequiredMessage);
      expect(validateProductName('Indomie'), isNull);
    });
  });
}
