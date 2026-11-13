bool isBlank(String? value) => value == null || value.trim().isEmpty;

int? parseInteger(String? input) => int.tryParse(input?.trim() ?? '');

double? parseDecimal(String? input) {
  final value = double.tryParse(input?.trim().replaceAll(',', '.') ?? '');
  if (value == null || !value.isFinite) return null;
  return value;
}

String requiredMessage(String label) => '$label wajib diisi.';

String notNumberMessage(String label) => '$label harus berupa angka.';

String notPositiveMessage(String label) => '$label harus lebih dari 0.';

String? validatePositiveNumber(String? value, {required String label, required num? Function(String?) parse}) {
  if (isBlank(value)) return requiredMessage(label);
  final number = parse(value);
  if (number == null) return notNumberMessage(label);
  if (number <= 0) return notPositiveMessage(label);
  return null;
}
