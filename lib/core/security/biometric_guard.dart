import 'package:splitsathi/core/di/service_locator.dart';
import 'package:splitsathi/core/security/biometric_service.dart';

class BiometricGuard {
  BiometricGuard._();

  static Future<bool> checkAccess({String? reason}) async {
    final biometricService = getIt<BiometricService>();
    final isEnabled = await biometricService.isBiometricEnabled();

    if (!isEnabled) return true;

    return biometricService.authenticate(
      reason: reason ?? 'Authenticate to continue',
    );
  }
}
