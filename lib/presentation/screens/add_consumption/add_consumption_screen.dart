import 'package:flutter/material.dart';

import 'consumption_form.dart';

class AddConsumptionScreen extends StatelessWidget {
  const AddConsumptionScreen({super.key});

  static Route<bool> route() => MaterialPageRoute<bool>(builder: (_) => const AddConsumptionScreen());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Manual')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Gunakan Input Manual jika produk tidak ditemukan atau Anda sedang offline.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const ConsumptionForm(),
        ],
      ),
    );
  }
}
