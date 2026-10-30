import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format.dart';
import '../../../domain/usecases/sync_consumptions.dart';
import '../../providers/add_consumption_notifier.dart';
import '../../providers/add_consumption_state.dart';
import '../../providers/server_sync_notifier.dart';
import '../../widgets/consumption_tile.dart';
import '../../widgets/state_message.dart';

class ServerSyncScreen extends StatelessWidget {
  const ServerSyncScreen({super.key});

  static Route<void> route(BuildContext context) {
    final notifier = ServerSyncNotifier(
      getServerConsumptions: context.read<GetServerConsumptions>(),
      uploadConsumptions: context.read<UploadConsumptions>(),
      restoreConsumptions: context.read<RestoreConsumptions>(),
    );

    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider(create: (_) => notifier..load(), child: const ServerSyncScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ServerSyncNotifier>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Sinkronisasi Server')),
      body: Column(
        children: [
          _SyncActions(isSyncing: state.isSyncing),
          const Divider(height: 1),
          Expanded(
            child: switch (state.status) {
              LoadStatus.loading => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Memuat data dari server...')],
                  ),
                ),
              LoadStatus.error => Center(
                  child: StateMessage(
                    icon: Icons.cloud_off,
                    title: 'Gagal Memuat',
                    message: state.errorMessage ?? ServerSyncNotifier.networkErrorText,
                    actionLabel: 'Coba Lagi',
                    onAction: context.read<ServerSyncNotifier>().retry,
                  ),
                ),
              LoadStatus.empty => const Center(
                  child: StateMessage(
                    icon: Icons.cloud_queue,
                    title: 'Server Masih Kosong',
                    message: 'Tekan "Kirim ke Server" untuk menyimpan catatan dari perangkat ini.',
                  ),
                ),
              LoadStatus.success => RefreshIndicator(
                  onRefresh: context.read<ServerSyncNotifier>().load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        '${state.items.length} catatan tersimpan di server',
                        key: const Key('serverItemCount'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final item in state.items) ...[
                        const SizedBox(height: 8),
                        Text(formatDateId(item.consumedAt), style: Theme.of(context).textTheme.bodySmall),
                        ConsumptionTile(consumption: item),
                      ],
                    ],
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _SyncActions extends StatelessWidget {
  const _SyncActions({required this.isSyncing});

  final bool isSyncing;

  Future<void> _run(BuildContext context, {required bool upload}) async {
    final notifier = context.read<ServerSyncNotifier>();
    final home = context.read<AddConsumptionNotifier?>();
    final messenger = ScaffoldMessenger.of(context);

    final message = upload ? await notifier.upload() : await notifier.restore();
    if (message.isEmpty) return;
    if (!upload) await home?.refresh();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isSyncing) ...[
            const LinearProgressIndicator(key: Key('syncProgress')),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('uploadButton'),
                  onPressed: isSyncing ? null : () => _run(context, upload: true),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Kirim ke Server'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('restoreButton'),
                  onPressed: isSyncing ? null : () => _run(context, upload: false),
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Ambil ke HP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
