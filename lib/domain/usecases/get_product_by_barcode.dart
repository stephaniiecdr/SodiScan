import '../../core/errors/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductByBarcode {
  const GetProductByBarcode(this._repository);

  static final RegExp _barcodePattern = RegExp(r'^\d{8,13}$');

  final ProductRepository _repository;

  static bool isValidBarcode(String barcode) => _barcodePattern.hasMatch(barcode.trim());

  Future<Product?> call(String barcode) {
    final code = barcode.trim();
    if (!isValidBarcode(code)) {
      throw const ValidationFailure('Kode barcode harus 8 sampai 13 digit angka.');
    }
    return _repository.getProductByBarcode(code);
  }
}
