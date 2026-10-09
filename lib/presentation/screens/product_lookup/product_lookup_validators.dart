import '../../../domain/entities/product.dart';
import '../../../domain/usecases/get_product_by_barcode.dart';

const String barcodeRequiredMessage = 'Kode barcode wajib diisi.';
const String barcodeNotNumberMessage = 'Kode barcode hanya boleh berisi angka.';
const String barcodeLengthMessage = 'Kode barcode harus 8 sampai 13 digit.';

String? validateBarcode(String? value) {
  final code = value?.trim() ?? '';
  if (code.isEmpty) return barcodeRequiredMessage;
  if (!RegExp(r'^\d+$').hasMatch(code)) return barcodeNotNumberMessage;
  if (!GetProductByBarcode.isValidBarcode(code)) return barcodeLengthMessage;
  return null;
}

String amountLabel(ConsumptionUnit unit) => unit == ConsumptionUnit.serving ? 'Jumlah porsi' : 'Berat';

double? parseAmount(String? input) {
  final value = double.tryParse(input?.trim().replaceAll(',', '.') ?? '');
  if (value == null || !value.isFinite) return null;
  return value;
}

String? validateAmount(String? value, ConsumptionUnit unit) {
  final label = amountLabel(unit);
  if (value == null || value.trim().isEmpty) return '$label wajib diisi.';
  final amount = parseAmount(value);
  if (amount == null) return '$label harus berupa angka.';
  if (amount <= 0) return '$label harus lebih dari 0.';
  return null;
}
