import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    this.buttonKey,
    required this.label,
    required this.isSubmitting,
    required this.onPressed,
    this.submittingLabel = 'Menyimpan...',
  });

  /// Dipasang langsung di [FilledButton] agar test tetap bisa membaca `onPressed`-nya.
  final Key? buttonKey;
  final String label;
  final String submittingLabel;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: buttonKey,
      onPressed: isSubmitting ? null : onPressed,
      child: isSubmitting
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [const ButtonSpinner(), const SizedBox(width: 12), Text(submittingLabel)],
            )
          : Text(label),
    );
  }
}

class FormErrorText extends StatelessWidget {
  const FormErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }
}

void showSuccessFeedback(ScaffoldMessengerState messenger, String message) {
  HapticFeedback.lightImpact();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
