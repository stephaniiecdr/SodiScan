import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/food_consumption.dart';
import '../../providers/add_consumption_notifier.dart';
import '../../widgets/keyboard_safe.dart';
import 'consumption_form_validators.dart';

class ConsumptionForm extends StatefulWidget {
  const ConsumptionForm({super.key, this.initial});

  final FoodConsumption? initial;

  @override
  State<ConsumptionForm> createState() => _ConsumptionFormState();
}

class _ConsumptionFormState extends State<ConsumptionForm> {
  final _formKey = GlobalKey<FormState>();
  late final _productNameController = TextEditingController(text: widget.initial?.productName);
  late final _sodiumController = TextEditingController(text: widget.initial?.sodiumMg.round().toString());
  final _productNameFocus = FocusNode();
  final _sodiumFocus = FocusNode();

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AddConsumptionNotifier>().clearSubmitError();
    });
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _sodiumController.dispose();
    _productNameFocus.dispose();
    _sodiumFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = context.read<AddConsumptionNotifier>();
    if (notifier.state.isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      _focusFirstInvalidField();
      return;
    }

    final productName = _productNameController.text;
    final sodiumMg = parseSodiumMg(_sodiumController.text)!.toDouble();
    final saved = _isEditing
        ? await notifier.update(widget.initial!, productName: productName, sodiumMg: sodiumMg)
        : await notifier.submit(productName: productName, sodiumMg: sodiumMg);
    if (!mounted || !saved) return;

    _formKey.currentState!.reset();
    _productNameController.clear();
    _sodiumController.clear();
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Perubahan berhasil disimpan.' : 'Konsumsi berhasil disimpan.')),
    );
    await Navigator.of(context).maybePop(true);
  }

  void _focusFirstInvalidField() {
    final invalid = validateProductName(_productNameController.text) != null ? _productNameFocus : _sodiumFocus;
    invalid.requestFocus();
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
          Semantics(
            header: true,
            child: Text(_isEditing ? 'Ubah Konsumsi' : 'Catat Konsumsi', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('productNameField'),
            controller: _productNameController,
            focusNode: _productNameFocus,
            enabled: !isSubmitting,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _sodiumFocus.requestFocus(),
            onTapOutside: dismissKeyboard,
            scrollPadding: fieldScrollPadding,
            decoration: const InputDecoration(labelText: 'Nama Makanan'),
            validator: validateProductName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('sodiumField'),
            controller: _sodiumController,
            focusNode: _sodiumFocus,
            enabled: !isSubmitting,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            onTapOutside: dismissKeyboard,
            scrollPadding: fieldScrollPadding,
            decoration: const InputDecoration(
              labelText: 'Jumlah Sodium',
              helperText: 'Angka bulat, contoh: 750',
              suffixText: 'mg',
            ),
            validator: validateSodiumMg,
          ),
          if (state.submitErrorMessage != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                state.submitErrorMessage!,
                key: const Key('submitErrorText'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
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
                : Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Konsumsi'),
          ),
        ],
      ),
    );
  }
}
