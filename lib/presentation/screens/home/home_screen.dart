import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/sodium_format.dart';
import '../../../domain/entities/daily_nutrition.dart';
import '../../../domain/entities/food_consumption.dart';
import '../../providers/add_consumption_notifier.dart';
import '../../providers/add_consumption_state.dart';
import '../../widgets/adaptive_layout.dart';
import '../../widgets/consumption_tile.dart';
import '../../widgets/risk_status_badge.dart';
import '../../widgets/state_message.dart';
import '../add_consumption/add_consumption_screen.dart';
import '../history/history_screen.dart';
import '../product_lookup/product_lookup_screen.dart';
import '../scanner/scanner_screen.dart';
import '../server_sync/server_sync_screen.dart';
import '../settings/settings_screen.dart';

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
          IconButton(
            key: const Key('openSettingsButton'),
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(SettingsScreen.route(context)),
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
            child: _HomeContent(state: state),
          ),
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state});

  final AddConsumptionState state;

  @override
  Widget build(BuildContext context) {
    final summary = [
      _DailySummaryCard(summary: state.summary!),
      const SizedBox(height: 16),
      const _ActionButtons(),
    ];
    final today = [
      Semantics(header: true, child: Text('Konsumsi Hari Ini', style: Theme.of(context).textTheme.titleMedium)),
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
    ];

    if (isExpandedWidth(context)) {
      return TwoPaneLayout(
        key: const Key('homeTwoPane'),
        primary: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: summary,
        ),
        secondary: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: today,
        ),
      );
    }

    return ListView(
      key: const Key('homeSinglePane'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: adaptivePadding(context),
      children: [...summary, const SizedBox(height: 24), ...today],
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
    final total = '${formatSodiumMg(summary.totalSodiumMg)} / ${formatSodiumMg(summary.dailyLimitMg)}';
    final remaining = summary.isOverLimit
        ? 'Melebihi batas ${formatSodiumMg(summary.exceededMg)}'
        : 'Sisa ${formatSodiumMg(summary.remainingMg)} dari batas harian';
    final semanticsLabel = 'Ringkasan ${formatDateId(summary.date)}. '
        'Total natrium ${formatSodiumMg(summary.totalSodiumMg)} dari batas ${formatSodiumMg(summary.dailyLimitMg)}. '
        'Status ${riskStatusLabel(summary.riskStatus)}. $remaining.';

    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Semantics(
        key: const Key('dailySummarySemantics'),
        container: true,
        label: semanticsLabel,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      formatDateId(summary.date),
                      style: textTheme.bodyMedium?.copyWith(color: onPrimary.withValues(alpha: 0.8)),
                    ),
                    RiskStatusBadge(status: summary.riskStatus),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total natrium hari ini',
                style: textTheme.bodyMedium?.copyWith(color: onPrimary.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 4),
              Text(
                total,
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
                remaining,
                key: const Key('remainingText'),
                style: textTheme.bodyMedium?.copyWith(color: onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    final scan = FilledButton.icon(
      key: const Key('scanBarcodeButton'),
      onPressed: () => _openProductLookup(context),
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Pindai Barcode'),
    );
    final manual = OutlinedButton.icon(
      key: const Key('manualInputButton'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () => _openManualInput(context),
      icon: const Icon(Icons.edit_note),
      label: const Text('Input Manual'),
    );

    if (isLargeText(context)) {
      return Column(
        key: const Key('actionButtonsStacked'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [scan, const SizedBox(height: 12), manual],
      );
    }

    return Row(
      children: [
        Expanded(child: scan),
        const SizedBox(width: 12),
        Expanded(child: manual),
      ],
    );
  }
}

Future<void> _openProductLookup(BuildContext context) async {
  final notifier = context.read<AddConsumptionNotifier>();
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final scan = await scanBarcode(context);
  if (!context.mounted) return;
  if (scan == null) {
    messenger.showSnackBar(const SnackBar(content: Text('Pemindaian dibatalkan.')));
    return;
  }

  final saved = await navigator.push(ProductLookupScreen.route(context, initialBarcode: scan.barcode));
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
