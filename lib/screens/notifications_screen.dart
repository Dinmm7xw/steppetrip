import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../utils/theme_constants.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService.instance;
  final AuthService _auth = AuthService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    _auth.addListener(_onChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    _auth.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _service.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Хабарламалар'),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'read') _service.markAllAsRead();
                if (val == 'clear') _service.clearAll();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'read', child: Text('Барлығын оқылды деп белгілеу')),
                PopupMenuItem(value: 'clear', child: Text('Барлығын тазарту')),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
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
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: item.isRead ? Colors.white : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.type == NotificationType.guidePending
                          ? const Color(0xFFFFB74D)
                          : (item.isRead ? AppColors.border : AppColors.primaryLight.withOpacity(0.3)),
                      width: item.type == NotificationType.guidePending ? 1.5 : 1,
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
                                      color: AppColors.accentGold,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.time,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                if (item.type == NotificationType.guidePending && item.guideEmail != null)
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.check, size: 14),
                                        label: const Text('Одобрить', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () {
                                          _auth.approveGuide(item.guideEmail!);
                                          _service.markGuideAsApproved(item.guideEmail!);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Гид мәртебесі мақұлданды! ✅')),
                                          );
                                        },
                                      ),
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
              },
            ),
    );
  }
}
