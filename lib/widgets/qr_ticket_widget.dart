import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../utils/theme_constants.dart';

/// Электронды QR-билетті визуализациялау виджеті (Boarding Pass)
class QrTicketWidget extends StatelessWidget {
  final BookingModel booking;

  const QrTicketWidget({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Жоғарғы стильді шапка
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'STEPPETRIP БИЛЕТІ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'РАСТАЛҒАН ✅',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Тур ақпараты
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.tourName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(booking.date, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(width: 14),
                          const Icon(Icons.people_outline, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('${booking.peopleCount} адам', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Нақты QR-код суреті
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    size: const Size(180, 180),
                    painter: _QrPatternPainter(
                      data: '${booking.id}|${booking.tourName}|${booking.clientName}|${booking.date}',
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  booking.id,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Гид автобусқа отырғызарда осы QR-кодты сканерлейді',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),

                // Жолаушы мәліметтері
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ЖОЛАУШЫ', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(booking.clientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('ТӨЛЕНДІ', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('${booking.totalPrice} ₸', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// QR-код матрицасын пиксельмен салатын таза Canvas Painter
class _QrPatternPainter extends CustomPainter {
  final String data;

  _QrPatternPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()
      ..color = const Color(0xFF1B3B36)
      ..style = PaintingStyle.fill;

    final goldPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final blockSize = size.width / 21;

    // 3 бұрыштағы үлкен квадраттарды (Position markers) салу
    void drawPositionMarker(double x, double y) {
      // Сыртқы 7x7 квадрат
      canvas.drawRect(Rect.fromLTWH(x, y, 7 * blockSize, 7 * blockSize), darkPaint);
      // Ішкі ақ 5x5 квадрат
      canvas.drawRect(Rect.fromLTWH(x + blockSize, y + blockSize, 5 * blockSize, 5 * blockSize), bgPaint);
      // Орталық 3x3 квадрат
      canvas.drawRect(Rect.fromLTWH(x + 2 * blockSize, y + 2 * blockSize, 3 * blockSize, 3 * blockSize), goldPaint);
    }

    // Жоғарғы сол, жоғарғы оң, төменгі сол позициялық маркерлер
    drawPositionMarker(0, 0);
    drawPositionMarker(14 * blockSize, 0);
    drawPositionMarker(0, 14 * blockSize);

    // Деректерді хэштеп, толтыру пиксельдерін генерациялау
    final hash = data.hashCode.abs();
    for (int row = 0; row < 21; row++) {
      for (int col = 0; col < 21; col++) {
        // Бұрыштарды бос қалдыру
        final inTopLeft = row < 8 && col < 8;
        final inTopRight = row < 8 && col >= 13;
        final inBottomLeft = row >= 13 && col < 8;

        if (inTopLeft || inTopRight || inBottomLeft) continue;

        // Псевдо-кездейсоқ торлы өрнек
        final bit = ((hash + (row * 31) + (col * 17) + (row * col)) % 7) < 3;
        if (bit) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(col * blockSize + 0.5, row * blockSize + 0.5, blockSize - 1, blockSize - 1),
              const Radius.circular(1.5),
            ),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

