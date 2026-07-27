import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:respyr_clinical/shared/urls.dart';

class UpdateService {
  static const MethodChannel _channel = MethodChannel('custom_update_channel');
  static const String versionUrl = Urls.appVersionJson;

  static Future<void> checkForUpdate(
      BuildContext context, {
        required VoidCallback onSkipOrComplete,
      }) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final int currentVersionCode = int.parse(packageInfo.buildNumber);

      final response = await Dio().get(versionUrl);
      final data = response.data;

      final int latestCode = data['version_code'];
      final String apkUrl = data['apk_url'];
      final String releaseNotes = data['release_notes'];
      final bool forceUpdate = data['force_update'];

      if (currentVersionCode >= latestCode) {
        onSkipOrComplete();
        return;
      }

      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission is required.")),
        );
        onSkipOrComplete();
        return;
      }

      // Show update dialog
      showDialog(
        context: context,
        barrierDismissible: !forceUpdate,
        builder: (_) => AlertDialog(
          title: Text('Update Available (${data['latest_version']})'),
          content: Text(releaseNotes),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onSkipOrComplete();
                },
                child: const Text('Later'),
              ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await _downloadAndInstallApk(context, apkUrl, onSkipOrComplete);
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Update check failed: $e");
      onSkipOrComplete();
    }
  }

  static Future<void> _downloadAndInstallApk(
      BuildContext context,
      String apkUrl,
      VoidCallback onSkipOrComplete,
      ) async {
    try {
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir!.path}/respyr_update.apk';

      double progress = 0;
      int lastPrintedPercent = -1;

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 2),
        responseType: ResponseType.bytes,
        headers: {
          HttpHeaders.acceptEncodingHeader: "gzip, deflate, br",
        },
      ));

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              dio.download(
                apkUrl,
                savePath,
                options: Options(
                  followRedirects: false,
                  receiveTimeout: Duration.zero,
                ),
                onReceiveProgress: (received, total) {
                  if (total != -1) {
                    final percent = ((received / total) * 100).floor();
                    if (percent > lastPrintedPercent) {
                      lastPrintedPercent = percent;
                      setState(() {
                        progress = received / total;
                      });
                      print("Downloading... $percent%");
                    }
                  }
                },
              ).then((_) async {
                await Future.delayed(const Duration(milliseconds: 500));
                Navigator.of(ctx).pop(); // close progress dialog
                await _channel.invokeMethod('installApk', {'filePath': savePath});
              }).catchError((e) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Download failed: $e")),
                );
                onSkipOrComplete();
              });

              return AlertDialog(
                title: const Text('Downloading...'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 12),
                    Text('${(progress * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      print("Download or install error: $e");
      onSkipOrComplete();
    }
  }

  static Future<bool> _requestStoragePermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }
}
