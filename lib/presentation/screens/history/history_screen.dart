import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/sodium_format.dart';
import '../../../domain/entities/daily_nutrition.dart';
import '../../../domain/usecases/get_consumption_history.dart';
import '../../providers/add_consumption_state.dart';
import '../../providers/history_notifier.dart';
import '../../widgets/adaptive_layout.dart';
import '../../widgets/consumption_tile.dart';
import '../../widgets/risk_status_badge.dart';
import '../../widgets/state_message.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static Route<void> route(BuildContext context) {
    final getConsumptionHistory = context.read<GetConsumptionHistory>();

    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => HistoryNotifier(getConsumptionHistory: getConsumptionHistory)..load(),
        child: const HistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HistoryNotifier>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Konsumsi')),
      body: switch (state.status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => Center(
            child: StateMessage(
              icon: Icons.error_outline,
              title: 'Terjadi Kesalahan',
              message: state.errorMessage ?? HistoryNotifier.loadErrorText,
              actionLabel: 'Coba Lagi',
              onAction: context.read<HistoryNotifier>().load,
            ),
          ),
        LoadStatus.empty => const Center(
            child: StateMessage(
              icon: Icons.history,
              title: 'Belum Ada Riwayat',
              message: 'Konsumsi yang Anda catat akan muncul di sini.',
            ),
          ),
        LoadStatus.success => isExpandedWidth(context)
            ? _DayGrid(days: state.days)
            : ListView.separated(
                padding: adaptivePadding(context),
                itemCount: state.days.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _DayCard(day: state.days[index]),
              ),
      },
    );
  }
}

/// Dua kartu per baris di layar lebar. Disusun per baris (bukan per kolom) agar
/// urutan baca pembaca layar tetap dari tanggal terbaru.
class _DayGrid extends StatelessWidget {
  const _DayGrid({required this.days});

  final List<DailyNutrition> days;

  @override
  Widget build(BuildContext context) {
    final rowCount = (days.length / 2).ceil();

    return ListView.separated(
      key: const Key('historyGrid'),
      padding: const EdgeInsets.all(16),
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, row) {
        final left = days[row * 2];
        final right = row * 2 + 1 < days.length ? days[row * 2 + 1] : null;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _DayCard(day: left)),
            const SizedBox(width: 12),
            Expanded(child: right == null ? const SizedBox.shrink() : _DayCard(day: right)),
          ],
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final DailyNutrition day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      key: Key('historyDay-${day.date.toIso8601String()}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(header: true, child: Text(formatDateId(day.date), style: textTheme.titleMedium)),
                      const SizedBox(height: 4),
                      Text('Total ${formatSodiumMg(day.totalSodiumMg)} / ${formatSodiumMg(day.dailyLimitMg)}'),
                    ],
                  ),
                  RiskStatusBadge(status: day.riskStatus),
                ],
              ),
            ),
            const Divider(height: 24),
            for (final consumption in day.consumptions) ConsumptionTile(consumption: consumption),
          ],
        ),
      ),
    );
  }
}
