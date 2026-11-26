import '../../core/constants/sodium_constants.dart';
import '../../core/errors/failures.dart';
import 'input_rules.dart';

const String _sodiumLabel = 'Jumlah sodium';

const String productNameRequiredMessage = 'Nama makanan wajib diisi.';
const String sodiumRequiredMessage = '$_sodiumLabel wajib diisi.';
const String sodiumNotNumberMessage = '$_sodiumLabel harus berupa angka.';
const String sodiumNotPositiveMessage = '$_sodiumLabel harus lebih dari 0.';
const String sodiumTooLargeMessage = '$_sodiumLabel maksimal 10000 mg per catatan.';

const int maxProductNameLength = 80;
const String productNameTooLongMessage = 'Nama makanan maksimal $maxProductNameLength karakter.';

int? parseSodiumMg(String? input) => parseInteger(input);

String? validateProductName(String? value) {
  if (isBlank(value)) return productNameRequiredMessage;
  if (value!.trim().length > maxProductNameLength) return productNameTooLongMessage;
  return null;
}

String? validateSodiumMg(String? value) {
  final error = validatePositiveNumber(value, label: _sodiumLabel, parse: parseSodiumMg);
  return error ?? sodiumRangeError(parseSodiumMg(value)!);
}

/// Nama produk dari Open Food Facts bisa sangat panjang; dipotong agar lolos validasi.
String clampProductName(String name) {
  final trimmed = name.trim();
  return trimmed.length <= maxProductNameLength ? trimmed : trimmed.substring(0, maxProductNameLength).trimRight();
}

String? sodiumRangeError(num sodiumMg) {
  if (sodiumMg.isNaN || sodiumMg <= 0) return sodiumNotPositiveMessage;
  if (sodiumMg.isInfinite || sodiumMg > maxSodiumPerEntryMg) return sodiumTooLargeMessage;
  return null;
}

String validateConsumptionInput({required String productName, required double sodiumMg}) {
  final error = validateProductName(productName) ?? sodiumRangeError(sodiumMg);
  if (error != null) throw ValidationFailure(error);
  return productName.trim();
}
