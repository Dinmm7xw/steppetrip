import 'package:flutter/material.dart';
import '../models/user_model.dart';

enum NotificationType {
  general,
  booking,
  guidePending,
  guideApproved,
}

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final NotificationType type;
  final String? guideEmail;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.type = NotificationType.general,
    this.guideEmail,
    this.isRead = false,
  });

  AppNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    IconData? icon,
    Color? iconColor,
    NotificationType? type,
    String? guideEmail,
    bool? isRead,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      type: type ?? this.type,
      guideEmail: guideEmail ?? this.guideEmail,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  final List<AppNotificationItem> _notifications = [
    AppNotificationItem(
      id: 'notif_welcome',
      title: 'SteppeTrip-ке қош келдіңіз! 🦅',
      message: 'Бас әкімші: Дінмұхаммед Бақытұлы. Барлық басқару құқығы берілді.',
      time: 'Жаңа ғана',
      icon: Icons.verified_user_rounded,
      iconColor: const Color(0xFF0F3E36),
      isRead: false,
    ),
  ];

  List<AppNotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addGuideApplication(UserModel guide) {
    // Check if notification for this guide already exists
    final exists = _notifications.any((n) => n.guideEmail?.toLowerCase() == guide.email.toLowerCase() && n.type == NotificationType.guidePending);
    if (exists) return;

    _notifications.insert(
      0,
      AppNotificationItem(
        id: 'guide_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Жаңа гид өтінімі! 🏅',
        message: '${guide.fullName} гид ретінде тіркелді. Телефон: ${guide.phone}. Әкімші мақұлдауын күтуде.',
        time: 'Жаңа ғана',
        icon: Icons.hourglass_top_rounded,
        iconColor: const Color(0xFFE65100),
        type: NotificationType.guidePending,
        guideEmail: guide.email,
        isRead: false,
      ),
    );
    notifyListeners();
  }

  void markGuideAsApproved(String email) {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].guideEmail?.toLowerCase() == email.toLowerCase()) {
        _notifications[i] = _notifications[i].copyWith(
          title: 'Гид мақұлданды ✅',
          message: '${_notifications[i].message} (Әкімші тарапынан мақұлданды)',
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          type: NotificationType.guideApproved,
          isRead: true,
        );
      }
    }
    notifyListeners();
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}

