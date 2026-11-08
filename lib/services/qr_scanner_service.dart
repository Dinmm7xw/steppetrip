import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import 'database_helper.dart';

enum DevicePermissionStatus {
  notDetermined,
  granted,
  denied,
  restricted,
}

/// QR-код сканері арқылы тексерілген билет нәтижесі
class QrTicketResult {
  final bool isValid;
  final String ticketCode;
  final BookingModel? booking;
  final String message;
  final DateTime scannedAt;

  const QrTicketResult({
    required this.isValid,
    required this.ticketCode,
    this.booking,
    required this.message,
    required this.scannedAt,
  });
}

/// Практикалық жұмыс №6:
/// 11-15. Күрделі мобильді функция – Камера және QR-код сканері сервисі
class QrScannerService extends ChangeNotifier {
  static final QrScannerService instance = QrScannerService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  QrScannerService._internal();

  DevicePermissionStatus _cameraPermission = DevicePermissionStatus.notDetermined;
  bool _isTorchOn = false;
  bool _isScanning = false;
  QrTicketResult? _lastResult;

  // Getters
  DevicePermissionStatus get cameraPermission => _cameraPermission;
  bool get hasPermission => _cameraPermission == DevicePermissionStatus.granted;
  bool get isTorchOn => _isTorchOn;
  bool get isScanning => _isScanning;
  QrTicketResult? get lastResult => _lastResult;

  // 13. Құрылғыдан қажетті permission сұрауын ұйымдастыру
  Future<DevicePermissionStatus> requestCameraPermission({bool grant = true}) async {
    // Permission сұрау процесін симуляциялау
    await Future.delayed(const Duration(milliseconds: 300));
    _cameraPermission = grant ? DevicePermissionStatus.granted : DevicePermissionStatus.denied;
    notifyListeners();
    return _cameraPermission;
  }

  // 15. Permission берілмеген жағдайды қолмен қосу (тексеру үшін)
  void setPermissionStatus(DevicePermissionStatus status) {
    _cameraPermission = status;
    notifyListeners();
  }

  void toggleTorch() {
    _isTorchOn = !_isTorchOn;
    notifyListeners();
  }

  void setScanning(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  // ==========================================================================
  // 14. Таңдалған функцияны негізгі бизнес-логикамен байланыстыру (Билет тексеру)
  // ==========================================================================
  Future<QrTicketResult> verifyQrData(String rawCode) async {
    _isScanning = false;
    final now = DateTime.now();

    // 1. QR дерегін талдау (мысалы: "STP:TICKET:BK-2026-TEST" немесе қарапайым ID)
    String cleanId = rawCode.trim();
    if (cleanId.startsWith('STP:TICKET:')) {
      cleanId = cleanId.replaceFirst('STP:TICKET:', '').trim();
    } else if (cleanId.startsWith('{')) {
      try {
        final decoded = jsonDecode(cleanId) as Map<String, dynamic>;
        cleanId = (decoded['ticketId'] ?? decoded['id'] ?? '').toString();
      } catch (_) {}
    }

    // 2. Дерекқордан брондауды табу
    try {
      final allBookings = await _dbHelper.getAllBookings();
      BookingModel? booking;
      for (final b in allBookings) {
        if (b.id.toLowerCase() == cleanId.toLowerCase() || b.id.toLowerCase().contains(cleanId.toLowerCase())) {
          booking = b;
          break;
        }
      }

      if (booking == null) {
        _lastResult = QrTicketResult(
          isValid: false,
          ticketCode: rawCode,
          message: 'Билет табылмады немесе жарамсыз: "$cleanId"',
          scannedAt: now,
        );
        notifyListeners();
        return _lastResult!;
      }

      // Билет күйін тексеру
      if (booking.status == BookingStatus.cancelled) {
        _lastResult = QrTicketResult(
          isValid: false,
          ticketCode: cleanId,
          booking: booking,
          message: 'Бұл брондау БОЛДЫРМАЛҒАН (Жарамсыз билет)!',
          scannedAt: now,
        );
        notifyListeners();
        return _lastResult!;
      }

      // Билетті расталды күйіне ауыстыру (Check-in)
      await _dbHelper.updateBooking(booking.copyWith(status: BookingStatus.confirmed));

      _lastResult = QrTicketResult(
        isValid: true,
        ticketCode: cleanId,
        booking: booking.copyWith(status: BookingStatus.confirmed),
        message: 'Билет сәтті тексерілді! Тұтынушы тіркелді.',
        scannedAt: now,
      );
      notifyListeners();
      return _lastResult!;
    } catch (e) {
      _lastResult = QrTicketResult(
        isValid: false,
        ticketCode: rawCode,
        message: 'Тексеру қатесі: $e',
        scannedAt: now,
      );
      notifyListeners();
      return _lastResult!;
    }
  }

  void clearResult() {
    _lastResult = null;
    notifyListeners();
  }
}

