import 'package:flutter/material.dart';
import '../services/tour_repository.dart';
import '../services/auth_service.dart';
import '../services/mock_data_service.dart';
import '../utils/theme_constants.dart';
import '../models/tour_place.dart';
import '../models/booking_model.dart';
import 'qr_scanner_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final TourRepository _repo = TourRepository.instance;
  final AuthService _auth = AuthService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _repo.addListener(_onChanged);
    _auth.addListener(_onChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _repo.removeListener(_onChanged);
    _auth.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _showAddTourDialog() {
    final titleCtrl = TextEditingController();
    final regionCtrl = TextEditingController(text: 'Алматы облысы');
    final priceCtrl = TextEditingController(text: '15000');
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_location_alt, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Жаңа тур қосу (Админ)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Тур атауы',
                  hintText: 'мысалы, Шарын каньоны',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: regionCtrl,
                decoration: InputDecoration(
                  labelText: 'Аймақ / Облыс',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Бағасы (теңге)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Сипаттамасы',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Болдырмау'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final newTour = TourPlace(
                id: 'tour_adm_${DateTime.now().millisecondsSinceEpoch}',
                name: titleCtrl.text.trim(),
                region: regionCtrl.text.trim(),
                category: 'Көлдер мен таулар',
                rating: 5.0,
                reviewsCount: 1,
                pricePerPerson: int.tryParse(priceCtrl.text.trim()) ?? 15000,
                description: descCtrl.text.trim().isNotEmpty
                    ? descCtrl.text.trim()
                    : 'Администратор қосқан жаңа тур.',
                imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
                highlights: const ['Табиғат', 'Тау', 'Әкімші таңдауы'],
                bestSeason: 'Мамыр - Қазан',
              );
              Navigator.pop(ctx);
              await _repo.createTour(newTour);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Жаңа тур деректер қорына сәтті қосылды! ✅')),
                );
              }
            },
            child: const Text('Сақтау'),
          ),
        ],
      ),
    );
  }

  void _simulateNewGuideRegistration() async {
    final success = await _auth.register(
      fullName: 'Арман Қайратұлы (Жаңа Гид)',
      email: 'guide.arman_${DateTime.now().millisecondsSinceEpoch % 1000}@steppetrip.kz',
      phone: '+7 (705) 111-22-33',
      password: '123456',
      role: 'guide',
    );
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Жаңа гид тіркелді! Ол әкімші мақұлдауын күтіп тұр ⏳'),
          backgroundColor: Color(0xFFF57F17),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _auth.pendingGuides;
    final totalTours = _repo.tours.length;
    final totalBookings = _repo.bookings.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3E36),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text(
              'Басқару тақтасы (Admin Panel)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'QR Сканер (Тексеру)',
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.accentGold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QRScannerScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              text: 'Модерация ${pending.isNotEmpty ? "(${pending.length})" : ""}',
              icon: const Icon(Icons.verified_user_outlined, size: 20),
            ),
            Tab(
              text: 'Турлар ($totalTours)',
              icon: const Icon(Icons.travel_explore, size: 20),
            ),
            Tab(
              text: 'Брондау ($totalBookings)',
              icon: const Icon(Icons.confirmation_num_outlined, size: 20),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModerationTab(pending),
          _buildToursTab(),
          _buildBookingsTab(),
        ],
      ),
    );
  }

  Widget _buildModerationTab(List pending) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3E36), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.accentGold,
                  child: Icon(Icons.security, color: Colors.black87, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Бас Әкімші: Дінмұхаммед Бақытұлы 👑',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Күтудегі гидтер өтінімі: ${pending.length} адам',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Гидтерді модерациялау',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text('Сынақ гид қосу', style: TextStyle(fontSize: 11)),
                onPressed: _simulateNewGuideRegistration,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (pending.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                    SizedBox(height: 12),
                    Text(
                      'Барлық өтінімдер қаралған! ✅',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Қазір модерацияны күтіп тұрған жаңа гидтер жоқ.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pending.length,
              itemBuilder: (ctx, idx) {
                final user = pending[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFFFF3E0),
                            child: const Icon(Icons.person, color: Color(0xFFE65100)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(user.phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('КҮТУДЕ ⏳', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Одобрить (Мақұлдау)'),
                              onPressed: () {
                                _auth.approveGuide(user.email);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${user.fullName} гид мәртебесі мақұлданды! ✅')),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Қабылдамау'),
                              onPressed: () {
                                _auth.rejectGuide(user.email);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${user.fullName} өтінімі қайтарылды.')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildToursTab() {
    final tours = _repo.tours;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Жаңа тур қосу'),
        onPressed: _showAddTourDialog,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tours.length,
        itemBuilder: (ctx, idx) {
          final t = tours[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1.5,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  t.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.landscape),
                  ),
                ),
              ),
              title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('${t.region} • ${t.pricePerPerson} ₸', style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  await _repo.deleteTour(t.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${t.name} өшірілді')),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingsTab() {
    final bookings = _repo.bookings;
    if (bookings.isEmpty) {
      return const Center(child: Text('Брондаулар табылмады.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (ctx, idx) {
        final b = bookings[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b.id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: b.status == BookingStatus.confirmed ? AppColors.success.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        b.status == BookingStatus.confirmed ? 'Расталған ✅' : b.status.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: b.status == BookingStatus.confirmed ? AppColors.success : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(b.tourName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Клиент: ${b.clientName} (${b.clientPhone})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('Күні: ${b.date} • ${b.peopleCount} адам • ${b.totalPrice} ₸', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}

