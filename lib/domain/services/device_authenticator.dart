enum DeviceAuthResult { success, cancelled, notAvailable, lockedOut, failed }

abstract class DeviceAuthenticator {
  Future<bool> isAvailable();

  Future<DeviceAuthResult> authenticate(String reason);
}
