import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'Турды қалай брондауға болады?',
      'answer': 'Басты беттен немесе іздеу арқылы өзіңізге ұнаған туристік орынды таңдап, «Брондау» батырмасын басыңыз. Күнді, адам санын және байланыс деректеріңізді енгізіп, растаңыз. Менеджер сізбен 15 минут ішінде хабарласады.',
    },
    {
      'question': 'Брондауды қалай қайтаруға немесе күшін жоюға болады?',
      'answer': 'Сапар басталуына дейін 48 сағат қалғанға дейін тапсырыстан бас тартсаңыз, төлем 100% толық қайтарылады. 24 сағат қалғанда 50% қайтарылады.',
    },
    {
      'question': 'Төлем қалай жүргізіледі?',
      'answer': 'Kaspi QR, кез келген банк карталары (Visa/MasterCard) немесе тур күні қолма-қол төлеуге болады.',
    },
    {
      'question': 'Тур құнына не кіреді?',
      'answer': 'Әр турдың сипаттамасында егжей-тегжейлі жазылған: жайлы трансфер, кәсіби гид қызметі, ұлттық паркке кіру билеттері және кейбір бағыттарда экологиялық тамақтану.',
    },
    {
      'question': 'Қандай киім және заттар алып бару керек?',
      'answer': 'Ыңғайлы трекинг аяқ киімі, күннен қорғайтын көзілдірік пен крем, жылы желқағар (тауда ауа-райы тез өзгереді) және жеке құжаттарыңыз.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Көмек және қолдау'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Support Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.headset_mic_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Біз әрдайым байланыстамыз!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Сұрақтарыңыз болса немесе жеке тур ұйымдастырғыңыз келсе, операторларға хабарласыңыз.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Байланыс орталығы: +7 (727) 300-55-77')),
                            );
                          },
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Қоңырау шалу', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/chat');
                          },
                          icon: const Icon(Icons.forum_rounded, size: 18),
                          label: const Text('Live Чат', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Header
            const Text(
              'Жиі қойылатын сұрақтар (FAQ)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // FAQ List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faqs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final faq = _faqs[index];
                  return ExpansionTile(
                    title: Text(
                      faq['question']!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Text(
                          faq['answer']!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
