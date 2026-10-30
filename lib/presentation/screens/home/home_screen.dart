import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/sodium_format.dart';
import '../../../domain/entities/daily_nutrition.dart';
import '../../../domain/entities/food_consumption.dart';
import '../../providers/add_consumption_notifier.dart';
import '../../providers/add_consumption_state.dart';
import '../../widgets/consumption_tile.dart';
import '../../widgets/risk_status_badge.dart';
import '../../widgets/state_message.dart';
import '../add_consumption/add_consumption_screen.dart';
import '../history/history_screen.dart';
import '../product_lookup/product_lookup_screen.dart';
import '../server_sync/server_sync_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddConsumptionNotifier>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SodiScan'),
        actions: [
          IconButton(
            key: const Key('openHistoryButton'),
            tooltip: 'Riwayat Konsumsi',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(HistoryScreen.route(context)),
          ),
          IconButton(
            key: const Key('openServerSyncButton'),
            tooltip: 'Sinkronisasi Server',
            icon: const Icon(Icons.cloud_sync_outlined),
            onPressed: () => Navigator.of(context).push(ServerSyncScreen.route(context)),
          ),
        ],
      ),
      body: switch (state.loadStatus) {
        LoadStatus.loading => const _LoadingView(),
        LoadStatus.error => Center(
            child: StateMessage(
              icon: Icons.error_outline,
              title: 'Terjadi Kesalahan',
              message: state.loadErrorMessage ?? AddConsumptionNotifier.loadErrorText,
              actionLabel: 'Coba Lagi',
              onAction: context.read<AddConsumptionNotifier>().retry,
            ),
          ),
        LoadStatus.empty || LoadStatus.success => RefreshIndicator(
            onRefresh: context.read<AddConsumptionNotifier>().refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DailySummaryCard(summary: state.summary!),
                const SizedBox(height: 16),
                const _ActionButtons(),
                const SizedBox(height: 24),
                Text('Konsumsi Hari Ini', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                if (state.loadStatus == LoadStatus.empty)
                  const StateMessage(
                    icon: Icons.no_food_outlined,
                    title: 'Belum Ada Data',
                    message: 'Belum ada makanan yang tercatat hari ini.',
                  )
                else
                  for (final consumption in state.summary!.consumptions)
                    ConsumptionTile(
                      consumption: consumption,
                      onEdit: () => Navigator.of(context).push(AddConsumptionScreen.route(consumption: consumption)),
                      onDelete: () => _confirmDelete(context, consumption),
                    ),
              ],
            ),
          ),
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Memuat data...'),
        ],
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.summary});

  final DailyNutrition summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatDateId(summary.date),
                    style: textTheme.bodyMedium?.copyWith(color: onPrimary.withValues(alpha: 0.8)),
                  ),
                ),
                RiskStatusBadge(status: summary.riskStatus),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Total natrium hari ini',
              style: textTheme.bodyMedium?.copyWith(color: onPrimary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatSodiumMg(summary.totalSodiumMg)} / ${formatSodiumMg(summary.dailyLimitMg)}',
              key: const Key('dailyTotalText'),
              style: textTheme.headlineSmall?.copyWith(color: onPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: const Key('dailyProgress'),
                value: summary.progress,
                minHeight: 10,
                backgroundColor: onPrimary.withValues(alpha: 0.2),
                color: riskStatusColor(summary.riskStatus),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              summary.isOverLimit
                  ? 'Melebihi batas ${formatSodiumMg(summary.exceededMg)}'
                  : 'Sisa ${formatSodiumMg(summary.remainingMg)} dari batas harian',
              key: const Key('remainingText'),
              style: textTheme.bodyMedium?.copyWith(color: onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const Key('scanBarcodeButton'),
            onPressed: () => _openProductLookup(context),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Pindai Barcode'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('manualInputButton'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _openManualInput(context),
            icon: const Icon(Icons.edit_note),
            label: const Text('Input Manual'),
          ),
        ),
      ],
    );
  }
}

Future<void> _openProductLookup(BuildContext context) async {
  final notifier = context.read<AddConsumptionNotifier>();
  final navigator = Navigator.of(context);
  final saved = await navigator.push(ProductLookupScreen.route(context));
  if (saved == true) {
    await notifier.refresh();
  } else if (saved == false) {
    await navigator.push(AddConsumptionScreen.route());
  }
}

Future<void> _openManualInput(BuildContext context) => Navigator.of(context).push(AddConsumptionScreen.route());

Future<void> _confirmDelete(BuildContext context, FoodConsumption consumption) async {
  final notifier = context.read<AddConsumptionNotifier>();
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus Konsumsi?'),
      content: Text('${consumption.productName} (${formatSodiumMg(consumption.sodiumMg)}) akan dihapus dari catatan.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
        FilledButton(
          key: const Key('confirmDeleteButton'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final deleted = await notifier.delete(consumption.id);
  messenger.showSnackBar(
    SnackBar(content: Text(deleted ? 'Konsumsi dihapus.' : AddConsumptionNotifier.deleteErrorText)),
  );
}
