import 'package:flutter/material.dart';

import '../../../domain/entities/food_consumption.dart';
import 'consumption_form.dart';

class AddConsumptionScreen extends StatelessWidget {
  const AddConsumptionScreen({super.key, this.consumption});

  final FoodConsumption? consumption;

  static Route<bool> route({FoodConsumption? consumption}) {
    return MaterialPageRoute<bool>(builder: (_) => AddConsumptionScreen(consumption: consumption));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(consumption == null ? 'Input Manual' : 'Edit Konsumsi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            consumption == null
                ? 'Gunakan Input Manual jika produk tidak ditemukan atau Anda sedang offline.'
                : 'Perbaiki nama makanan atau jumlah sodium yang salah input. Waktu konsumsi tidak berubah.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ConsumptionForm(initial: consumption),
        ],
      ),
    );
  }
}
