import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sodiscan/data/repositories/settings_repository_impl.dart';
import 'package:sodiscan/domain/repositories/settings_repository.dart';

void main() {
  late Directory tempDir;

  Future<SettingsRepositoryImpl> open() async {
    Hive.init(tempDir.path);
    return SettingsRepositoryImpl(await Hive.openBox<dynamic>(SettingsRepositoryImpl.boxName));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sodiscan_settings_test');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('default semua fitur mati', () async {
    final settings = await (await open()).load();

    expect(settings.appLockEnabled, isFalse);
    expect(settings.sodiumAlertsEnabled, isFalse);
  });

  test('pengaturan tetap tersimpan setelah aplikasi dibuka kembali', () async {
    await (await open()).save(const AppSettings(appLockEnabled: true, sodiumAlertsEnabled: true));
    await Hive.close();

    final settings = await (await open()).load();

    expect(settings.appLockEnabled, isTrue);
    expect(settings.sodiumAlertsEnabled, isTrue);
  });
}
