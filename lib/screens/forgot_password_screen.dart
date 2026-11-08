import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  bool _codeSent = false;

  void _handleReset() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _codeSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Қалпына келтіру коды поштаңызға / телефоныңызға жіберілді!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Құпиясөзді қалпына келтіру'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 56,
                      color: AppColors.accentGold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Құпиясөзіңізді ұмыттыңыз ба?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Тіркелген электронды поштаңызды немесе телефон нөміріңізді енгізіңіз. Біз растау кодын жібереміз.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                const Text('Электронды пошта немесе телефон', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    hintText: 'user@gmail.com немесе +7707...',
                    prefixIcon: const Icon(Icons.alternate_email, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Байланыс дерегін жазыңыз' : null,
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: _codeSent ? 'Кодты қайта жіберу' : 'Нұсқаулықты жіберу',
                  icon: Icons.send_rounded,
                  onPressed: _handleReset,
                ),
                const SizedBox(height: 16),

                if (_codeSent) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: AppColors.success),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Тексеру коды жіберілді. Поштаңызды немесе SMS хабарламаңызды тексеріңіз.',
                            style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                const Spacer(),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.primary),
                    label: const Text(
                      'Жүйеге кіруге оралу',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
