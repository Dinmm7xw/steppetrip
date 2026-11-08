// ignore_for_file: avoid_print
import 'dart:async';
import 'package:steppetrip/models/chat_message.dart';
import 'package:steppetrip/services/realtime_service.dart';
import 'package:steppetrip/services/app_logger.dart';

void main() async {
  print(
      '======================================================================');
  print(
      'Практикалық жұмыс №7: Flutter жобасын баптау және тәуелділіктерді басқару');
  print('Тапсырмалар 14-20: Realtime Service, AppLogger & Unit Testing');
  print(
      '======================================================================\n');

  int passed = 0;
  int failed = 0;

  void assertEqual(dynamic actual, dynamic expected, String description) {
    if (actual == expected) {
      print('  [PASS] $description');
      passed++;
    } else {
      print('  [FAIL] $description: Expected "$expected" but got "$actual"');
      failed++;
    }
  }

  void assertTrue(bool condition, String description) {
    if (condition) {
      print('  [PASS] $description');
      passed++;
    } else {
      print('  [FAIL] $description: Condition was false');
      failed++;
    }
  }

  final realtime = RealtimeService.instance;
  final logger = AppLogger.instance;
  logger.clearLogs();

  // --------------------------------------------------------------------------
  // ТЕСТ 1: WebSocket / Realtime байланыс орнату (Connection Lifecycle)
  // --------------------------------------------------------------------------
  print(
      '--- ТЕСТ 1: RealtimeService қосылу lifecycle-ы мен күйлерін тексеру ---');
  realtime.disconnect();
  assertEqual(realtime.connectionStatus, RealtimeConnectionStatus.disconnected,
      'Бастапқы күй disconnected');
  assertTrue(realtime.isOffline, 'Бастапқы күйде isOffline == true');

  final connectFuture = realtime.connect();
  assertEqual(realtime.connectionStatus, RealtimeConnectionStatus.connecting,
      'connect() шақырғанда connecting күйіне ауысады');
  assertTrue(realtime.isConnecting, 'isConnecting флагы true');

  final connected = await connectFuture;
  assertTrue(connected, 'connect() Future true қайтарады');
  assertEqual(realtime.connectionStatus, RealtimeConnectionStatus.connected,
      'Байланыс орнатылған соң connected болады');
  assertTrue(realtime.isConnected, 'isConnected флагы true');
  assertTrue(!realtime.isOffline, 'Байланыс бар кезде isOffline == false');
  assertTrue(
      realtime.messages.isNotEmpty, 'Әдепкі сәлемдесу хабарламалары қосылды');

  // --------------------------------------------------------------------------
  // ТЕСТ 2: Нақты уақыттағы екіжақты хабарлама алмасу (Bidirectional Messaging)
  // --------------------------------------------------------------------------
  print(
      '\n--- ТЕСТ 2: Нақты уақыттағы хабарлама жіберу және автоматты жауап алу ---');
  final initialCount = realtime.messages.length;
  ChatMessage? receivedStreamMessage;
  final sub = realtime.messageStream.listen((msg) {
    receivedStreamMessage = msg;
  });

  const question = 'Көлсай көліне тур қашан басталады?';
  final sentMessage =
      await realtime.sendMessage(question, senderName: 'Тест Саяхатшысы');

  assertEqual(
      sentMessage.text, question, 'Жіберілген хабарламаның мәтіні дұрыс');
  assertTrue(sentMessage.isFromUser,
      'Хабарлама пайдаланушыға тиесілі (isFromUser == true)');
  assertEqual(sentMessage.status, MessageStatus.sent,
      'Жіберілген хабарлама мәртебесі sent');
  assertEqual(realtime.messages.length, initialCount + 1,
      'Хабарламалар тізімі 1-ге көбейді');
  assertEqual(receivedStreamMessage?.text, question,
      'MessageStream жаңа хабарламаны нақты уақытта таратты');

  // Күту: Серверден виртуалды гидтің жауабын күту (~1000 мс)
  await Future.delayed(const Duration(milliseconds: 1200));

  assertEqual(realtime.messages.length, initialCount + 2,
      'Серверден автоматты жауап келіп, тізімге қосылды');
  final lastReply = realtime.messages.last;
  assertTrue(!lastReply.isFromUser,
      'Жауап серверден/гидтен келді (isFromUser == false)');
  assertTrue(lastReply.text.contains('Көлсай'),
      'Гидтің жауабы Көлсай тақырыбына сәйкес мазмұнды қамтиды');
  assertEqual(lastReply.status, MessageStatus.delivered,
      'Сервер хабарламасының мәртебесі delivered');
  await sub.cancel();

  // --------------------------------------------------------------------------
  // ТЕСТ 3: Байланыс үзілген жағдай және авто-қалпына келтіру (Disconnect & Reconnect)
  // --------------------------------------------------------------------------
  print(
      '\n--- ТЕСТ 3: Желі үзілісін симуляциялау және автоматты қалпына келтіру ---');
  realtime.simulateNetworkDrop();
  assertEqual(realtime.connectionStatus, RealtimeConnectionStatus.reconnecting,
      'simulateNetworkDrop() авто-қайта қосылуды бастайды');
  assertTrue(realtime.isReconnecting, 'isReconnecting флагы true');
  assertTrue(realtime.lastError != null, 'lastError сипаттамасы толтырылды');

  // Реконнект таймері (~2000 мс + ~500 мс connect) жұмысын күту
  await Future.delayed(const Duration(milliseconds: 2700));

  assertEqual(realtime.connectionStatus, RealtimeConnectionStatus.connected,
      'Авто-қайта қосылу сәтті өтіп, күй connected болды');
  assertTrue(realtime.isConnected, 'isConnected қайта true болды');

  // --------------------------------------------------------------------------
  // ТЕСТ 4: Live Tour & Booking мәртебесін нақты уақытта тарату
  // --------------------------------------------------------------------------
  print('\n--- ТЕСТ 4: Live-статустар таратуды (LiveTourUpdate) тексеру ---');
  LiveTourUpdate? streamedUpdate;
  final updateSub = realtime.updateStream.listen((u) {
    streamedUpdate = u;
  });

  realtime.emitLiveBookingStatusUpdate(
    bookingId: 'BK-2026-7891',
    tourName: 'Көлсай және Қайыңды көлдері',
    status: 'Жолға шықты (Автобус №42)',
    message: 'Барлық саяхатшылар отырды. Келесі аялдама: Байсейіт ауылы.',
  );

  assertEqual(realtime.latestTourUpdate?.bookingId, 'BK-2026-7891',
      'latestTourUpdate брондау ID-і дұрыс сақталды');
  assertEqual(streamedUpdate?.status, 'Жолға шықты (Автобус №42)',
      'UpdateStream жаңартуды нақты уақытта таратты');
  assertEqual(
      streamedUpdate?.message,
      'Барлық саяхатшылар отырды. Келесі аялдама: Байсейіт ауылы.',
      'Жаңарту хабарламасы толық сәйкес');
  await updateSub.cancel();

  // --------------------------------------------------------------------------
  // ТЕСТ 5: Жүйелік логтарды жазу және деңгейлерін тексеру (AppLogger)
  // --------------------------------------------------------------------------
  print(
      '\n--- ТЕСТ 5: Қосымшадағы әрекеттер мен қателерді логтау жүйесі (AppLogger) ---');
  logger.info('TestTag', 'Жүйелік сынақ басталды');
  logger.warning('TestTag', 'Ескерту сынағы');
  logger.error('TestTag', 'Қате сынағы', 'Exception: Connection timed out');
  logger.realtime('TestTag', 'Realtime оқиғасы тіркелді');

  assertTrue(logger.logs.isNotEmpty, 'Логтар тізімі бос емес');
  final infoLogs = logger.logs.where((l) => l.level == LogLevel.info).toList();
  final errorLogs =
      logger.logs.where((l) => l.level == LogLevel.error).toList();
  final realtimeLogs =
      logger.logs.where((l) => l.level == LogLevel.realtime).toList();

  assertTrue(infoLogs.isNotEmpty, 'INFO деңгейіндегі лог бар');
  assertTrue(errorLogs.isNotEmpty, 'ERROR деңгейіндегі лог бар');
  assertEqual(errorLogs.last.error.toString(),
      'Exception: Connection timed out', 'Қате дерегі логқа дұрыс тіркелді');
  assertTrue(realtimeLogs.isNotEmpty, 'REALTIME деңгейіндегі лог бар');

  // --------------------------------------------------------------------------
  // ТЕСТ 6: ChatMessage моделінің JSON сериализациясы мен деректер тұтастығы
  // --------------------------------------------------------------------------
  print('\n--- ТЕСТ 6: ChatMessage сериализациясы мен моделін тексеру ---');
  final originalMsg = ChatMessage(
    id: 'msg_test_999',
    senderId: 'user_42',
    senderName: 'Әлішер',
    text: 'Шарын каньонына тур бар ма?',
    timestamp: DateTime.parse('2026-11-08T18:00:00.000Z'),
    isFromUser: true,
    status: MessageStatus.sent,
  );

  final jsonStr = originalMsg.toJson();
  final restoredMsg = ChatMessage.fromJson(jsonStr);

  assertEqual(restoredMsg.id, originalMsg.id, 'id тең');
  assertEqual(restoredMsg.senderId, originalMsg.senderId, 'senderId тең');
  assertEqual(restoredMsg.senderName, originalMsg.senderName, 'senderName тең');
  assertEqual(restoredMsg.text, originalMsg.text, 'text тең');
  assertEqual(restoredMsg.isFromUser, originalMsg.isFromUser, 'isFromUser тең');
  assertEqual(restoredMsg.status, originalMsg.status, 'status тең');

  // ==========================================================================
  // ҚОРЫТЫНДЫ
  // ==========================================================================
  print(
      '\n======================================================================');
  print('ТЕСТ ҚОРЫТЫНДЫСЫ:');
  print('Барлығы орындалған тексерулер: ${passed + failed}');
  print('СӘТТІ ӨТКЕНДЕРІ (PASS): $passed');
  print('СӘТСІЗ АЯҚТАЛҒАНДАРЫ (FAIL): $failed');
  if (failed == 0) {
    print('НӘТИЖЕ: Барлық 6 Unit-тест СӘТТІ АЯҚТАЛДЫ! (100% SUCCESS)');
  } else {
    print('НӘТИЖЕ: Кейбір тесттер сәтсіз аяқталды!');
  }
  print(
      '======================================================================');

  // Resets
  realtime.disconnect();
}
