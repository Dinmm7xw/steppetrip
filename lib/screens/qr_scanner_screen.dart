import 'package:flutter/material.dart';
import '../services/qr_scanner_service.dart';
import '../services/tour_repository.dart';
import '../services/mock_data_service.dart';
import '../widgets/qr_ticket_widget.dart';
import '../widgets/camera/camera_view.dart';
import '../utils/theme_constants.dart';

/// Практикалық жұмыс №6:
/// 11, 12, 13, 14, 15. Камера және QR-код сканері экраны (Интерактивті прототип)
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  final QrScannerService _scanner = QrScannerService.instance;
  late AnimationController _animController;
  late Animation<double> _laserAnimation;
  final TextEditingController _manualCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanner.addListener(_onScannerChanged);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // 13. Экран ашылғанда камера рұқсатын тексеру және шынайы камераны іске қосу
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scanner.cameraPermission == DevicePermissionStatus.notDetermined) {
        _requestPermission();
      } else if (_scanner.hasPermission) {
        startRealCamera();
      }
    });
  }

  @override
  void dispose() {
    stopRealCamera();
    _scanner.removeListener(_onScannerChanged);
    _animController.dispose();
    _manualCodeCtrl.dispose();
    super.dispose();
  }

  void _onScannerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _requestPermission() async {
    final status = await _scanner.requestCameraPermission(grant: true);
    if (status == DevicePermissionStatus.granted) {
      await startRealCamera();
    }
    if (mounted && status == DevicePermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Камераға рұқсат берілмеді. Қолмен енгізуге болады.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleSimulatedScan(String code) async {
    final result = await _scanner.verifyQrData(code);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              result.isValid ? Icons.check_circle : Icons.error,
              color: result.isValid ? AppColors.success : AppColors.error,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.isValid ? 'Билет расталды ✅' : 'Қате билет ❌',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: result.isValid ? AppColors.textPrimary : AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Код: ${result.ticketCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (result.booking != null) ...[
                    const Divider(height: 16),
                    Text('Тур: ${result.booking!.tourName}'),
                    Text('Күні: ${result.booking!.date}'),
                    Text('Адам саны: ${result.booking!.peopleCount} адам'),
                    Text('Жалпы құны: ${result.booking!.totalPrice} ₸'),
                    Text('Клиент: ${result.booking!.clientName}'),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Жабу'),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Билет кодын қолмен енгізу'),
        content: TextField(
          controller: _manualCodeCtrl,
          decoration: InputDecoration(
            hintText: 'мысалы, BK-01 немесе BK-2026-TEST',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Болдырмау'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final code = _manualCodeCtrl.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                _handleSimulatedScan(code);
              }
            },
            child: const Text('Тексеру'),
          ),
        ],
      ),
    );
  }

  void _showMyQrTicket() {
    final repo = TourRepository.instance;
    final booking = repo.bookings.isNotEmpty ? repo.bookings.first : MockDataService.mockBookings.first;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: QrTicketWidget(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPerm = _scanner.hasPermission;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Тур билетін тексеру (QR)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Менің QR Билетім',
            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.amberAccent, size: 28),
            onPressed: _showMyQrTicket,
          ),
          // 15. Permission ауыстырып тексеру түймесі (Тестілеу үшін)
          IconButton(
            tooltip: 'Permission күйін өзгерту (Тест)',
            icon: Icon(
              hasPerm ? Icons.videocam : Icons.videocam_off,
              color: hasPerm ? Colors.greenAccent : Colors.redAccent,
            ),
            onPressed: () {
              _scanner.setPermissionStatus(
                hasPerm ? DevicePermissionStatus.denied : DevicePermissionStatus.granted,
              );
            },
          ),
          IconButton(
            tooltip: 'Жарық (Flash)',
            icon: Icon(
              _scanner.isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _scanner.isTorchOn ? Colors.yellowAccent : Colors.white,
            ),
            onPressed: hasPerm ? () => _scanner.toggleTorch() : null,
          ),
        ],
      ),
      body: hasPerm ? _buildScannerBody() : _buildPermissionDeniedBody(),
    );
  }

  // 15. Permission берілген жағдай: Камера мен лазер анимациясы
  Widget _buildScannerBody() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Билеттің QR-кодын кадр ортасына бағыттаңыз',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        const Spacer(),

        // Viewfinder with Real Camera feed
        Center(
          child: Container(
            width: 270,
            height: 270,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryLight, width: 3),
              borderRadius: BorderRadius.circular(24),
              color: Colors.black,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Real camera preview (WebRTC / Device)
                getRealCameraView(onCodeDetected: _handleSimulatedScan),

                // Scanning laser overlay & corner guides
                AnimatedBuilder(
                  animation: _laserAnimation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // Corner accents
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(width: 30, height: 30, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.secondary, width: 4), left: BorderSide(color: AppColors.secondary, width: 4)))),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(width: 30, height: 30, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.secondary, width: 4), right: BorderSide(color: AppColors.secondary, width: 4)))),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(width: 30, height: 30, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.secondary, width: 4), left: BorderSide(color: AppColors.secondary, width: 4)))),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(width: 30, height: 30, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.secondary, width: 4), right: BorderSide(color: AppColors.secondary, width: 4)))),
                        ),

                        // Animated Scanning Laser Line
                        Positioned(
                          top: 270 * _laserAnimation.value,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_rounded, color: Colors.greenAccent, size: 16),
              SizedBox(width: 6),
              Text(
                'Шынайы камера (WebRTC трансляциясы)',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Демо тестілеу батырмалары
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const Text(
                'Демо-тест: QR-код симуляциясы',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // Real camera capture button (Works on iOS/Android browsers even on HTTP LAN)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3E36),
                    foregroundColor: AppColors.accentGold,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, color: AppColors.accentGold, size: 20),
                  label: const Text('📸 Камерадан QR суретін түсіру (Сканер)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () => captureFromDeviceCamera(_handleSimulatedScan),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.qr_code, size: 20),
                      label: const Text('BK-01 Билеті ✅'),
                      onPressed: () => _handleSimulatedScan('BK-01'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.confirmation_number_outlined, size: 20),
                      label: const Text('BK-2026-001 ✅'),
                      onPressed: () => _handleSimulatedScan('BK-2026-001'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.error_outline, size: 18, color: Colors.orangeAccent),
                      label: const Text('Жарамсыз QR ❌'),
                      onPressed: () => _handleSimulatedScan('INVALID_QR_999'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                      label: const Text('QR Билет көру', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _showMyQrTicket,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                icon: const Icon(Icons.keyboard, color: Colors.white70),
                label: const Text('Кодты қолмен енгізу', style: TextStyle(color: Colors.white70)),
                onPressed: _showManualInputDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 15. Permission берілмеген жағдай UI
  Widget _buildPermissionDeniedBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                size: 72,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Камераға рұқсат берілмеген',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Тур билетінің QR-кодын сканерлеу үшін SteppeTrip қосымшасына құрылғы камерасын пайдалануға рұқсат беріңіз.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Рұқсат беру (Grant)'),
              onPressed: () => _scanner.requestCameraPermission(grant: true),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Билет кодын қолмен енгізу'),
              onPressed: _showManualInputDialog,
            ),
          ],
        ),
      ),
    );
  }
}

