import 'package:flutter/material.dart';

class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.refresh,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionIcon = Icons.edit_note,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;

  /// Aksi alternatif, misalnya Input Manual di samping Coba Lagi.
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData secondaryActionIcon;

  bool get _hasAction => actionLabel != null && onAction != null;
  bool get _hasSecondaryAction => secondaryActionLabel != null && onSecondaryAction != null;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 4),
            Text(message, style: textTheme.bodyMedium, textAlign: TextAlign.center),
            if (_hasAction || _hasSecondaryAction) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (_hasAction)
                    OutlinedButton.icon(onPressed: onAction, icon: Icon(actionIcon), label: Text(actionLabel!)),
                  if (_hasSecondaryAction)
                    FilledButton.tonalIcon(
                      onPressed: onSecondaryAction,
                      icon: Icon(secondaryActionIcon),
                      label: Text(secondaryActionLabel!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
