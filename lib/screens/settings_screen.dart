import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'Қазақша';
  bool _darkMode = false;
  bool _pushNotifications = true;
  bool _emailUpdates = false;
  bool _biometrics = true;

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Кэшті тазарту'),
        content: const Text('Қосымшаның уақытша файлдары (14.2 MB) сәтті тазартылды.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Түсінікті'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Баптаулар'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section: General
          _buildSectionHeader('Негізгі баптаулар'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                    title: const Text('Қосымша тілі', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Қазақша 🇰🇿',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 54),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                    title: const Text('Қараңғы тақырып', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Түнгі режим', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    value: _darkMode,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _darkMode = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section: Notifications
          _buildSectionHeader('Хабарландырулар'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                    title: const Text('Push-хабарламалар', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Брондаулар мен акциялар туралы', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    value: _pushNotifications,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(height: 1, indent: 54),
                  SwitchListTile(
                    secondary: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
                    title: const Text('Email-дайджест', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Апта сайынғы пайдалы кеңестер', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    value: _emailUpdates,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _emailUpdates = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section: Security
          _buildSectionHeader('Қауіпсіздік және деректер'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                    title: const Text('Биометрия арқылы кіру', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Face ID / Саусақ ізі', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    value: _biometrics,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _biometrics = val),
                  ),
                  const Divider(height: 1, indent: 54),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.primary),
                    title: const Text('Кэшті тазарту', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Text('14.2 MB', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    onTap: _clearCache,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // App info
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: const Column(
              children: [
                Text('SteppeTrip v1.0.0 (Build 2026)', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Барлық құқықтар қорғалған © 2026', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
