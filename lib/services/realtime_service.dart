import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import 'app_logger.dart';

/// 4, 7, 8, 9. Нақты уақыттағы байланыс күйлері
enum RealtimeConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Нақты уақыттағы тур жаңартуы (Live Booking / Tour Update)
class LiveTourUpdate {
  final String bookingId;
  final String tourName;
  final String status;
  final String message;
  final DateTime updatedAt;

  const LiveTourUpdate({
    required this.bookingId,
    required this.tourName,
    required this.status,
    required this.message,
    required this.updatedAt,
  });
}

/// Практикалық жұмыс №7:
/// 1-9. WebSocket және Realtime қызметі (Тур гидімен тікелей чат және Live-статустар)
class RealtimeService extends ChangeNotifier {
  static final RealtimeService instance = RealtimeService._internal();

  RealtimeService._internal();

  final AppLogger _logger = AppLogger.instance;

  RealtimeConnectionStatus _connectionStatus = RealtimeConnectionStatus.disconnected;
  String _serverUrl = 'wss://realtime.steppetrip.kz/v1/ws';
  String? _lastError;
  int _reconnectAttempts = 0;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  // Нақты уақыттағы хабарламалар тізімі
  final List<ChatMessage> _messages = [];
  LiveTourUpdate? _latestTourUpdate;

  // Streams
  final StreamController<ChatMessage> _messageStreamController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<LiveTourUpdate> _updateStreamController =
      StreamController<LiveTourUpdate>.broadcast();

  // Getters
  RealtimeConnectionStatus get connectionStatus => _connectionStatus;
  bool get isConnected => _connectionStatus == RealtimeConnectionStatus.connected;
  bool get isConnecting => _connectionStatus == RealtimeConnectionStatus.connecting;
  bool get isReconnecting => _connectionStatus == RealtimeConnectionStatus.reconnecting;
  bool get isOffline =>
      _connectionStatus == RealtimeConnectionStatus.disconnected ||
      _connectionStatus == RealtimeConnectionStatus.error;

  String get serverUrl => _serverUrl;
  String? get lastError => _lastError;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  LiveTourUpdate? get latestTourUpdate => _latestTourUpdate;

  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  Stream<LiveTourUpdate> get updateStream => _updateStreamController.stream;

  // ==========================================================================
  // 3 & 4. Клиент пен сервер арасында нақты уақыттағы байланысты орнату
  // ==========================================================================
  Future<bool> connect({String? customUrl}) async {
    if (customUrl != null) _serverUrl = customUrl;

    _connectionStatus = RealtimeConnectionStatus.connecting;
    _lastError = null;
    notifyListeners();
    _logger.realtime('RealtimeService', 'WebSocket байланысын орнату: $_serverUrl');

    // Байланыс орнату симуляциясы
    await Future.delayed(const Duration(milliseconds: 500));

    _connectionStatus = RealtimeConnectionStatus.connected;
    _reconnectAttempts = 0;
    _startHeartbeat();
    _initDefaultChatMessages();
    notifyListeners();

    _logger.info('RealtimeService', 'WebSocket байланысы сәтті орнатылды (Connected)');
    return true;
  }

  // ==========================================================================
  // 5. Деректерді нақты уақытта жіберу (Send message)
  // ==========================================================================
  Future<ChatMessage> sendMessage(String text, {String senderName = 'Саяхатшы'}) async {
    if (text.trim().isEmpty) throw ArgumentError('Хабарлама бос болмауы керек');

    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final userMessage = ChatMessage(
      id: messageId,
      senderId: 'current_user',
      senderName: senderName,
      text: text.trim(),
      timestamp: DateTime.now(),
      isFromUser: true,
      status: isConnected ? MessageStatus.sent : MessageStatus.sending,
    );

    _messages.add(userMessage);
    _messageStreamController.add(userMessage);
    notifyListeners();

    _logger.realtime('RealtimeService', 'Хабарлама жіберілді: "${userMessage.text}"');

    // 6. Серверден нақты уақытта жауап қайтару (Автоматты қабылдау)
    if (isConnected) {
      _simulateServerResponse(userMessage.text);
    }

    return userMessage;
  }

  // ==========================================================================
  // 6. Серверден келген деректерді автоматты қабылдау (Live response)
  // ==========================================================================
  void _simulateServerResponse(String userText) {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!isConnected) return;

      String replyText;
      final lower = userText.toLowerCase();

      if (lower.contains('көлсай') || lower.contains('қайыңды')) {
        replyText =
            'Көлсайға арналған тур ертең сағат 07:00-де Абай алаңынан шығады. Гидіңіз: Бауыржан мырза (+7 777 222-33-44). Жылы киім алыңыз!';
      } else if (lower.contains('шарын') || lower.contains('шатқал')) {
        replyText =
            'Шарын шатқалына тур 1 күнге созылады. Ауа райы ашық (+18°C). Экологиялық алымдар тур құнына кіреді.';
      } else if (lower.contains('билет') || lower.contains('бронь') || lower.contains('статус')) {
        replyText =
            'Сіздің соңғы BK-2026-TEST билетіңіз расталған. QR-код сканері арқылы автобусқа отыра аласыз.';
      } else if (lower.contains('сәлем') || lower.contains('салем') || lower.contains('привет')) {
        replyText =
            'Сәлеметсіз бе! SteppeTrip онлайн қолдау қызметі мен тур гиді сізді тыңдап тұр. Қандай сұрағыңыз бар?';
      } else {
        replyText =
            'Сұрағыңыз қабылданды! Гид пен оператор нақты уақытта байланыста. Барлық саяхат сұрақтарына қуана жауап береміз.';
      }

      final serverMsg = ChatMessage(
        id: 'srv_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'guide_operator',
        senderName: 'SteppeTrip Гид-көмекші',
        text: replyText,
        timestamp: DateTime.now(),
        isFromUser: false,
        status: MessageStatus.delivered,
      );

      _messages.add(serverMsg);
      _messageStreamController.add(serverMsg);
      notifyListeners();

      _logger.info('RealtimeService', 'Серверден хабарлама қабылданды: "$replyText"');
    });
  }

  /// Нақты уақыттағы брондау мәртебесін өзгерту оқиғасын тарату (Live Status)
  void emitLiveBookingStatusUpdate({
    required String bookingId,
    required String tourName,
    required String status,
    required String message,
  }) {
    _latestTourUpdate = LiveTourUpdate(
      bookingId: bookingId,
      tourName: tourName,
      status: status,
      message: message,
      updatedAt: DateTime.now(),
    );

    _updateStreamController.add(_latestTourUpdate!);
    notifyListeners();

    _logger.realtime(
      'RealtimeService',
      'Live Update: Брондау $bookingId мәртебесі: $status ($message)',
    );
  }

  // ==========================================================================
  // 7. Байланыс үзілген кездегі жағдайды өңдеу (Disconnect)
  // ==========================================================================
  void disconnect({String reason = 'Пайдаланушы байланысты үзді'}) {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _connectionStatus = RealtimeConnectionStatus.disconnected;
    notifyListeners();
    _logger.warning('RealtimeService', 'WebSocket байланысы үзілді: $reason');
  }

  /// 7 & 9. Байланыс апатты үзілген жағдайды симуляциялау (Network drop)
  void simulateNetworkDrop() {
    _heartbeatTimer?.cancel();
    _connectionStatus = RealtimeConnectionStatus.error;
    _lastError = 'Желі байланысы үзілді (Connection reset by peer)';
    notifyListeners();
    _logger.error('RealtimeService', 'Желі үзілді (Offline)', _lastError);

    // 8. Автоматты қайта қосылуды іске қосу (Auto-reconnect with backoff)
    scheduleAutoReconnect();
  }

  // ==========================================================================
  // 8. Байланысты қайта қалпына келтіру (Reconnect)
  // ==========================================================================
  void scheduleAutoReconnect() {
    _reconnectTimer?.cancel();
    _connectionStatus = RealtimeConnectionStatus.reconnecting;
    _reconnectAttempts++;
    notifyListeners();

    _logger.realtime(
      'RealtimeService',
      'Қайта қосылу әрекеті №$_reconnectAttempts...',
    );

    _reconnectTimer = Timer(const Duration(seconds: 2), () async {
      final success = await connect();
      if (success) {
        _logger.info('RealtimeService', 'Байланыс сәтті қалпына келтірілді (Reconnected)');
      }
    });
  }

  Future<void> manualReconnect() async {
    _reconnectAttempts = 0;
    await connect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (isConnected) {
        _logger.debug('RealtimeService', 'Ping-Pong heartbeat OK (ws: alive)');
      }
    });
  }

  void _initDefaultChatMessages() {
    if (_messages.isEmpty) {
      _messages.addAll([
        ChatMessage(
          id: 'welcome_01',
          senderId: 'guide_operator',
          senderName: 'SteppeTrip Қолдау',
          text:
              'Қош келдіңіз! SteppeTrip нақты уақыттағы тур гиді мен қолдау қызметіне қосылдыңыз. Кез келген сұрағыңызды жаза аласыз.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isFromUser: false,
        ),
        ChatMessage(
          id: 'welcome_02',
          senderId: 'guide_operator',
          senderName: 'Бауыржан (Гид)',
          text: 'Сәлеметсіз бе! Мен Көлсай және Шарын турлары бойынша жетекші гидпін. Қалай көмектесе аламын?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          isFromUser: false,
        ),
      ]);
    }
  }

  void clearChat() {
    _messages.clear();
    _initDefaultChatMessages();
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _messageStreamController.close();
    _updateStreamController.close();
    super.dispose();
  }
}

