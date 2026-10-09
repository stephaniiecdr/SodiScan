import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/sodium_format.dart';
import '../../../domain/entities/product.dart';
import '../../providers/product_lookup_notifier.dart';
import 'product_lookup_validators.dart';

class PortionForm extends StatefulWidget {
  const PortionForm({super.key, required this.product});

  final Product product;

  @override
  State<PortionForm> createState() => _PortionFormState();
}

class _PortionFormState extends State<PortionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = context.read<ProductLookupNotifier>();
    if (notifier.state.isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final saved = await notifier.submit(parseAmount(_amountController.text)!);
    if (!mounted || !saved) return;

    messenger.showSnackBar(const SnackBar(content: Text('Konsumsi berhasil disimpan.')));
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProductLookupNotifier>().state;
    final isSubmitting = state.isSubmitting;
    final unit = widget.product.unit;
    final amount = parseAmount(_amountController.text);
    final preview = amount == null || amount <= 0 ? null : widget.product.sodiumFor(amount);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Catat Konsumsi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('amountField'),
            controller: _amountController,
            enabled: !isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: unit == ConsumptionUnit.serving ? 'Jumlah Porsi' : 'Berat Dikonsumsi',
              suffixText: unit == ConsumptionUnit.serving ? 'porsi' : 'g',
              helperText: unit == ConsumptionUnit.serving
                  ? 'Contoh: 1 atau 0,5'
                  : 'Produk ini hanya punya data per 100 g',
            ),
            validator: (value) => validateAmount(value, unit),
          ),
          const SizedBox(height: 12),
          Text(
            preview == null ? 'Perkiraan natrium: -' : 'Perkiraan natrium: ${formatSodiumMg(preview)}',
            key: const Key('sodiumPreviewText'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (state.submitErrorMessage != null) ...[
            const SizedBox(height: 12),
            Text(state.submitErrorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('saveProductButton'),
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Menyimpan...'),
                    ],
                  )
                : const Text('Simpan Konsumsi'),
          ),
        ],
      ),
    );
  }
}
