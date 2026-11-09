import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme_constants.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

/// Практикалық жұмыс №6:
/// 1. Registration формасын әзірлеу, 2. Тіркелу формасындағы міндетті өрістерге validation орнату
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'tourist'; // 'tourist' or 'guide'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 1 & 2. Тіркелуді орындау және валидация
  Future<void> _handleRegister() async {
    // 2. Барлық міндетті өрістерге validation тексеру
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Қолдану шарттарымен келісу міндетті!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _authService.register(
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // 5. Сессия сақталып, жүйеге кіру
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authService.successMessage ?? 'Тіркелу сәтті аяқталды!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      // 4. Тіркелу қатесі
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authService.errorMessage ?? 'Тіркелу сәтсіз аяқталды!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Жаңа аккаунт ашу', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SteppeTrip отбасына қосылыңыз 🌄',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Қазақстанның әдемі жерлерін зерттеп, саяхаттарыңызды бір жерден басқарыңыз',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Рөлді таңдау: Саяхатшы немесе Гид
                const Text('Қосымшадағы рөліңізді таңдаңыз *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'tourist'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'tourist' ? AppColors.primaryLight.withOpacity(0.18) : AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedRole == 'tourist' ? AppColors.primary : AppColors.border,
                              width: _selectedRole == 'tourist' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.hiking, color: AppColors.primary, size: 26),
                              SizedBox(height: 4),
                              Text('Саяхатшы 🎒', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 2),
                              Text('Тур көру, брондау', style: TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'guide'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'guide' ? AppColors.accentGold.withOpacity(0.18) : AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedRole == 'guide' ? AppColors.accentGold : AppColors.border,
                              width: _selectedRole == 'guide' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.verified, color: AppColors.accentGold, size: 26),
                              SizedBox(height: 4),
                              Text('Тур Гиді 🏅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 2),
                              Text('Билеттерді тексеру', style: TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedRole == 'guide') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.lock_clock, color: Color(0xFFF57F17), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ескерту: Гид мәртебесі админ тексеруінен кейін ғана мақұлданады.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // 2. Name validation
                const Text('Толық аты-жөніңіз *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('reg_name'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'мысалы, Азамат Серікұлы',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  validator: AuthService.validateName,
                ),
                const SizedBox(height: 16),

                // 2. Email validation
                const Text('Электронды пошта *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('reg_email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'мысалы, azamat@mail.kz',
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  validator: AuthService.validateEmail,
                ),
                const SizedBox(height: 16),

                // 2. Phone validation
                const Text('Телефон нөмірі *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('reg_phone'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+7 (707) 123-45-67',
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  validator: AuthService.validatePhone,
                ),
                const SizedBox(height: 16),

                // 2. Password validation
                const Text('Құпиясөз (кемінде 6 таңба) *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('reg_password'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Құпиясөз ойлап табыңыз',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  validator: AuthService.validatePassword,
                ),
                const SizedBox(height: 16),

                // 2. Confirm Password validation
                const Text('Құпиясөзді растау *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('reg_confirm_password'),
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Құпиясөзді қайталаңыз',
                    prefixIcon: const Icon(Icons.lock_reset, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Құпиясөзді қайта енгізіңіз';
                    }
                    if (val != _passwordController.text) {
                      return 'Құпиясөздер сәйкес келмейді!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Terms Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text(
                          'Мен SteppeTrip пайдалану шарттарымен және құпиялылық саясатымен келісемін',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Register Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        text: 'Тіркелу',
                        onPressed: _handleRegister,
                      ),

                const SizedBox(height: 16),

                // Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Аккаунтыңыз бар ма? ', style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Кіру',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
