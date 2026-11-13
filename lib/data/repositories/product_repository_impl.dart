import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/remote/open_food_facts_remote_data_source.dart';
import 'repository_guard.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDataSource);

  final OpenFoodFactsRemoteDataSource _remoteDataSource;

  @override
  Future<Product?> getProductByBarcode(String barcode) {
    return guardRemote('mengambil data produk', () async {
      final model = await _remoteDataSource.fetchProduct(barcode);
      return model?.toEntity();
    });
  }
}
