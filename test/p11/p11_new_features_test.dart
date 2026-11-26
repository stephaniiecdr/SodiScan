import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:sodiscan/core/errors/failures.dart';
import 'package:sodiscan/data/datasources/local/consumption_local_data_source.dart';
import 'package:sodiscan/data/datasources/remote/consumption_remote_data_source.dart';
import 'package:sodiscan/data/repositories/consumption_repository_impl.dart';
import 'package:sodiscan/data/repositories/consumption_sync_repository_impl.dart';
import 'package:sodiscan/data/repositories/settings_repository_impl.dart';
import 'package:sodiscan/domain/entities/daily_nutrition.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/entities/frequent_food.dart';
import 'package:sodiscan/domain/entities/risk_status.dart';
import 'package:sodiscan/domain/entities/sync_report.dart';
import 'package:sodiscan/domain/repositories/settings_repository.dart';
import 'package:sodiscan/domain/services/device_authenticator.dart';
import 'package:sodiscan/domain/services/notification_service.dart';
import 'package:sodiscan/domain/usecases/delete_consumption.dart';
import 'package:sodiscan/domain/usecases/get_consumption_history.dart';
import 'package:sodiscan/domain/usecases/get_daily_summary.dart';
import 'package:sodiscan/domain/usecases/get_frequent_foods.dart';
import 'package:sodiscan/domain/usecases/record_consumption.dart';
import 'package:sodiscan/domain/usecases/sync_consumptions.dart';
import 'package:sodiscan/domain/usecases/update_consumption.dart';
import 'package:sodiscan/domain/validation/settings_rules.dart';
import 'package:sodiscan/presentation/providers/add_consumption_notifier.dart';
import 'package:sodiscan/presentation/providers/server_sync_notifier.dart';
import 'package:sodiscan/presentation/providers/settings_notifier.dart';
import 'package:sodiscan/presentation/screens/settings/settings_screen.dart';

import '../helpers/fake_consumption_repository.dart';
import '../helpers/fake_consumption_sync_repository.dart';
import '../helpers/fake_device_services.dart';
import '../helpers/pump_home_app.dart';

FoodConsumption _item(String id, String name, {double sodium = 500, DateTime? at}) {
  return FoodConsumption(
    id: id,
    productName: name,
    sodiumMg: sodium,
    source: ConsumptionSource.manual,
    consumedAt: at ?? fixedNow,
  );
}

class _FailingSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> load() async => throw const StorageFailure('rusak');

  @override
  Future<void> save(AppSettings settings) async {}
}

void main() {
  group('Fitur #16 target natrium harian bisa diatur', () {
    test('RiskStatus mengikuti target: Mendekati Batas mulai di atas 75% target', () {
      expect(RiskStatus.fromTotal(1125, limitMg: 1500), RiskStatus.safe);
      expect(RiskStatus.fromTotal(1126, limitMg: 1500), RiskStatus.nearLimit);
      expect(RiskStatus.fromTotal(1500, limitMg: 1500), RiskStatus.nearLimit);
      expect(RiskStatus.fromTotal(1501, limitMg: 1500), RiskStatus.danger);
    });

    test('tanpa target, perilaku lama (2000 mg) tidak berubah', () {
      expect(RiskStatus.fromTotal(1500), RiskStatus.safe);
      expect(RiskStatus.fromTotal(2000), RiskStatus.nearLimit);
      expect(RiskStatus.fromTotal(2001), RiskStatus.danger);
    });

    test('DailyNutrition memakai target untuk sisa, kelebihan, dan progres', () {
      final summary = DailyNutrition.fromConsumptions(fixedNow, [_item('a', 'Bakso', sodium: 1200)], dailyLimitMg: 1000);

      expect(summary.dailyLimitMg, 1000);
      expect(summary.isOverLimit, isTrue);
      expect(summary.exceededMg, 200);
      expect(summary.progress, 1.0);
      expect(summary.riskStatus, RiskStatus.danger);
    });

    test('GetDailySummary membaca target dari pengaturan', () async {
      final repository = FakeConsumptionRepository(items: [_item('a', 'Bakso', sodium: 1200)]);
      final settings = FakeSettingsRepository(const AppSettings(dailyLimitMg: 1500));

      final summary = await GetDailySummary(repository, settingsRepository: settings)(fixedNow);

      expect(summary.dailyLimitMg, 1500);
      expect(summary.riskStatus, RiskStatus.nearLimit);
    });

    test('GetConsumptionHistory memakai target yang sama untuk setiap hari', () async {
      final repository = FakeConsumptionRepository(items: [
        _item('a', 'Bakso', sodium: 1200),
        _item('b', 'Soto', sodium: 900, at: fixedNow.subtract(const Duration(days: 1))),
      ]);
      final settings = FakeSettingsRepository(const AppSettings(dailyLimitMg: 1000));

      final days = await GetConsumptionHistory(repository, settingsRepository: settings)();

      expect(days.map((day) => day.dailyLimitMg), everyElement(1000));
      expect(days.map((day) => day.riskStatus), [RiskStatus.danger, RiskStatus.nearLimit]);
    });

    test('pengaturan gagal dibaca: ringkasan tetap tampil dengan batas default 2000 mg', () async {
      final repository = FakeConsumptionRepository(items: [_item('a', 'Bakso', sodium: 1200)]);

      final summary = await GetDailySummary(repository, settingsRepository: _FailingSettingsRepository())(fixedNow);

      expect(summary.dailyLimitMg, 2000);
    });

    test('validasi target: kosong, bukan angka, dan di luar 1000–3000 ditolak', () {
      expect(validateDailyLimit('1500'), isNull);
      expect(validateDailyLimit('1000'), isNull);
      expect(validateDailyLimit('3000'), isNull);
      expect(validateDailyLimit(''), 'Target natrium wajib diisi.');
      expect(validateDailyLimit('abc'), 'Target natrium harus berupa angka.');
      expect(validateDailyLimit('999'), dailyLimitRangeMessage);
      expect(validateDailyLimit('3001'), dailyLimitRangeMessage);
    });

    test('SettingsNotifier.setDailyLimit menyimpan target dan memberi pesan', () async {
      final settings = FakeSettingsRepository();
      final notifier = SettingsNotifier(
        settingsRepository: settings,
        authenticator: FakeDeviceAuthenticator(),
        notificationService: FakeNotificationService(),
      );
      await notifier.load();

      final message = await notifier.setDailyLimit(1500);

      expect(message, 'Target natrium harian diatur ke 1500 mg.');
      expect(settings.settings.dailyLimitMg, 1500);
      expect(notifier.settings!.dailyLimitMg, 1500);
    });

    test('SettingsNotifier menolak target di luar rentang tanpa menyimpan', () async {
      final settings = FakeSettingsRepository();
      final notifier = SettingsNotifier(
        settingsRepository: settings,
        authenticator: FakeDeviceAuthenticator(),
        notificationService: FakeNotificationService(),
      );
      await notifier.load();

      expect(await notifier.setDailyLimit(500), dailyLimitRangeMessage);
      expect(settings.settings.dailyLimitMg, 2000);
    });

    test('SettingsNotifier: gagal simpan memberi pesan error dan target lama tetap', () async {
      final settings = FakeSettingsRepository()..failSave = true;
      final notifier = SettingsNotifier(
        settingsRepository: settings,
        authenticator: FakeDeviceAuthenticator(),
        notificationService: FakeNotificationService(),
      );
      await notifier.load();

      expect(await notifier.setDailyLimit(1500), SettingsNotifier.saveErrorText);
      expect(notifier.settings!.dailyLimitMg, 2000);
    });

    group('SettingsRepositoryImpl (Hive)', () {
      late Directory tempDir;

      Future<SettingsRepositoryImpl> open() async {
        Hive.init(tempDir.path);
        return SettingsRepositoryImpl(await Hive.openBox<dynamic>(SettingsRepositoryImpl.boxName));
      }

      setUp(() async => tempDir = await Directory.systemTemp.createTemp('sodiscan_limit_test'));

      tearDown(() async {
        await Hive.close();
        await tempDir.delete(recursive: true);
      });

      test('default 2000 mg dan tetap tersimpan setelah aplikasi dibuka ulang', () async {
        expect((await (await open()).load()).dailyLimitMg, 2000);

        await (await open()).save(const AppSettings(dailyLimitMg: 1500));
        await Hive.close();

        expect((await (await open()).load()).dailyLimitMg, 1500);
      });

      test('nilai tersimpan yang rusak atau di luar rentang kembali ke default', () async {
        final box = await Hive.openBox<dynamic>(SettingsRepositoryImpl.boxName, path: tempDir.path);
        await box.put('dailyLimitMg', 99999);
        await box.close();

        expect((await (await open()).load()).dailyLimitMg, 2000);
      });
    });

    group('UI Pengaturan', () {
      late FakeSettingsRepository settings;

      Future<void> pumpSettings(WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<SettingsRepository>.value(value: settings),
              Provider<DeviceAuthenticator>.value(value: FakeDeviceAuthenticator()),
              Provider<NotificationService>.value(value: FakeNotificationService()),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(SettingsScreen.route(context)),
                    child: const Text('buka'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('buka'));
        await tester.pumpAndSettle();
      }

      setUp(() => settings = FakeSettingsRepository());

      testWidgets('menampilkan target saat ini', (tester) async {
        settings.settings = const AppSettings(dailyLimitMg: 1800);
        await pumpSettings(tester);

        expect(find.textContaining('1800 mg per hari'), findsOneWidget);
      });

      testWidgets('input di luar rentang menampilkan pesan validasi dan tidak disimpan', (tester) async {
        await pumpSettings(tester);

        await tester.tap(find.byKey(const Key('dailyLimitTile')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('dailyLimitField')), '500');
        await tester.tap(find.byKey(const Key('saveDailyLimitButton')));
        await tester.pumpAndSettle();

        expect(find.text(dailyLimitRangeMessage), findsOneWidget);
        expect(settings.settings.dailyLimitMg, 2000);
      });

      testWidgets('memilih preset 1500 mg lalu Simpan mengubah target', (tester) async {
        await pumpSettings(tester);

        await tester.tap(find.byKey(const Key('dailyLimitTile')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('dailyLimitPreset_1500')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('saveDailyLimitButton')));
        await tester.pumpAndSettle();

        expect(settings.settings.dailyLimitMg, 1500);
        expect(find.text('Target natrium harian diatur ke 1500 mg.'), findsOneWidget);
        expect(find.textContaining('1500 mg per hari'), findsOneWidget);
      });

      testWidgets('Batal menutup dialog tanpa mengubah target', (tester) async {
        await pumpSettings(tester);

        await tester.tap(find.byKey(const Key('dailyLimitTile')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('dailyLimitField')), '1200');
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(settings.settings.dailyLimitMg, 2000);
        expect(find.byKey(const Key('dailyLimitField')), findsNothing);
      });
    });
  });

  group('Fitur #17 catat cepat makanan yang sering dicatat', () {
    test('mengurutkan dari yang paling sering, lalu yang terbaru', () async {
      final repository = FakeConsumptionRepository(items: [
        _item('1', 'Roti', at: fixedNow.subtract(const Duration(days: 2))),
        _item('2', 'Indomie', at: fixedNow.subtract(const Duration(days: 2))),
        _item('3', 'Indomie', at: fixedNow.subtract(const Duration(days: 1))),
        _item('4', 'Bakso', at: fixedNow),
      ]);

      final foods = await GetFrequentFoods(repository)();

      expect(foods.map((food) => food.productName), ['Indomie', 'Bakso', 'Roti']);
      expect(foods.first.count, 2);
    });

    test('nama dengan huruf besar/kecil dan spasi berbeda dianggap makanan yang sama', () async {
      final repository = FakeConsumptionRepository(items: [
        _item('1', 'Indomie Goreng', at: fixedNow.subtract(const Duration(days: 1))),
        _item('2', '  indomie   goreng ', at: fixedNow),
      ]);

      final foods = await GetFrequentFoods(repository)();

      expect(foods, hasLength(1));
      expect(foods.single.count, 2);
    });

    test('memakai natrium, barcode, dan sumber dari catatan terakhir', () async {
      final repository = FakeConsumptionRepository(items: [
        _item('1', 'Indomie Mi Goreng', sodium: 700, at: fixedNow.subtract(const Duration(days: 1))),
        indomieConsumption(),
      ]);

      final food = (await GetFrequentFoods(repository)()).single;

      expect(food.sodiumMg, 750);
      expect(food.barcode, '089686010947');
      expect(food.source, ConsumptionSource.scan);
    });

    test('dibatasi sesuai limit dan kosong jika belum ada catatan', () async {
      final repository = FakeConsumptionRepository(items: [for (var i = 0; i < 8; i++) _item('$i', 'Makanan $i')]);

      expect(await GetFrequentFoods(repository, limit: 5)(), hasLength(5));
      expect(await GetFrequentFoods(FakeConsumptionRepository())(), isEmpty);
    });

    AddConsumptionNotifier buildNotifier(FakeConsumptionRepository repository) {
      return AddConsumptionNotifier(
        getDailySummary: GetDailySummary(repository),
        recordConsumption: RecordConsumption(repository, clock: () => fixedNow),
        updateConsumption: UpdateConsumption(repository),
        deleteConsumption: DeleteConsumption(repository),
        getFrequentFoods: GetFrequentFoods(repository),
        clock: () => fixedNow,
      );
    }

    test('notifier memuat daftar catat cepat bersama ringkasan', () async {
      final notifier = buildNotifier(FakeConsumptionRepository(items: [indomieConsumption()]));

      await notifier.load();

      expect(notifier.state.frequentFoods.single.productName, 'Indomie Mi Goreng');
    });

    test('quickAdd mencatat ulang makanan dan memperbarui total hari ini', () async {
      final repository = FakeConsumptionRepository(items: [indomieConsumption()]);
      final notifier = buildNotifier(repository);
      await notifier.load();

      final saved = await notifier.quickAdd(notifier.state.frequentFoods.single);

      expect(saved, isTrue);
      expect(repository.items, hasLength(2));
      expect(repository.items.last.source, ConsumptionSource.scan);
      expect(repository.items.last.barcode, '089686010947');
      expect(notifier.state.summary!.totalSodiumMg, 1500);
      expect(notifier.state.frequentFoods.single.count, 2);
    });

    test('quickAdd gagal menyimpan menampilkan pesan error', () async {
      final repository = FakeConsumptionRepository(items: [indomieConsumption()]);
      final notifier = buildNotifier(repository);
      await notifier.load();
      repository.failSave = true;

      expect(await notifier.quickAdd(notifier.state.frequentFoods.single), isFalse);
      expect(notifier.state.submitErrorMessage, AddConsumptionNotifier.submitErrorText);
    });

    test('pesan sukses menyebut nama dan natrium', () {
      final food = FrequentFood(
        productName: 'Bakso',
        sodiumMg: 800,
        source: ConsumptionSource.manual,
        count: 3,
        lastConsumedAt: fixedNow,
      );

      expect(AddConsumptionNotifier.quickAddSuccessText(food), 'Bakso dicatat lagi (800 mg).');
    });

    testWidgets('UI: chip Catat Cepat mencatat makanan dengan sekali tekan', (tester) async {
      final repository = FakeConsumptionRepository(items: [indomieConsumption()]);
      await pumpHomeApp(tester, repository: repository, quickAdd: true);

      expect(find.byKey(const Key('quickAddSection')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('quickAdd_0')));
      await tester.tap(find.byKey(const Key('quickAdd_0')));
      await tester.pumpAndSettle();

      expect(repository.items, hasLength(2));
      expect(find.text('Indomie Mi Goreng dicatat lagi (750 mg).'), findsOneWidget);
      expect(find.text('1500 mg / 2000 mg'), findsOneWidget);
    });

    testWidgets('UI: bagian Catat Cepat tidak tampil jika belum ada riwayat', (tester) async {
      await pumpHomeApp(tester, repository: FakeConsumptionRepository(), quickAdd: true);

      expect(find.byKey(const Key('quickAddSection')), findsNothing);
    });
  });

  group('Bug #18 catatan yang dihapus muncul lagi setelah "Ambil ke HP"', () {
    test('menghapus catatan menyimpan tombstone', () async {
      final repository = FakeConsumptionRepository(items: [indomieConsumption()]);

      await DeleteConsumption(repository)('indomie-1');

      expect(await repository.getDeletedIds(), {'indomie-1'});
    });

    test('"Ambil ke HP" tidak mengembalikan catatan yang sudah dihapus', () async {
      final local = FakeConsumptionRepository(items: [indomieConsumption(), _item('roti', 'Roti')]);
      final server = FakeConsumptionSyncRepository(items: [indomieConsumption(), _item('roti', 'Roti')]);
      await local.deleteConsumption('indomie-1');

      final report = await RestoreConsumptions(server, local)();

      expect(report.skippedDeleted, 1);
      expect(local.items.map((item) => item.id), ['roti']);
    });

    test('"Kirim ke Server" ikut menghapus catatan di server lalu melupakan tombstone', () async {
      final local = FakeConsumptionRepository(items: [indomieConsumption(), _item('roti', 'Roti')]);
      final server = FakeConsumptionSyncRepository(items: [indomieConsumption(), _item('roti', 'Roti')]);
      await local.deleteConsumption('indomie-1');

      final report = await UploadConsumptions(local, server)();

      expect(report.deleted, 1);
      expect(server.items.map((item) => item.id), ['roti']);
      expect(await local.getDeletedIds(), isEmpty);
    });

    test('hapus di server gagal: tombstone tetap ada untuk dicoba lagi', () async {
      final local = FakeConsumptionRepository(items: [_item('roti', 'Roti')]);
      final server = FakeConsumptionSyncRepository(items: [indomieConsumption()])..failDeleteIds = {'indomie-1'};
      local.deletedIds.add('indomie-1');

      final report = await UploadConsumptions(local, server)();

      expect(report.failedDeletes, 1);
      expect(report.hasFailures, isTrue);
      expect(await local.getDeletedIds(), {'indomie-1'});
    });

    test('hanya ada penghapusan dan semuanya gagal: error dilempar agar penyebab terlihat', () async {
      final local = FakeConsumptionRepository()..deletedIds.add('indomie-1');
      final server = FakeConsumptionSyncRepository()..failWith = const NetworkFailure('offline');

      await expectLater(UploadConsumptions(local, server)(), throwsA(isA<NetworkFailure>()));
    });

    test('pesan upload menyebut catatan yang ikut dihapus di server', () {
      expect(
        ServerSyncNotifier.uploadMessage(const UploadReport(total: 2, deleted: 1)),
        '2 catatan dikirim ke server. 1 catatan yang dihapus juga dihapus dari server.',
      );
      expect(
        ServerSyncNotifier.uploadMessage(const UploadReport(total: 2, failedDeletes: 1)),
        contains('1 penghapusan belum terkirim'),
      );
    });

    test('pesan restore menyebut catatan terhapus yang tidak dikembalikan', () {
      expect(
        ServerSyncNotifier.restoreMessage(const RestoreReport(added: 1, skippedDeleted: 2)),
        '1 catatan dari server disimpan ke perangkat. 2 catatan yang sudah Anda hapus tidak dikembalikan.',
      );
    });

    group('Hive', () {
      late Directory tempDir;

      Future<ConsumptionRepositoryImpl> open() async {
        Hive.init(tempDir.path);
        final box = await Hive.openBox<Map>(ConsumptionLocalDataSource.boxName);
        final deletedBox = await Hive.openBox<dynamic>(ConsumptionLocalDataSource.deletedBoxName);
        return ConsumptionRepositoryImpl(ConsumptionLocalDataSource(box, deletedBox: deletedBox));
      }

      setUp(() async => tempDir = await Directory.systemTemp.createTemp('sodiscan_tombstone_test'));

      tearDown(() async {
        await Hive.close();
        await tempDir.delete(recursive: true);
      });

      test('tombstone tetap ada setelah aplikasi ditutup dan dibuka kembali', () async {
        var repository = await open();
        await repository.saveConsumption(indomieConsumption());
        await repository.deleteConsumption('indomie-1');
        await Hive.close();

        repository = await open();

        expect(await repository.getAllConsumptions(), isEmpty);
        expect(await repository.getDeletedIds(), {'indomie-1'});
      });

      test('forgetDeleted dan menyimpan ulang id yang sama menghapus tombstone', () async {
        final repository = await open();
        await repository.saveConsumption(indomieConsumption());
        await repository.deleteConsumption('indomie-1');
        await repository.saveConsumption(indomieConsumption());
        expect(await repository.getDeletedIds(), isEmpty);

        await repository.deleteConsumption('indomie-1');
        await repository.forgetDeleted('indomie-1');
        expect(await repository.getDeletedIds(), isEmpty);
      });
    });

    group('API DELETE', () {
      ConsumptionSyncRepositoryImpl repositoryResponding(int status, List<http.Request> requests) {
        return ConsumptionSyncRepositoryImpl(
          ConsumptionRemoteDataSource(
            MockClient((request) async {
              requests.add(request);
              return http.Response('', status);
            }),
            baseUrl: 'http://localhost:8080',
          ),
        );
      }

      test('204 berhasil dan memanggil endpoint yang benar', () async {
        final requests = <http.Request>[];

        await repositoryResponding(204, requests).deleteFromServer('indomie-1');

        expect(requests.single.method, 'DELETE');
        expect(requests.single.url.toString(), 'http://localhost:8080/api/consumptions/indomie-1');
      });

      test('404 dianggap berhasil karena data sudah tidak ada di server', () async {
        await repositoryResponding(404, []).deleteFromServer('indomie-1');
      });

      test('500 menjadi NetworkFailure', () async {
        await expectLater(repositoryResponding(500, []).deleteFromServer('indomie-1'), throwsA(isA<NetworkFailure>()));
      });
    });
  });
}
