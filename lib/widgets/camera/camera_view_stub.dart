import 'package:flutter/material.dart';

Widget buildPlatformCameraView({required Function(String) onCodeDetected}) {
  return const SizedBox.shrink();
}

Future<bool> initPlatformCamera() async => false;
void stopPlatformCamera() {}
void captureFromDeviceCamera(Function(String) onCodeDetected) {}

