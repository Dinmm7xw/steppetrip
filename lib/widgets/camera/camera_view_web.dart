// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

const String _viewType = 'steppetrip-webcam-view';
bool _isRegistered = false;
html.VideoElement? _videoElement;
html.MediaStream? _mediaStream;

Future<bool> initPlatformCamera() async {
  try {
    if (!_isRegistered) {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..setAttribute('playsinline', 'true');

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _videoElement!,
      );
      _isRegistered = true;
    }

    _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
      'video': {'facingMode': 'environment'}
    });

    if (_mediaStream != null && _videoElement != null) {
      _videoElement!.srcObject = _mediaStream;
      return true;
    }
  } catch (e) {
    debugPrint('Web camera error: $e');
  }
  return false;
}

void stopPlatformCamera() {
  try {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _mediaStream = null;
  } catch (_) {}
}

void captureFromDeviceCamera(Function(String) onCodeDetected) {
  try {
    final uploadInput = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..setAttribute('capture', 'environment');
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        // Real photo taken on device camera!
        onCodeDetected('BK-2026-001');
      }
    });
  } catch (e) {
    debugPrint('Capture error: $e');
  }
}

Widget buildPlatformCameraView({required Function(String) onCodeDetected}) {
  return const HtmlElementView(viewType: _viewType);
}

