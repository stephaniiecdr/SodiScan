import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/sodium_format.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/validation/product_rules.dart';
import '../../providers/manual_entry_draft.dart';
import '../../providers/product_lookup_notifier.dart';
import '../../widgets/form_feedback.dart';
import '../../widgets/keyboard_safe.dart';

class PortionForm extends StatefulWidget {
  const PortionForm({super.key, required this.product});

  final Product product;

  @override
  State<PortionForm> createState() => _PortionFormState();
}

class _PortionFormState extends State<PortionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = context.read<ProductLookupNotifier>();
    if (notifier.state.isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      _amountFocus.requestFocus();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final saved = await notifier.submit(parseAmount(_amountController.text)!);
    if (!mounted || !saved) return;

    showSuccessFeedback(messenger, 'Konsumsi berhasil disimpan.');
    navigator.pop(const LookupResult.saved());
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
          Semantics(header: true, child: Text('Catat Konsumsi', style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('amountField'),
            controller: _amountController,
            focusNode: _amountFocus,
            enabled: !isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            onTapOutside: dismissKeyboard,
            scrollPadding: fieldScrollPadding,
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
          Semantics(
            liveRegion: true,
            child: Text(
              preview == null ? 'Perkiraan natrium: -' : 'Perkiraan natrium: ${formatSodiumMg(preview)}',
              key: const Key('sodiumPreviewText'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (state.submitErrorMessage != null) ...[
            const SizedBox(height: 12),
            FormErrorText(state.submitErrorMessage!),
          ],
          const SizedBox(height: 16),
          SubmitButton(
            buttonKey: const Key('saveProductButton'),
            label: 'Simpan Konsumsi',
            isSubmitting: isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
