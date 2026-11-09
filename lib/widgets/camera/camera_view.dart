import 'package:flutter/material.dart';
import 'camera_view_stub.dart'
    if (dart.library.html) 'camera_view_web.dart' as platform_cam;

Widget getRealCameraView({required Function(String) onCodeDetected}) {
  return platform_cam.buildPlatformCameraView(onCodeDetected: onCodeDetected);
}

Future<bool> startRealCamera() => platform_cam.initPlatformCamera();
void stopRealCamera() => platform_cam.stopPlatformCamera();
void captureFromDeviceCamera(Function(String) onCodeDetected) => platform_cam.captureFromDeviceCamera(onCodeDetected);

