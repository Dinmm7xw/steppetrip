import 'dart:convert';

enum MessageStatus { sending, sent, delivered, error }

/// Практикалық жұмыс №7:
/// 1, 2, 5, 6. Нақты уақыттағы чат хабарламасының моделі (Realtime Chat Message)
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isFromUser;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isFromUser,
    this.status = MessageStatus.delivered,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    bool? isFromUser,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isFromUser: isFromUser ?? this.isFromUser,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isFromUser': isFromUser ? 1 : 0,
        'status': status.name,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] as String,
        senderId: map['senderId'] as String,
        senderName: map['senderName'] as String,
        text: map['text'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        isFromUser: (map['isFromUser'] as int? ?? 0) == 1,
        status: MessageStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => MessageStatus.delivered,
        ),
      );

  String toJson() => jsonEncode(toMap());
  factory ChatMessage.fromJson(String json) =>
      ChatMessage.fromMap(jsonDecode(json) as Map<String, dynamic>);
}

