import 'package:flutter/material.dart';

import '../../../domain/entities/food_consumption.dart';
import '../../providers/manual_entry_draft.dart';
import '../../widgets/adaptive_layout.dart';
import 'consumption_form.dart';

class AddConsumptionScreen extends StatelessWidget {
  const AddConsumptionScreen({super.key, this.consumption, this.draft});

  final FoodConsumption? consumption;

  /// Isian awal saat datang dari pencarian produk yang tidak berhasil.
  final ManualEntryDraft? draft;

  static Route<bool> route({FoodConsumption? consumption, ManualEntryDraft? draft}) {
    return MaterialPageRoute<bool>(
      settings: RouteSettings(name: consumption == null ? '/consumption/add' : '/consumption/edit'),
      builder: (_) => AddConsumptionScreen(consumption: consumption, draft: draft),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barcode = draft?.barcode;

    return Scaffold(
      appBar: AppBar(title: Text(consumption == null ? 'Input Manual' : 'Edit Konsumsi')),
      body: ListView(
        padding: adaptivePadding(context),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(
            consumption != null
                ? 'Perbaiki nama makanan atau jumlah sodium yang salah input. Waktu konsumsi tidak berubah.'
                : barcode != null
                    ? 'Data natrium untuk barcode $barcode belum tersedia. '
                        'Isi jumlah sodium sesuai label Informasi Nilai Gizi di kemasan.'
                    : 'Gunakan Input Manual jika produk tidak ditemukan atau Anda sedang offline.',
            key: const Key('manualEntryIntro'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ConsumptionForm(initial: consumption, draft: draft),
        ],
      ),
    );
  }
}
