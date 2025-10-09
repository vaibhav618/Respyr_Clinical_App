import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart'; // <-- NEW

/// Fetch login ID from GetStorage
Future<String> getLoginId() async {
  final storage = GetStorage();
  return storage.read('loginClinicalName') ?? "not_available";
}

/// Collect all device and app details along with user login ID
Future<Map<String, String>> getDeviceDetails() async {
  final deviceInfo = DeviceInfoPlugin();
  final packageInfo = await PackageInfo.fromPlatform();
  final loginId = await getLoginId();

  String deviceId = '';
  String model = '';
  String brand = '';
  String osVersion = '';
  String platform = '';
  String ipAddress = '';

  if (Platform.isAndroid) {
    final info = await deviceInfo.androidInfo;
    deviceId = info.id;
    model = info.model;
    brand = info.brand;
    osVersion = info.version.release;
    platform = 'android';
  } else if (Platform.isIOS) {
    final info = await deviceInfo.iosInfo;
    deviceId = info.identifierForVendor ?? '';
    model = info.utsname.machine;
    brand = 'Apple';
    osVersion = info.systemVersion;
    platform = 'ios';
  } else {
    platform = 'other';
  }

  // Use network_info_plus for IP address
  try {
    final info = NetworkInfo();
    ipAddress = await info.getWifiIP() ?? '';
  } catch (_) {
    ipAddress = '';
  }

  return {
    'device_id': deviceId,
    'device_model': model,
    'brand': brand,
    'os_version': osVersion,
    'platform': platform,
    'ip_address': ipAddress,
    'app_version': packageInfo.version,
    'build_number': packageInfo.buildNumber,
    'app_name': packageInfo.appName,
    'package_name': packageInfo.packageName,
    'login_id': loginId,
  };
}
