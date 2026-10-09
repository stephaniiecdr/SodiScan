const String productNameRequiredMessage = 'Nama makanan wajib diisi.';
const String sodiumRequiredMessage = 'Jumlah sodium wajib diisi.';
const String sodiumNotNumberMessage = 'Jumlah sodium harus berupa angka.';
const String sodiumNotPositiveMessage = 'Jumlah sodium harus lebih dari 0.';

int? parseSodiumMg(String? input) => int.tryParse(input?.trim() ?? '');

String? validateProductName(String? value) {
  if (value == null || value.trim().isEmpty) return productNameRequiredMessage;
  return null;
}

String? validateSodiumMg(String? value) {
  if (value == null || value.trim().isEmpty) return sodiumRequiredMessage;
  final sodium = parseSodiumMg(value);
  if (sodium == null) return sodiumNotNumberMessage;
  if (sodium <= 0) return sodiumNotPositiveMessage;
  return null;
}
