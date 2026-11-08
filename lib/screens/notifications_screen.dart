import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Брондау расталды! 🎉',
      message: 'Көлсай көліне сапарыңыз бойынша BK-2026-001 нөмірлі брондау сәтті расталды.',
      time: '1 сағат бұрын',
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Арнайы жазғы жеңілдік! 🔥',
      message: 'Бурабай және Қатонқарағай турларына осы демалыста 15% жеңілдік ұсынылады.',
      time: 'Кеше, 18:30',
      icon: Icons.local_offer_rounded,
      iconColor: AppColors.accentGold,
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Жаңа бағыт қосылды 🏔️',
      message: 'Бозжыра шатқалына джип-тур ашылды. Бағдарламамен каталогымыздан танысыңыз.',
      time: '3 күн бұрын',
      icon: Icons.explore_rounded,
      iconColor: AppColors.primary,
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'SteppeTrip-ке қош келдіңіз!',
      message: 'Профильді толтырып, саяхаттарыңыз үшін бонустық ұпайлар жинаңыз.',
      time: '1 апта бұрын',
      icon: Icons.card_giftcard_rounded,
      iconColor: AppColors.primaryLight,
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Хабарламалар'),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'read') _markAllAsRead();
                if (val == 'clear') _clearAll();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'read', child: Text('Барлығын оқылды деп белгілеу')),
                const PopupMenuItem(value: 'clear', child: Text('Барлығын тазарту')),
              ],
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 14),
                  Text('Хабарламалар жоқ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  SizedBox(height: 4),
                  Text('Жаңа хабарламалар осында көрсетіледі', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (dir) {
                    setState(() => _notifications.removeAt(index));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.isRead ? Colors.white : AppColors.primaryLight.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.isRead ? AppColors.border : AppColors.primaryLight.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: item.iconColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: item.iconColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (!item.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.message,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.time,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
