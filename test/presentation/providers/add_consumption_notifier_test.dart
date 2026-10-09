import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/providers/add_consumption_state.dart';

import '../../helpers/fake_consumption_repository.dart';

void main() {
  AddConsumptionNotifier buildNotifier(FakeConsumptionRepository repository) {
    return AddConsumptionNotifier(
      getDailySummary: GetDailySummary(repository),
      recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
      clock: () => fixedNow,
    );
  }

  test('state awal adalah loading', () {
    final notifier = buildNotifier(FakeConsumptionRepository());

    expect(notifier.state.loadStatus, LoadStatus.loading);
    expect(notifier.state.isSubmitting, isFalse);
  });

  test('load menghasilkan success, empty, atau error sesuai hasil repository', () async {
    final repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    final notifier = buildNotifier(repository);

    await notifier.load();
    expect(notifier.state.loadStatus, LoadStatus.success);
    expect(notifier.state.summary!.totalSodiumMg, 750);

    repository.items.clear();
    await notifier.retry();
    expect(notifier.state.loadStatus, LoadStatus.empty);

    repository.failLoad = true;
    await notifier.retry();
    expect(notifier.state.loadStatus, LoadStatus.error);
    expect(notifier.state.loadErrorMessage, AddConsumptionNotifier.loadErrorText);
    expect(repository.loadCalls, 3);
  });

  test('submit kedua saat submit pertama berjalan diabaikan', () async {
    final repository = FakeConsumptionRepository()..saveGate = Completer<void>();
    final notifier = buildNotifier(repository);
    await notifier.load();

    final first = notifier.submit(productName: 'Indomie Mi Goreng', sodiumMg: 750);
    final second = notifier.submit(productName: 'Indomie Mi Goreng', sodiumMg: 750);

    expect(notifier.state.isSubmitting, isTrue);
    expect(await second, isFalse);

    repository.saveGate!.complete();
    expect(await first, isTrue);
    expect(repository.saveCalls, 1);
    expect(notifier.state.isSubmitting, isFalse);
    expect(notifier.state.loadStatus, LoadStatus.success);
  });

  test('submit gagal menyimpan pesan error dan mengembalikan isSubmitting ke false', () async {
    final repository = FakeConsumptionRepository()..failSave = true;
    final notifier = buildNotifier(repository);
    await notifier.load();

    final saved = await notifier.submit(productName: 'Indomie Mi Goreng', sodiumMg: 750);

    expect(saved, isFalse);
    expect(notifier.state.isSubmitting, isFalse);
    expect(notifier.state.submitErrorMessage, AddConsumptionNotifier.submitErrorText);
    expect(notifier.state.loadStatus, LoadStatus.empty);
  });
}
