import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Hero Image / Icon Illustration
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryLight.withOpacity(0.2), AppColors.accentGold.withOpacity(0.15)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.travel_explore,
                            size: 90,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Title & Subtitle
                      const Text(
                        'Қазақстанның ғажайып орындары сізді күтуде!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Көлсай, Бурабай, Шарын, Түркістан және Бозжыра. Сенімді гидтермен авторлық турларды жоспарлап, бір батырмамен брондаңыз.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      // Action Buttons
                      CustomButton(
                        text: 'Жүйеге кіру / Тіркелу',
                        icon: Icons.login_rounded,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Қонақ ретінде саяхаттау',
                        isSecondary: true,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
