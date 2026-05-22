import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// True if device has enrolled biometrics
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!canCheck || !supported) return false;
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Attempt fingerprint auth. Returns true on success.
  static Future<bool> authenticate({
    String reason = 'Verify your identity to continue',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled') return false;
      return false;
    }
  }

  /// True if NO fingerprints enrolled on device
  static Future<bool> isNotEnrolled() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final list = await _auth.getAvailableBiometrics();
      return list.isEmpty;
    } on PlatformException {
      return false;
    }
  }
}
