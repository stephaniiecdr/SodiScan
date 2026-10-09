import 'dart:async';

import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/domain/entities/product.dart';
import 'package:sodiscan/domain/repositories/product_repository.dart';

class FakeProductRepository implements ProductRepository {
  FakeProductRepository({this.product});

  Product? product;
  bool failLookup = false;
  Completer<void>? lookupGate;
  int lookupCalls = 0;
  String? lastBarcode;

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    lookupCalls++;
    lastBarcode = barcode;
    if (lookupGate != null) await lookupGate!.future;
    if (failLookup) throw const NetworkFailure('lookup failed');
    return product;
  }
}

const indomieProduct = Product(
  barcode: '089686010947',
  name: 'Indomie Mi Goreng',
  brand: 'Indomie',
  servingSize: '85 g',
  sodiumPer100gMg: 882,
  sodiumPerServingMg: 750,
);

const chitatoProduct = Product(
  barcode: '089686600742',
  name: 'Chitato Sapi Panggang',
  brand: 'Chitato',
  sodiumPer100gMg: 520,
);

const noSodiumProduct = Product(barcode: '8991002101234', name: 'Air Mineral 600 ml', brand: 'Contoh');
