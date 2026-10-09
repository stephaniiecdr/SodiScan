import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'data/datasources/local/consumption_local_data_source.dart';
import 'data/datasources/remote/open_food_facts_remote_data_source.dart';
import 'data/repositories/consumption_repository_impl.dart';
import 'data/repositories/product_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox<Map>(ConsumptionLocalDataSource.boxName);

  runApp(
    SodiScanApp(
      consumptionRepository: ConsumptionRepositoryImpl(ConsumptionLocalDataSource(box)),
      productRepository: ProductRepositoryImpl(OpenFoodFactsRemoteDataSource(http.Client())),
    ),
  );
}
