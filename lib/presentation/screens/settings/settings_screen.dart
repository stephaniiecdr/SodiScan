import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/sodium_format.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/services/device_authenticator.dart';
import '../../../domain/services/notification_service.dart';
import '../../providers/settings_notifier.dart';
import '../../widgets/adaptive_layout.dart';
import '../logs/log_screen.dart';
import '../../widgets/state_message.dart';
import 'daily_limit_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Route<void> route(BuildContext context) {
    final notifier = SettingsNotifier(
      settingsRepository: context.read<SettingsRepository>(),
      authenticator: context.read<DeviceAuthenticator>(),
      notificationService: context.read<NotificationService>(),
    );

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/settings'),
      builder: (_) => ChangeNotifierProvider(create: (_) => notifier..load(), child: const SettingsScreen()),
    );
  }

  Future<void> _run(BuildContext context, Future<String?> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await action();
    if (message == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editDailyLimit(BuildContext context, int current) async {
    final notifier = context.read<SettingsNotifier>();
    final value = await showDailyLimitDialog(context, current: current);
    if (value == null || !context.mounted) return;
    await _run(context, () => notifier.setDailyLimit(value));
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SettingsNotifier>();
    final settings = notifier.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: notifier.isLoading
          ? const Center(child: CircularProgressIndicator())
          : settings == null
              ? Center(
                  child: StateMessage(
                    icon: Icons.error_outline,
                    title: 'Terjadi Kesalahan',
                    message: notifier.errorMessage ?? SettingsNotifier.loadErrorText,
                    actionLabel: 'Coba Lagi',
                    onAction: notifier.load,
                  ),
                )
              : ListView(
                  padding: adaptivePadding(context, base: 0),
                  children: [
                    if (notifier.isBusy)
                      const LinearProgressIndicator(key: Key('settingsBusy'), semanticsLabel: 'Menyimpan pengaturan'),
                    ListTile(
                      key: const Key('dailyLimitTile'),
                      leading: const Icon(Icons.flag_outlined),
                      title: const Text('Target Natrium Harian'),
                      subtitle: Text(
                        '${formatSodiumMg(settings.dailyLimitMg.toDouble())} per hari. '
                        'Status Mendekati Batas dan Bahaya mengikuti target ini.',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      enabled: !notifier.isBusy,
                      onTap: () => _editDailyLimit(context, settings.dailyLimitMg),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      key: const Key('sodiumAlertSwitch'),
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Peringatan Natrium'),
                      subtitle: const Text(
                        'Kirim notifikasi saat total natrium hari ini mencapai Mendekati Batas atau Bahaya.',
                      ),
                      value: settings.sodiumAlertsEnabled,
                      onChanged: notifier.isBusy ? null : (value) => _run(context, () => notifier.setSodiumAlerts(value)),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      key: const Key('appLockSwitch'),
                      secondary: const Icon(Icons.fingerprint),
                      title: const Text('Kunci Aplikasi'),
                      subtitle: const Text(
                        'Minta sidik jari, wajah, atau PIN HP setiap aplikasi dibuka atau kembali dari latar belakang.',
                      ),
                      value: settings.appLockEnabled,
                      onChanged: notifier.isBusy ? null : (value) => _run(context, () => notifier.setAppLock(value)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('openLogsTile'),
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: const Text('Log Aplikasi'),
                      subtitle: const Text('Lihat dan salin catatan aktivitas serta error untuk membantu melacak masalah.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(LogScreen.route(context)),
                    ),
                  ],
                ),
    );
  }
}
