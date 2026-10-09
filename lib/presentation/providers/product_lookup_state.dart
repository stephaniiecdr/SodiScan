import '../../domain/entities/product.dart';

enum LookupStatus { idle, loading, success, empty, error }

class ProductLookupState {
  const ProductLookupState({
    this.status = LookupStatus.idle,
    this.barcode,
    this.product,
    this.message,
    this.isSubmitting = false,
    this.submitErrorMessage,
  });

  final LookupStatus status;
  final String? barcode;
  final Product? product;
  final String? message;
  final bool isSubmitting;
  final String? submitErrorMessage;

  ProductLookupState copyWith({
    LookupStatus? status,
    String? barcode,
    Product? product,
    String? message,
    bool? isSubmitting,
    String? submitErrorMessage,
    bool clearProduct = false,
    bool clearMessage = false,
    bool clearSubmitError = false,
  }) {
    return ProductLookupState(
      status: status ?? this.status,
      barcode: barcode ?? this.barcode,
      product: clearProduct ? null : product ?? this.product,
      message: clearMessage ? null : message ?? this.message,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitErrorMessage: clearSubmitError ? null : submitErrorMessage ?? this.submitErrorMessage,
    );
  }
}
