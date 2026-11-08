import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/realtime_service.dart';
import '../utils/theme_constants.dart';

/// Практикалық жұмыс №7:
/// 1, 2, 5, 6, 7, 8, 9. Тур гидімен нақты уақыттағы чат және Live-статустар экраны
class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final RealtimeService _realtime = RealtimeService.instance;
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _realtime.addListener(_onRealtimeStateChanged);

    // 4. Экран ашылғанда байланыс орнату
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_realtime.isConnected) {
        _realtime.connect();
      }
    });
  }

  @override
  void dispose() {
    _realtime.removeListener(_onRealtimeStateChanged);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onRealtimeStateChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _realtime.sendMessage(text);
    _textCtrl.clear();
    _scrollToBottom();
  }

  void _sendQuickMessage(String text) {
    _textCtrl.text = text;
    _handleSend();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _realtime.isConnected;
    final isOffline = _realtime.isOffline;
    final isReconnecting = _realtime.isReconnecting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тур гидімен тікелей байланыс',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected
                        ? Colors.greenAccent
                        : (isReconnecting ? Colors.orangeAccent : Colors.redAccent),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected
                      ? 'Нақты уақытта онлайн (WebSocket Live)'
                      : (isReconnecting ? 'Қайта қосылуда...' : 'Желі үзілді (Офлайн)'),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 7 & 8. Байланысты қолмен үзу немесе қосу (Сынақ үшін)
          IconButton(
            tooltip: isConnected ? 'Байланысты үзу (Offline сынағы)' : 'Қайта қосылу (Reconnect)',
            icon: Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected ? Colors.white : Colors.orangeAccent,
            ),
            onPressed: () {
              if (isConnected) {
                _realtime.simulateNetworkDrop();
              } else {
                _realtime.manualReconnect();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'clear') {
                _realtime.clearChat();
              } else if (val == 'test_live') {
                _realtime.emitLiveBookingStatusUpdate(
                  bookingId: 'BK-2026-TEST',
                  tourName: 'Көлсай және Қайыңды көлдері',
                  status: 'Расталды ✅',
                  message: 'Гид сіздің отыру орныңызды бекітті!',
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'test_live',
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Live-статус сынағы'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Чатты тазарту'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 9. Offline / Error хабарламасы панелі
          if (isOffline || isReconnecting)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isReconnecting ? Colors.orange.shade800 : Colors.red.shade800,
              child: Row(
                children: [
                  Icon(
                    isReconnecting ? Icons.sync : Icons.cloud_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isReconnecting
                          ? 'Байланыс үзілді. Серверге қайта қосылу жүріп жатыр...'
                          : 'Интернет байланысы жоқ (Offline). Хабарламалар кэште сақталады.',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _realtime.manualReconnect(),
                    child: const Text('Қайта қосу', style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Live Booking Update Banner
          if (_realtime.latestTourUpdate != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.teal, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Жаңарту: ${_realtime.latestTourUpdate!.tourName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                        ),
                        Text(
                          _realtime.latestTourUpdate!.message,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Чат хабарламалары тізімі
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _realtime.messages.length,
              itemBuilder: (context, index) {
                final msg = _realtime.messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Жылдам сұрақтар чиптері (Quick suggestions)
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickChip('Көлсай қай уақытта?'),
                _buildQuickChip('Шарын ауа райы қалай?'),
                _buildQuickChip('Билет мәртебесін тексеру'),
                _buildQuickChip('Гид байланыс телефоны'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 5. Хабарлама енгізу өрісі (Realtime input)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Сұрағыңызды жазыңыз...',
                        hintStyle: const TextStyle(fontSize: 14),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _handleSend,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        backgroundColor: Colors.white,
        elevation: 1,
        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        label: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        onPressed: () => _sendQuickMessage(label),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isFromUser;
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            if (!isMe) const SizedBox(height: 2),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.status == MessageStatus.delivered ? Icons.done_all : Icons.done,
                    size: 13,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

