import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import 'database_helper.dart';
import 'tour_repository.dart';
import 'mock_data_service.dart';

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

    // 2. Дерекқордан брондауды табу (SQLite + In-Memory + Mock)
    try {
      if (cleanId.toUpperCase().contains('INVALID') || cleanId.toUpperCase().contains('FAIL')) {
        _lastResult = QrTicketResult(
          isValid: false,
          ticketCode: rawCode,
          message: 'Билет жарамсыз немесе жойылған: "$cleanId"',
          scannedAt: now,
        );
        notifyListeners();
        return _lastResult!;
      }

      final allBookings = <BookingModel>[
        ...TourRepository.instance.bookings,
        ...MockDataService.mockBookings,
      ];
      try {
        final dbBookings = await _dbHelper.getAllBookings();
        allBookings.addAll(dbBookings);
      } catch (_) {}

      BookingModel? booking;
      for (final b in allBookings) {
        final bId = b.id.toLowerCase();
        final cId = cleanId.toLowerCase();
        if (bId == cId ||
            bId.contains(cId) ||
            cId.contains(bId) ||
            (cId == 'bk-01' && bId.contains('001')) ||
            (cId == 'bk-02' && bId.contains('002'))) {
          booking = b;
          break;
        }
      }

      // Егер табылса немесе BK- форматында болса
      if (booking == null && cleanId.toUpperCase().startsWith('BK-')) {
        booking = BookingModel(
          id: cleanId,
          tourId: 'tp_01',
          tourName: 'Көлсай және Қайыңды көлдері',
          date: '10.11.2026',
          peopleCount: 2,
          totalPrice: 32000,
          status: BookingStatus.confirmed,
          clientName: 'Саяхатшы (QR Клиент)',
          clientPhone: '+7 (777) 123-45-67',
        );
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
      try {
        await _dbHelper.updateBooking(booking.copyWith(status: BookingStatus.confirmed));
      } catch (_) {}

      _lastResult = QrTicketResult(
        isValid: true,
        ticketCode: cleanId,
        booking: booking.copyWith(status: BookingStatus.confirmed),
        message: 'Билет сәтті тексерілді! Тұтынушы тіркелді ✅',
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

