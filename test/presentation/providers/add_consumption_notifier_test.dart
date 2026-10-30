import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/repositories/settings_repository.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/domain/usecases/send_sodium_alert.dart';
import 'package:sodiscan/domain/usecases/update_consumption.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/providers/add_consumption_state.dart';

import '../../helpers/fake_consumption_repository.dart';
import '../../helpers/fake_device_services.dart';

void main() {
  AddConsumptionNotifier buildNotifier(FakeConsumptionRepository repository) {
    return AddConsumptionNotifier(
      getDailySummary: GetDailySummary(repository),
      recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
      updateConsumption: UpdateConsumption(repository),
      deleteConsumption: DeleteConsumption(repository),
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

  test('delete menghapus konsumsi lalu menghitung ulang ringkasan harian', () async {
    final repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    final notifier = buildNotifier(repository);
    await notifier.load();
    expect(notifier.state.summary!.totalSodiumMg, 750);

    expect(await notifier.delete('indomie-1'), isTrue);
    expect(notifier.state.loadStatus, LoadStatus.empty);
    expect(notifier.state.summary!.totalSodiumMg, 0);

    repository
      ..items.add(indomieConsumption())
      ..failDelete = true;
    await notifier.refresh();
    expect(await notifier.delete('indomie-1'), isFalse);
    expect(notifier.state.summary!.totalSodiumMg, 750);
  });

  test('update mengubah konsumsi lalu ringkasan dihitung ulang', () async {
    final repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    final notifier = buildNotifier(repository);
    await notifier.load();

    final updated = await notifier.update(indomieConsumption(), productName: 'Indomie Soto', sodiumMg: 1800);

    expect(updated, isTrue);
    expect(notifier.state.isSubmitting, isFalse);
    expect(notifier.state.summary!.totalSodiumMg, 1800);
    expect(notifier.state.summary!.consumptions.single.productName, 'Indomie Soto');
  });

  test('update gagal di storage menampilkan pesan error', () async {
    final repository = FakeConsumptionRepository(items: [indomieConsumption()])..failUpdate = true;
    final notifier = buildNotifier(repository);
    await notifier.load();

    final updated = await notifier.update(indomieConsumption(), productName: 'Indomie Soto', sodiumMg: 800);

    expect(updated, isFalse);
    expect(notifier.state.submitErrorMessage, AddConsumptionNotifier.updateErrorText);
    expect(notifier.state.summary!.totalSodiumMg, 750);
  });

  test('notifikasi dikirim saat catatan baru membuat status naik ke Bahaya', () async {
    final repository = FakeConsumptionRepository(items: [indomieConsumption()]);
    final notifications = FakeNotificationService();
    final notifier = AddConsumptionNotifier(
      getDailySummary: GetDailySummary(repository),
      recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
      updateConsumption: UpdateConsumption(repository),
      deleteConsumption: DeleteConsumption(repository),
      sendSodiumAlert: SendSodiumAlert(
        FakeSettingsRepository(const AppSettings(sodiumAlertsEnabled: true)),
        notifications,
      ),
      clock: () => fixedNow,
    );
    await notifier.load();
    expect(notifications.shown, isEmpty);

    await notifier.submit(productName: 'Sosis Bakar', sodiumMg: 1500);

    expect(notifier.state.summary!.totalSodiumMg, 2250);
    expect(notifications.shown.single.$1, 'Natrium hari ini melebihi batas');

    await notifier.submit(productName: 'Kerupuk', sodiumMg: 100);
    expect(notifications.shown, hasLength(1));
  });
}
