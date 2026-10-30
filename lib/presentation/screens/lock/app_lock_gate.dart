import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_lock_notifier.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  late final AppLockNotifier _notifier = context.read<AppLockNotifier>();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _notifier.onBackground, onShow: _notifier.onForeground);
    _notifier.addListener(_showUnlockedMessage);
  }

  @override
  void dispose() {
    _notifier.removeListener(_showUnlockedMessage);
    _lifecycle.dispose();
    super.dispose();
  }

  void _showUnlockedMessage() {
    final message = _notifier.message;
    if (!_notifier.isUnlocked || message == null) return;
    _notifier.clearMessage();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockNotifier>();

    return Stack(
      children: [
        Visibility(
          visible: lock.isUnlocked,
          maintainState: true,
          child: widget.child,
        ),
        if (!lock.isUnlocked) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockNotifier>();
    final theme = Theme.of(context);
    final isBusy = lock.status == AppLockStatus.checking || lock.status == AppLockStatus.authenticating;

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('SodiScan Terkunci', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  lock.message ?? 'Gunakan sidik jari, wajah, atau PIN HP untuk membuka aplikasi.',
                  key: const Key('lockMessage'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isBusy)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Menunggu autentikasi...'),
                    ],
                  )
                else
                  FilledButton.icon(
                    key: const Key('unlockButton'),
                    onPressed: lock.unlock,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Buka Kunci'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
