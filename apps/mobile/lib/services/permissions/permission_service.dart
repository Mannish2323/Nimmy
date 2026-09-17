import 'package:permission_handler/permission_handler.dart';

enum NimmyPermission { microphone, notifications }

enum NimmyPermissionStatus { allowed, denied, restricted, permanentlyDenied }

class PermissionService {
  Future<NimmyPermissionStatus> status(NimmyPermission permission) async {
    final value = await _platformPermission(permission).status;
    return _map(value);
  }

  Future<NimmyPermissionStatus> request(NimmyPermission permission) async {
    final value = await _platformPermission(permission).request();
    return _map(value);
  }

  Future<bool> openAppSettings() => openAppSettings();

  Permission _platformPermission(NimmyPermission permission) {
    return switch (permission) {
      NimmyPermission.microphone => Permission.microphone,
      NimmyPermission.notifications => Permission.notification,
    };
  }

  NimmyPermissionStatus _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return NimmyPermissionStatus.allowed;
    }
    if (status.isPermanentlyDenied) {
      return NimmyPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) return NimmyPermissionStatus.restricted;
    return NimmyPermissionStatus.denied;
  }
}
