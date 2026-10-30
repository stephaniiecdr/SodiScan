import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product_lookup_notifier.dart';
import '../../providers/product_lookup_state.dart';
import '../scanner/scanner_screen.dart';
import 'product_lookup_validators.dart';

class BarcodeSearchForm extends StatefulWidget {
  const BarcodeSearchForm({super.key, this.initialBarcode});

  final String? initialBarcode;

  @override
  State<BarcodeSearchForm> createState() => _BarcodeSearchFormState();
}

class _BarcodeSearchFormState extends State<BarcodeSearchForm> {
  final _formKey = GlobalKey<FormState>();
  late final _barcodeController = TextEditingController(text: widget.initialBarcode);

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<ProductLookupNotifier>().search(_barcodeController.text);
  }

  Future<void> _scan() async {
    final result = await scanBarcode(context);
    final barcode = result?.barcode;
    if (!mounted || barcode == null) return;
    _barcodeController.text = barcode;
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProductLookupNotifier>().state;
    final isBusy = state.status == LookupStatus.loading || state.isSubmitting;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('barcodeField'),
            controller: _barcodeController,
            enabled: !isBusy,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Kode Barcode',
              helperText: 'Contoh: 089686010947',
              prefixIcon: const Icon(Icons.qr_code),
              suffixIcon: IconButton(
                key: const Key('scanCameraButton'),
                tooltip: 'Pindai dengan kamera',
                icon: const Icon(Icons.photo_camera_outlined),
                onPressed: isBusy ? null : _scan,
              ),
            ),
            validator: validateBarcode,
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            key: const Key('searchButton'),
            onPressed: isBusy ? null : _search,
            icon: const Icon(Icons.search),
            label: const Text('Cari Produk'),
          ),
        ],
      ),
    );
  }
}
