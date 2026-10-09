import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/food_consumption.dart';
import '../../domain/usecases/get_product_by_barcode.dart';
import '../../domain/usecases/record_consumption.dart';
import 'product_lookup_state.dart';

class ProductLookupNotifier extends ChangeNotifier {
  ProductLookupNotifier({
    required GetProductByBarcode getProductByBarcode,
    required RecordConsumption recordConsumption,
  })  : _getProductByBarcode = getProductByBarcode,
        _recordConsumption = recordConsumption;

  static const String notFoundText = 'Produk dengan barcode ini belum ada di Open Food Facts.';
  static const String noSodiumText = 'Produk ditemukan, tetapi data natriumnya tidak tersedia.';
  static const String networkErrorText = 'Data produk tidak dapat dimuat. Periksa koneksi internet Anda.';
  static const String submitErrorText = 'Konsumsi gagal disimpan. Silakan coba lagi.';

  final GetProductByBarcode _getProductByBarcode;
  final RecordConsumption _recordConsumption;

  ProductLookupState _state = const ProductLookupState();
  bool _isDisposed = false;

  ProductLookupState get state => _state;

  Future<void> search(String barcode) async {
    if (_state.status == LookupStatus.loading || _state.isSubmitting) return;
    final code = barcode.trim();
    _emit(ProductLookupState(status: LookupStatus.loading, barcode: code));

    try {
      final product = await _getProductByBarcode(code);
      if (product == null) {
        _emit(_state.copyWith(status: LookupStatus.empty, message: notFoundText));
      } else if (!product.hasSodiumData) {
        _emit(_state.copyWith(status: LookupStatus.empty, product: product, message: noSodiumText));
      } else {
        _emit(_state.copyWith(status: LookupStatus.success, product: product, clearMessage: true));
      }
    } on ValidationFailure catch (failure) {
      _emit(_state.copyWith(status: LookupStatus.error, message: failure.message));
    } on Exception {
      _emit(_state.copyWith(status: LookupStatus.error, message: networkErrorText));
    }
  }

  Future<void> retry() async {
    final barcode = _state.barcode;
    if (barcode == null) return;
    await search(barcode);
  }

  Future<bool> submit(double amount) async {
    final product = _state.product;
    if (_state.isSubmitting || _state.status != LookupStatus.success || product == null) return false;
    _emit(_state.copyWith(isSubmitting: true, clearSubmitError: true));

    try {
      await _recordConsumption(
        productName: product.name,
        sodiumMg: product.sodiumFor(amount),
        source: ConsumptionSource.scan,
        barcode: product.barcode,
      );
    } on ValidationFailure catch (failure) {
      _emit(_state.copyWith(isSubmitting: false, submitErrorMessage: failure.message));
      return false;
    } on Exception {
      _emit(_state.copyWith(isSubmitting: false, submitErrorMessage: submitErrorText));
      return false;
    }

    _emit(_state.copyWith(isSubmitting: false));
    return true;
  }

  void _emit(ProductLookupState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
