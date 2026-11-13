import '../../core/errors/failures.dart';
import '../../domain/entities/food_consumption.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_product_by_barcode.dart';
import '../../domain/usecases/record_consumption.dart';
import 'base_notifier.dart';
import 'product_lookup_state.dart';

class ProductLookupNotifier extends StateNotifier<ProductLookupState> {
  ProductLookupNotifier({
    required GetProductByBarcode getProductByBarcode,
    required RecordConsumption recordConsumption,
  })  : _getProductByBarcode = getProductByBarcode,
        _recordConsumption = recordConsumption,
        super(const ProductLookupState());

  static const String notFoundText = 'Produk dengan barcode ini belum ada di Open Food Facts.';
  static const String noSodiumText = 'Produk ditemukan, tetapi data natriumnya tidak tersedia.';
  static const String networkErrorText = 'Data produk tidak dapat dimuat. Periksa koneksi internet Anda.';
  static const String submitErrorText = 'Konsumsi gagal disimpan. Silakan coba lagi.';

  final GetProductByBarcode _getProductByBarcode;
  final RecordConsumption _recordConsumption;

  Future<void> search(String barcode) async {
    if (state.status == LookupStatus.loading || state.isSubmitting) return;
    final code = barcode.trim();
    emit(ProductLookupState(status: LookupStatus.loading, barcode: code));

    try {
      emit(_resultFor(await _getProductByBarcode(code)));
    } on ValidationFailure catch (failure) {
      emit(state.copyWith(status: LookupStatus.error, message: failure.message));
    } on Exception {
      emit(state.copyWith(status: LookupStatus.error, message: networkErrorText));
    }
  }

  Future<void> retry() async {
    final barcode = state.barcode;
    if (barcode == null) return;
    await search(barcode);
  }

  Future<bool> submit(double amount) async {
    final product = state.product;
    if (state.isSubmitting || state.status != LookupStatus.success || product == null) return false;
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true));

    final error = await runSubmit(
      () => _recordConsumption(
        productName: product.name,
        sodiumMg: product.sodiumFor(amount),
        source: ConsumptionSource.scan,
        barcode: product.barcode,
      ),
      fallbackMessage: submitErrorText,
    );
    emit(state.copyWith(isSubmitting: false, submitErrorMessage: error));
    return error == null;
  }

  ProductLookupState _resultFor(Product? product) {
    if (product == null) return state.copyWith(status: LookupStatus.empty, message: notFoundText);
    if (!product.hasSodiumData) {
      return state.copyWith(status: LookupStatus.empty, product: product, message: noSodiumText);
    }
    return state.copyWith(status: LookupStatus.success, product: product, clearMessage: true);
  }
}
