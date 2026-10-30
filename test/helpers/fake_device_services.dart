import 'dart:async';

import 'package:sodiscan/domain/repositories/settings_repository.dart';
import 'package:sodiscan/domain/services/device_authenticator.dart';
import 'package:sodiscan/domain/services/notification_service.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.settings = const AppSettings()]);

  AppSettings settings;
  bool failSave = false;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {
    if (failSave) throw Exception('save failed');
    this.settings = settings;
  }
}

class FakeDeviceAuthenticator implements DeviceAuthenticator {
  FakeDeviceAuthenticator({this.result = DeviceAuthResult.success});

  DeviceAuthResult result;
  Completer<void>? gate;
  final List<String> reasons = [];

  @override
  Future<bool> isAvailable() async => result != DeviceAuthResult.notAvailable;

  @override
  Future<DeviceAuthResult> authenticate(String reason) async {
    reasons.add(reason);
    if (gate != null) await gate!.future;
    return result;
  }
}

class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.permissionGranted = true});

  bool permissionGranted;
  int permissionRequests = 0;
  final List<(String, String)> shown = [];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> showSodiumAlert({required String title, required String body}) async {
    shown.add((title, body));
  }
}
