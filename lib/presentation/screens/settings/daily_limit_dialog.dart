import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/sodium_constants.dart';
import '../../../domain/validation/settings_rules.dart';

/// Dialog untuk mengubah target natrium harian. Mengembalikan nilai baru, atau
/// `null` jika dibatalkan.
Future<int?> showDailyLimitDialog(BuildContext context, {required int current}) {
  return showDialog<int>(context: context, builder: (_) => _DailyLimitDialog(current: current));
}

class _DailyLimitDialog extends StatefulWidget {
  const _DailyLimitDialog({required this.current});

  final int current;

  @override
  State<_DailyLimitDialog> createState() => _DailyLimitDialogState();
}

class _DailyLimitDialogState extends State<_DailyLimitDialog> {
  static const List<int> _presets = [1500, 2000, 2300];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(text: '${widget.current}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(parseDailyLimit(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Target Natrium Harian'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Batas umum WHO 2000 mg. Untuk hipertensi biasanya disarankan 1500 mg.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final preset in _presets)
                  ChoiceChip(
                    key: Key('dailyLimitPreset_$preset'),
                    label: Text('$preset mg'),
                    selected: _controller.text.trim() == '$preset',
                    onSelected: (_) => setState(() => _controller.text = '$preset'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('dailyLimitField'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Target (mg)',
                helperText: 'Antara $minDailyLimitMg dan $maxDailyLimitMg mg',
                suffixText: 'mg',
              ),
              validator: validateDailyLimit,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(key: const Key('saveDailyLimitButton'), onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
