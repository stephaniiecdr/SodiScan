import 'package:local_auth/local_auth.dart';

import '../../domain/services/device_authenticator.dart';

class LocalAuthDeviceAuthenticator implements DeviceAuthenticator {
  LocalAuthDeviceAuthenticator([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<DeviceAuthResult> authenticate(String reason) async {
    try {
      final success = await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
      return success ? DeviceAuthResult.success : DeviceAuthResult.failed;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          DeviceAuthResult.cancelled,
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled =>
          DeviceAuthResult.notAvailable,
        LocalAuthExceptionCode.temporaryLockout || LocalAuthExceptionCode.biometricLockout => DeviceAuthResult.lockedOut,
        _ => DeviceAuthResult.failed,
      };
    } catch (_) {
      return DeviceAuthResult.failed;
    }
  }
}
