import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/tour_repository.dart';
import '../services/auth_service.dart';
import '../utils/theme_constants.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'login_screen.dart';
import 'admin_panel_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TourRepository _repo = TourRepository.instance;
  bool _pushNotifications = true;
  String _selectedLang = 'Қазақша';

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    AuthService.instance.addListener(_onRepoChanged);
    final current = AuthService.instance.currentUser ?? _repo.currentUser;
    if (current != null) {
      _selectedLang = current.preferredLanguage;
    }
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    AuthService.instance.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // 10. Update User Profile in SQLite
  Future<void> _showEditProfileDialog() async {
    final user = AuthService.instance.currentUser ?? _repo.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.fullName);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Профильді өзгерту (Update)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Толық аты-жөніңіз',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Электрондық пошта',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Телефон нөмірі',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болдырмау'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final editedUser = user.copyWith(
                fullName: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                preferredLanguage: _selectedLang,
              );
              await AuthService.instance.updateUser(editedUser);
              final success = await _repo.updateProfile(editedUser);
              if (context.mounted) {
                Navigator.pop(context, success);
              }
            },
            child: const Text('Сақтау', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль SQLite деректер қорында сәтті жаңартылды!')),
      );
    }
  }

  // Reset database confirmation
  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Деректер қорын бастапқы күйге келтіру', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Барлық өзгерістер өшіріліп, бастапқы демонстрациялық турлар мен брондаулар қайта жүктеледі. Жалғастырасыз ба?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Жоқ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Иә, қалпына келтіру', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _repo.resetToDefault();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SQLite деректер қоры бастапқы қалпына келтірілді')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser ??
        _repo.currentUser ??
        const UserModel(
          id: 'user_01',
          fullName: 'Әлішер Ерболұлы',
          email: 'alisher.erbol@gmail.com',
          phone: '+7 (707) 123-45-67',
          avatarUrl: '',
        );

    final completedBookings = _repo.bookings.length;
    final favoriteCount = _repo.favoriteTours.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Жеке кабинет'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Профильді өзгерту',
            onPressed: _showEditProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                        child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                      ),
                      GestureDetector(
                        onTap: _showEditProfileDialog,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isAdmin
                          ? const Color(0xFFFFF8E1)
                          : (user.isGuide ? AppColors.accentGold.withOpacity(0.15) : AppColors.primary.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: user.isAdmin
                            ? const Color(0xFFFFB300)
                            : (user.isGuide ? AppColors.accentGold : AppColors.primary.withOpacity(0.3)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.isAdmin ? Icons.admin_panel_settings : (user.isGuide ? Icons.verified : Icons.hiking),
                          size: 16,
                          color: user.isAdmin ? const Color(0xFFF57F17) : (user.isGuide ? AppColors.accentGold : AppColors.primary),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.isAdmin ? 'Бас Әкімші (Admin) 👑' : (user.isGuide ? 'Кәсіби Гид / Тексеруші 🏅' : 'Саяхатшы / Турист 🎒'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: user.isAdmin
                                ? const Color(0xFFE65100)
                                : (user.isGuide ? const Color(0xFFB78103) : AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Admin Panel navigation button
                  if (user.isAdmin) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F3E36),
                        foregroundColor: AppColors.accentGold,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.dashboard_customize_rounded, size: 18, color: AppColors.accentGold),
                      label: const Text(
                        'Әкімші тақтасы (Admin Panel) 👑',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (user.isGuide && !user.isApproved) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.hourglass_top, color: Color(0xFFE65100), size: 18),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Мәртебе: Әкімші мақұлдауын күтуде (Модерация)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFE65100)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Әкімші ретінде мақұлдау (Одобрить)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              AuthService.instance.approveGuide(user.email);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Гид мәртебесі әкімші тарапынан сәтті мақұлданды! ✅')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!user.isAdmin)
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                      icon: const Icon(Icons.swap_horiz, size: 16, color: AppColors.primary),
                      label: Text(
                        user.isGuide ? 'Саяхатшы режиміне ауысу' : 'Гид (Тексеруші) режиміне ауысу',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        AuthService.instance.toggleRole();
                        setState(() {});
                      },
                    ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // User stats directly from SQLite
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('$completedBookings', 'Брондау'),
                      Container(height: 30, width: 1, color: AppColors.border),
                      _buildStatColumn('$favoriteCount', 'Таңдаулы'),
                      Container(height: 30, width: 1, color: AppColors.border),
                      _buildStatColumn('15%', 'Жеңілдік'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings list
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                  ListTile(
                    leading: const Icon(Icons.language, color: AppColors.primary),
                    title: const Text('Қосымша тілі', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Қазақша 🇰🇿', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                    title: const Text('Push-хабарламалар', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    value: _pushNotifications,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.storage_outlined, color: AppColors.primary),
                    title: const Text('SQLite деректер қорын қалпына келтіру', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Бастапқы күйге келтіру', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.refresh, color: AppColors.primary),
                    onTap: _resetDatabase,
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.security_outlined, color: AppColors.primary),
                    title: const Text('Қауіпсіздік және баптаулар', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.forum_outlined, color: AppColors.primary),
                    title: const Text('Live Чат және Realtime Гид', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('WebSocket арқылы нақты уақыттағы байланыс', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.pushNamed(context, '/chat');
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined, color: AppColors.primary),
                    title: const Text('Көмек және қолдау қызметі', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.primary),
                    title: const Text('SteppeTrip туралы (v1.0.0, SQLite)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'SteppeTrip',
                        applicationVersion: '1.0.0 (SQLite Offline)',
                        applicationLegalese: 'Қазақстанның туристік мобильді қосымшасы. SQLite локалды деректер қоры қолданылған.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
            const SizedBox(height: 20),

            // Logout button
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Жүйеден шығу'),
                    content: const Text('Шынымен жүйеден шыққыңыз келе ме?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Болдырмау'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          // 7. Logout функциясын іске асыру
                          await AuthService.instance.logout();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        child: const Text('Шығу', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Жүйеден шығу',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
