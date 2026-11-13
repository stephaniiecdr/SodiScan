import '../entities/product.dart';
import 'input_rules.dart';

const String barcodeRequiredMessage = 'Kode barcode wajib diisi.';
const String barcodeNotNumberMessage = 'Kode barcode hanya boleh berisi angka.';
const String barcodeLengthMessage = 'Kode barcode harus 8 sampai 13 digit.';

final RegExp _digitsPattern = RegExp(r'^\d+$');
final RegExp _barcodePattern = RegExp(r'^\d{8,13}$');

bool isValidBarcode(String barcode) => _barcodePattern.hasMatch(barcode.trim());

String? validateBarcode(String? value) {
  final code = value?.trim() ?? '';
  if (code.isEmpty) return barcodeRequiredMessage;
  if (!_digitsPattern.hasMatch(code)) return barcodeNotNumberMessage;
  if (!isValidBarcode(code)) return barcodeLengthMessage;
  return null;
}

String amountLabel(ConsumptionUnit unit) => unit == ConsumptionUnit.serving ? 'Jumlah porsi' : 'Berat';

double? parseAmount(String? input) => parseDecimal(input);

String? validateAmount(String? value, ConsumptionUnit unit) {
  return validatePositiveNumber(value, label: amountLabel(unit), parse: parseAmount);
}
