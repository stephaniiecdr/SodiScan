import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/sodium_format.dart';
import '../../../domain/entities/daily_nutrition.dart';
import '../../providers/add_consumption_notifier.dart';
import '../../providers/add_consumption_state.dart';
import '../../widgets/consumption_tile.dart';
import '../../widgets/risk_status_badge.dart';
import '../../widgets/state_message.dart';
import '../product_lookup/product_lookup_screen.dart';
import 'consumption_form.dart';

class AddConsumptionScreen extends StatelessWidget {
  const AddConsumptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddConsumptionNotifier>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Konsumsi'),
        actions: [
          IconButton(
            key: const Key('openProductLookupButton'),
            tooltip: 'Cari Produk via Barcode',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _openProductLookup(context),
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
        LoadStatus.empty || LoadStatus.success => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.loadStatus == LoadStatus.empty)
                const StateMessage(
                  icon: Icons.no_food_outlined,
                  title: 'Belum Ada Data',
                  message: 'Belum ada makanan yang tercatat hari ini.',
                )
              else
                _TodaySummary(summary: state.summary!),
              const Divider(height: 32),
              const ConsumptionForm(),
            ],
          ),
      },
    );
  }
}

Future<void> _openProductLookup(BuildContext context) async {
  final notifier = context.read<AddConsumptionNotifier>();
  final saved = await Navigator.of(context).push(ProductLookupScreen.route(context));
  if (saved == true) await notifier.refresh();
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

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.summary});

  final DailyNutrition summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total sodium hari ini',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatSodiumMg(summary.totalSodiumMg)} / ${formatSodiumMg(summary.dailyLimitMg)}',
                        key: const Key('dailyTotalText'),
                        style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                RiskStatusBadge(status: summary.riskStatus),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final consumption in summary.consumptions) ConsumptionTile(consumption: consumption),
      ],
    );
  }
}
