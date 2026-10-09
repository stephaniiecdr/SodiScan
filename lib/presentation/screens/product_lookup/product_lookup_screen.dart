import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/usecases/get_product_by_barcode.dart';
import '../../../domain/usecases/record_consumption.dart';
import '../../providers/product_lookup_notifier.dart';
import '../../providers/product_lookup_state.dart';
import '../../widgets/state_message.dart';
import 'barcode_search_form.dart';
import 'portion_form.dart';
import 'product_info_card.dart';

class ProductLookupScreen extends StatelessWidget {
  const ProductLookupScreen({super.key});

  static Route<bool> route(BuildContext context) {
    final getProductByBarcode = context.read<GetProductByBarcode>();
    final recordConsumption = context.read<RecordConsumption>();

    return MaterialPageRoute<bool>(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => ProductLookupNotifier(
          getProductByBarcode: getProductByBarcode,
          recordConsumption: recordConsumption,
        ),
        child: const ProductLookupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProductLookupNotifier>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Produk')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const BarcodeSearchForm(),
          const SizedBox(height: 24),
          _LookupResult(state: state),
        ],
      ),
    );
  }
}

class _LookupResult extends StatelessWidget {
  const _LookupResult({required this.state});

  final ProductLookupState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      LookupStatus.idle => const StateMessage(
          icon: Icons.qr_code_scanner,
          title: 'Cari Produk Kemasan',
          message: 'Masukkan kode barcode untuk melihat kandungan natrium produk.',
        ),
      LookupStatus.loading => const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Mencari produk...'),
            ],
          ),
        ),
      LookupStatus.empty => StateMessage(
          icon: Icons.search_off,
          title: state.product == null ? 'Produk Tidak Ditemukan' : 'Data Natrium Tidak Tersedia',
          message: '${state.message} Gunakan Input Manual untuk mencatat konsumsi.',
          actionLabel: 'Input Manual',
          actionIcon: Icons.edit_note,
          onAction: () => Navigator.of(context).pop(false),
        ),
      LookupStatus.error => StateMessage(
          icon: Icons.wifi_off,
          title: 'Terjadi Kesalahan',
          message: state.message ?? ProductLookupNotifier.networkErrorText,
          actionLabel: 'Coba Lagi',
          onAction: context.read<ProductLookupNotifier>().retry,
        ),
      LookupStatus.success => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductInfoCard(product: state.product!),
            const SizedBox(height: 24),
            PortionForm(key: ValueKey(state.product!.barcode), product: state.product!),
          ],
        ),
    };
  }
}
