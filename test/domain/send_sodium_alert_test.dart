import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/domain/entities/daily_nutrition.dart';
import 'package:sodiscan/domain/entities/food_consumption.dart';
import 'package:sodiscan/domain/repositories/settings_repository.dart';
import 'package:sodiscan/domain/usecases/send_sodium_alert.dart';

import '../helpers/fake_consumption_repository.dart';
import '../helpers/fake_device_services.dart';

DailyNutrition _day(double totalMg, {DateTime? date}) {
  final day = date ?? fixedNow;
  return DailyNutrition.fromConsumptions(day, [
    if (totalMg > 0)
      FoodConsumption(
        id: 'x',
        productName: 'Makanan',
        sodiumMg: totalMg,
        source: ConsumptionSource.manual,
        consumedAt: day,
      ),
  ]);
}

void main() {
  late FakeSettingsRepository settings;
  late FakeNotificationService notifications;
  late SendSodiumAlert sendSodiumAlert;

  setUp(() {
    settings = FakeSettingsRepository(const AppSettings(sodiumAlertsEnabled: true));
    notifications = FakeNotificationService();
    sendSodiumAlert = SendSodiumAlert(settings, notifications);
  });

  group('shouldAlert', () {
    test('memberi peringatan hanya saat status naik ke Mendekati Batas atau Bahaya', () {
      expect(SendSodiumAlert.shouldAlert(_day(1000), _day(1600)), isTrue);
      expect(SendSodiumAlert.shouldAlert(_day(1000), _day(2500)), isTrue);
      expect(SendSodiumAlert.shouldAlert(_day(1600), _day(2100)), isTrue);
    });

    test('tidak memberi peringatan jika status tetap, turun, atau masih Aman', () {
      expect(SendSodiumAlert.shouldAlert(_day(1600), _day(1800)), isFalse);
      expect(SendSodiumAlert.shouldAlert(_day(2500), _day(1000)), isFalse);
      expect(SendSodiumAlert.shouldAlert(_day(500), _day(1400)), isFalse);
    });

    test('tidak memberi peringatan saat pertama kali dibuka atau beda hari', () {
      expect(SendSodiumAlert.shouldAlert(null, _day(2500)), isFalse);
      final yesterday = fixedNow.subtract(const Duration(days: 1));
      expect(SendSodiumAlert.shouldAlert(_day(1000, date: yesterday), _day(2500)), isFalse);
    });
  });

  test('mengirim notifikasi Mendekati Batas dengan sisa batas', () async {
    final sent = await sendSodiumAlert(previous: _day(1000), current: _day(1650));

    expect(sent, isTrue);
    expect(notifications.shown.single.$1, 'Natrium hari ini mendekati batas');
    expect(notifications.shown.single.$2, 'Total 1650 mg dari batas 2000 mg. Sisa 350 mg.');
  });

  test('mengirim notifikasi Bahaya dengan kelebihan batas', () async {
    await sendSodiumAlert(previous: _day(1600), current: _day(2300));

    expect(notifications.shown.single.$1, 'Natrium hari ini melebihi batas');
    expect(notifications.shown.single.$2, 'Total 2300 mg, lebih 300 mg dari batas 2000 mg.');
  });

  test('tidak mengirim notifikasi jika pengguna mematikan peringatan', () async {
    settings.settings = const AppSettings();

    final sent = await sendSodiumAlert(previous: _day(1000), current: _day(2300));

    expect(sent, isFalse);
    expect(notifications.shown, isEmpty);
  });
}
