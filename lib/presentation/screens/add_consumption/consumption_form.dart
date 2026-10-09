import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/add_consumption_notifier.dart';
import 'consumption_form_validators.dart';

class ConsumptionForm extends StatefulWidget {
  const ConsumptionForm({super.key});

  @override
  State<ConsumptionForm> createState() => _ConsumptionFormState();
}

class _ConsumptionFormState extends State<ConsumptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _sodiumController = TextEditingController();

  @override
  void dispose() {
    _productNameController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = context.read<AddConsumptionNotifier>();
    if (notifier.state.isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final saved = await notifier.submit(
      productName: _productNameController.text,
      sodiumMg: parseSodiumMg(_sodiumController.text)!.toDouble(),
    );
    if (!mounted || !saved) return;

    _formKey.currentState!.reset();
    _productNameController.clear();
    _sodiumController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Konsumsi berhasil disimpan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddConsumptionNotifier>().state;
    final isSubmitting = state.isSubmitting;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Catat Konsumsi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('productNameField'),
            controller: _productNameController,
            enabled: !isSubmitting,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nama Makanan'),
            validator: validateProductName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('sodiumField'),
            controller: _sodiumController,
            enabled: !isSubmitting,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jumlah Sodium',
              helperText: 'Angka bulat, contoh: 750',
              suffixText: 'mg',
            ),
            validator: validateSodiumMg,
          ),
          if (state.submitErrorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.submitErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('submitButton'),
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
