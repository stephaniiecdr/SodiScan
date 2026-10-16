import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'domain/repositories/consumption_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'domain/usecases/delete_consumption.dart';
import 'domain/usecases/get_consumption_history.dart';
import 'domain/usecases/get_daily_summary.dart';
import 'domain/usecases/get_product_by_barcode.dart';
import 'domain/usecases/record_consumption.dart';
import 'presentation/providers/add_consumption_notifier.dart';
import 'presentation/screens/home/home_screen.dart';

class SodiScanApp extends StatelessWidget {
  const SodiScanApp({super.key, required this.consumptionRepository, required this.productRepository});

  final ConsumptionRepository consumptionRepository;
  final ProductRepository productRepository;

  @override
  Widget build(BuildContext context) {
    final recordConsumption = RecordConsumption(consumptionRepository);

    return MultiProvider(
      providers: [
        Provider.value(value: recordConsumption),
        Provider.value(value: GetProductByBarcode(productRepository)),
        Provider.value(value: GetConsumptionHistory(consumptionRepository)),
        ChangeNotifierProvider(
          create: (_) => AddConsumptionNotifier(
            getDailySummary: GetDailySummary(consumptionRepository),
            recordConsumption: recordConsumption,
            deleteConsumption: DeleteConsumption(consumptionRepository),
          )..load(),
        ),
      ],
      child: MaterialApp(
        title: 'SodiScan',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
