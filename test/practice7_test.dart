import 'package:flutter_test/flutter_test.dart';
import 'package:steppetrip/models/chat_message.dart';
import 'package:steppetrip/services/realtime_service.dart';
import 'package:steppetrip/services/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Практикалық жұмыс №7: Realtime & Unit Testing', () {
    late RealtimeService realtime;
    late AppLogger logger;

    setUp(() {
      realtime = RealtimeService.instance;
      logger = AppLogger.instance;
      logger.clearLogs();
    });

    tearDown(() {
      realtime.disconnect();
    });

    // 14 & 15. Тест 1: WebSocket / Realtime байланыс орнату
    test('Тест 1: RealtimeService қосылу lifecycle-ы және күйлері', () async {
      realtime.disconnect();
      expect(realtime.connectionStatus, RealtimeConnectionStatus.disconnected);
      expect(realtime.isOffline, true);

      final connected = await realtime.connect();
      expect(connected, true);
      expect(realtime.connectionStatus, RealtimeConnectionStatus.connected);
      expect(realtime.isConnected, true);
      expect(realtime.isOffline, false);
      expect(realtime.messages.isNotEmpty, true);
    });

    // 14 & 15. Тест 2: Нақты уақыттағы хабарлама алмасу
    test('Тест 2: Нақты уақыттағы екіжақты хабарлама жіберу және жауап алу', () async {
      await realtime.connect();
      final initialCount = realtime.messages.length;

      ChatMessage? streamedMsg;
      final sub = realtime.messageStream.listen((msg) => streamedMsg = msg);

      final sent = await realtime.sendMessage('Көлсай туралы айтып беріңізші');
      expect(sent.text, 'Көлсай туралы айтып беріңізші');
      expect(sent.isFromUser, true);
      expect(sent.status, MessageStatus.sent);
      expect(streamedMsg?.text, 'Көлсай туралы айтып беріңізші');

      // Кідіріспен сервер жауабын күту
      await Future.delayed(const Duration(milliseconds: 1200));
      expect(realtime.messages.length, initialCount + 2);

      final reply = realtime.messages.last;
      expect(reply.isFromUser, false);
      expect(reply.text.contains('Көлсай'), true);
      expect(reply.status, MessageStatus.delivered);

      await sub.cancel();
    });

    // 14 & 15. Тест 3: Желі үзілісі және қайта қалпына келтіру
    test('Тест 3: Желі үзілісі және автоматты қалпына келтіру (Auto-reconnect)', () async {
      await realtime.connect();
      expect(realtime.isConnected, true);

      realtime.simulateNetworkDrop();
      expect(realtime.isReconnecting, true);
      expect(realtime.lastError != null, true);

      // 2 сек реконнект таймері + 500мс байланыс
      await Future.delayed(const Duration(milliseconds: 2700));
      expect(realtime.isConnected, true);
      expect(realtime.connectionStatus, RealtimeConnectionStatus.connected);
    });

    // 14 & 15. Тест 4: Live Tour & Booking статусын тарату
    test('Тест 4: Live-статустар ағыны (LiveTourUpdate)', () async {
      LiveTourUpdate? receivedUpdate;
      final sub = realtime.updateStream.listen((u) => receivedUpdate = u);

      realtime.emitLiveBookingStatusUpdate(
        bookingId: 'BK-2026-LIVE',
        tourName: 'Шарын каньоны',
        status: 'Тур аяқталды',
        message: 'Саяхат сәтті аяқталды. Пікір қалдыруыңызды сұраймыз!',
      );

      expect(realtime.latestTourUpdate?.bookingId, 'BK-2026-LIVE');
      expect(receivedUpdate?.status, 'Тур аяқталды');
      expect(receivedUpdate?.message, 'Саяхат сәтті аяқталды. Пікір қалдыруыңызды сұраймыз!');

      await sub.cancel();
    });

    // 14 & 15. Тест 5: AppLogger лог жүйесі
    test('Тест 5: AppLogger қателер мен әрекеттерді логтау', () {
      logger.info('Test', 'Жүйелік лог');
      logger.warning('Test', 'Ескерту');
      logger.error('Test', 'Қате орын алды', 'TimeoutException');
      logger.realtime('Test', 'Realtime оқиғасы');

      expect(logger.logs.length, 4);
      expect(logger.logs.any((l) => l.level == LogLevel.info), true);
      expect(logger.logs.any((l) => l.level == LogLevel.warning), true);
      expect(logger.logs.any((l) => l.level == LogLevel.error), true);
      expect(logger.logs.any((l) => l.level == LogLevel.realtime), true);
    });

    // 14 & 15. Тест 6: ChatMessage моделі мен JSON сериализациясы
    test('Тест 6: ChatMessage сериализациясы мен моделі', () {
      final msg = ChatMessage(
        id: 'msg_001',
        senderId: 'user_1',
        senderName: 'Тест',
        text: 'Сәлем',
        timestamp: DateTime.parse('2026-11-08T12:00:00Z'),
        isFromUser: true,
      );

      final json = msg.toJson();
      final fromJson = ChatMessage.fromJson(json);

      expect(fromJson.id, msg.id);
      expect(fromJson.text, msg.text);
      expect(fromJson.senderName, msg.senderName);
      expect(fromJson.isFromUser, msg.isFromUser);
    });
  });
}

