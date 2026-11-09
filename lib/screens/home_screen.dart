import 'package:flutter/material.dart';
import '../models/tour_place.dart';
import '../models/booking_model.dart';
import '../services/tour_repository.dart';
import '../services/auth_service.dart';
import '../services/mock_data_service.dart';
import '../utils/theme_constants.dart';
import '../widgets/category_chip.dart';
import '../widgets/place_card.dart';
import 'place_detail_screen.dart';
import 'profile_screen.dart';
import 'catalog_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'qr_scanner_screen.dart';
import 'admin_panel_screen.dart';
import '../widgets/qr_ticket_widget.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TourRepository _repo = TourRepository.instance;
  int _currentTabIndex = 0;
  String _selectedCategory = 'Барлығы';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Барлығы',
    'Көлдер мен таулар',
    'Тарихи орындар',
    'Каньондар',
    'Ұлттық парктер',
    'Эко-турлар',
  ];

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    AuthService.instance.addListener(_onAuthChanged);
    NotificationService.instance.addListener(_onAuthChanged);
    AuthService.instance.syncUsersFromDatabase();
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    AuthService.instance.removeListener(_onAuthChanged);
    NotificationService.instance.removeListener(_onAuthChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  void _onRepoChanged() {
    if (mounted) {
      if (_repo.errorMessage != null) {
        final err = _repo.errorMessage!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(err)),
                  ],
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
        _repo.clearMessages();
      } else if (_repo.successMessage != null) {
        final msg = _repo.successMessage!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(msg)),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
        _repo.clearMessages();
      }
      setState(() {});
    }
  }

  List<TourPlace> get _filteredPlaces {
    return _repo.tours.where((place) {
      final matchesCategory = _selectedCategory == 'Барлығы' || place.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          place.region.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _toggleFavorite(String placeId) async {
    final status = await _repo.toggleFavorite(placeId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status ? 'Таңдаулыларға қосылды (SQLite)' : 'Таңдаулылардан алынды'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 8. Create Operation: Quick add tour modal
  Future<void> _showQuickAddTour() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final regionCtrl = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Жаңа тур қосу (POST /tours)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Тур атауы',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: regionCtrl,
              decoration: InputDecoration(
                labelText: 'Аймағы (облыс, қала)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Бағасы (₸)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Болдырмау')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
              final tour = TourPlace(
                id: 'tp_${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                region: regionCtrl.text.trim().isEmpty ? 'Қазақстан' : regionCtrl.text.trim(),
                category: _selectedCategory == 'Барлығы' ? 'Көлдер мен таулар' : _selectedCategory,
                rating: 5.0,
                reviewsCount: 1,
                pricePerPerson: int.tryParse(priceCtrl.text) ?? 20000,
                description: 'Жаңадан қосылған туристік орын.',
                imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
                highlights: ['Таза табиғат', 'Жайлы демалыс', 'Керемет көрініс'],
                bestSeason: 'Мамыр - Қазан',
                isFavorite: false,
              );
              final ok = await _repo.createTour(tour);
              if (context.mounted) Navigator.pop(context, ok);
            },
            child: const Text('Серверге сақтау (POST)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Жаңа тур серверге (POST) сәтті қосылды!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildCurrentTab(),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Тур қосу', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _showQuickAddTour,
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Басты бет',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Каталог',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number),
              label: 'Брондаулар',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Таңдаулы',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Профиль',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const CatalogScreen();
      case 2:
        return _buildBookingsTab();
      case 3:
        return const FavoritesScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  /// 7, 12, 13, 14, 15, 16. REST API & Офлайн кэш мәртебесі панелі
  Widget _buildApiStatusBar() {
    final isOffline = _repo.isOfflineMode;
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOffline ? const Color(0xFFFFF4E5) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOffline ? const Color(0xFFFFB74D) : const Color(0xFF81C784),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
            color: isOffline ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOffline ? 'Офлайн режим (SQLite кэш)' : 'Supabase Cloud Онлайн (PostgreSQL)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isOffline ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  isOffline
                      ? 'Интернет жоқ. Локалды деректер қорынан көрсетілуде'
                      : 'tbuezeoqfcwyshxtnxiz.supabase.co базасымен тікелей байланыс',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOffline ? const Color(0xFFBF360C) : const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
          if (_repo.isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.sync, size: 20),
              tooltip: 'Серверден жаңарту (GET)',
              color: isOffline ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
              onPressed: () => _repo.syncWithServer(),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: isOffline ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
              ),
              tooltip: 'API Сынақтары',
              onSelected: (val) async {
                final api = _repo.apiService;
                if (val == 'offline') {
                  api.forceSimulateNetworkError = true;
                  api.forceSimulateTimeout = false;
                  api.forceSimulateServerError = false;
                  await _repo.syncWithServer();
                } else if (val == 'timeout') {
                  api.forceSimulateNetworkError = false;
                  api.forceSimulateTimeout = true;
                  api.forceSimulateServerError = false;
                  await _repo.syncWithServer();
                } else if (val == 'server_err') {
                  api.forceSimulateNetworkError = false;
                  api.forceSimulateTimeout = false;
                  api.forceSimulateServerError = true;
                  await _repo.syncWithServer();
                } else if (val == 'normal') {
                  api.forceSimulateNetworkError = false;
                  api.forceSimulateTimeout = false;
                  api.forceSimulateServerError = false;
                  await _repo.syncWithServer();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'normal', child: Text('Қалыпты режим (HTTP 200 OK)')),
                const PopupMenuItem(value: 'offline', child: Text('Сынау: 15. Желі жоқ (Offline)')),
                const PopupMenuItem(value: 'timeout', child: Text('Сынау: 16. Күту уақыты (Timeout)')),
                const PopupMenuItem(value: 'server_err', child: Text('Сынау: 14. Сервер қатесі (Error 500)')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final filtered = _filteredPlaces;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await AuthService.instance.syncUsersFromDatabase();
          await _repo.syncWithServer();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar & Search Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User greeting & Avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Қайырлы күн, ${(AuthService.instance.currentUser ?? _repo.currentUser)?.fullName.split(' ').first ?? 'Саяхатшы'}! 👋',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ((AuthService.instance.currentUser ?? _repo.currentUser)?.isAdmin ?? false)
                                        ? const Color(0xFFFFF3E0)
                                        : ((AuthService.instance.currentUser ?? _repo.currentUser)?.isGuide ?? false)
                                            ? AppColors.accentGold.withOpacity(0.18)
                                            : AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ((AuthService.instance.currentUser ?? _repo.currentUser)?.isAdmin ?? false)
                                        ? 'ӘКІМШІ 👑'
                                        : ((AuthService.instance.currentUser ?? _repo.currentUser)?.isGuide ?? false)
                                            ? 'ГИД 🏅'
                                            : 'ТУРИСТ 🎒',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: ((AuthService.instance.currentUser ?? _repo.currentUser)?.isAdmin ?? false)
                                          ? const Color(0xFFE65100)
                                          : ((AuthService.instance.currentUser ?? _repo.currentUser)?.isGuide ?? false)
                                              ? const Color(0xFFB78103)
                                              : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Қазақстанды ашыңыз',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((AuthService.instance.currentUser ?? _repo.currentUser)?.isAdmin ?? false) ...[
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              tooltip: 'Басқару тақтасы (Admin Panel)',
                              icon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFE65100), size: 24),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                                );
                              },
                            ),
                            const SizedBox(width: 2),
                          ],
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(),
                            tooltip: 'Live Чат (Realtime гид)',
                            icon: const Icon(Icons.forum_outlined, color: AppColors.primary, size: 22),
                            onPressed: () {
                              Navigator.pushNamed(context, '/chat');
                            },
                          ),
                          const SizedBox(width: 2),
                          if (((AuthService.instance.currentUser ?? _repo.currentUser)?.isGuide ?? false) ||
                              ((AuthService.instance.currentUser ?? _repo.currentUser)?.isAdmin ?? false))
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(),
                              tooltip: 'Билеттерді тексеру (Гид/Админ Сканері)',
                              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 22),
                              onPressed: () {
                                final active = (AuthService.instance.currentUser ?? _repo.currentUser);
                                if (active?.isGuide == true && active?.isApproved == false) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('⏳ Гид аккаунты әкімші тексеруінде (Админ мақұлдауын күтуде)'),
                                      backgroundColor: Color(0xFFF57F17),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                                );
                              },
                            )
                          else
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(),
                              tooltip: 'Менің QR Билетім',
                              icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.accentGold, size: 24),
                              onPressed: () {
                                final booking = _repo.bookings.isNotEmpty ? _repo.bookings.first : MockDataService.mockBookings.first;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: const EdgeInsets.all(20),
                                    child: QrTicketWidget(booking: booking),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(width: 2),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(),
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
                                if (NotificationService.instance.unreadCount > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                      child: Text(
                                        '${NotificationService.instance.unreadCount}',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() => _currentTabIndex = 4);
                            },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                              child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Орынды немесе облысты іздеу...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                              tooltip: 'Кеңейтілген сүзгілер',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Admin Guide Notification Alert Banner
                  if (((AuthService.instance.currentUser ?? _repo.currentUser)?.isAdmin ?? false) &&
                      AuthService.instance.pendingGuides.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)]),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_unread_rounded, color: Color(0xFFE65100), size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Жаңа гид өтінімі! (${AuthService.instance.pendingGuides.length} адам)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE65100)),
                                ),
                                Text(
                                  '${AuthService.instance.pendingGuides.first.fullName} мақұлдауды күтуде',
                                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE65100),
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                              );
                            },
                            child: const Text('Қарау 👑', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 7, 12, 13, 14, 15, 16. REST API & Cloud Status Bar
                  _buildApiStatusBar(),

                  const SizedBox(height: 12),

                  // Banner card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'REST API & Офлайн кэш жүйесі',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Деректер бұлттық REST серверімен және SQLite базасымен автоматты синхрондалады.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Selector
                  SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return CategoryChip(
                          label: cat,
                          isSelected: _selectedCategory == cat,
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Танымал бағыттар (${filtered.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _currentTabIndex = 1);
                        },
                        child: const Text(
                          'Барлығы',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 17. Empty state or Destinations List
          filtered.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Бағыттар табылмады',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Іздеу сөзін немесе категорияны өзгертіп көріңіз',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final place = filtered[index];
                        return PlaceCard(
                          place: place,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaceDetailScreen(place: place),
                              ),
                            );
                          },
                          onFavoriteTap: () => _toggleFavorite(place.id),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    ),
  );
}

  // Bookings Tab from SQLite with Update and Delete
  Widget _buildBookingsTab() {
    final bookings = _repo.bookings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Менің брондауларым (REST API & SQLite)'),
        automaticallyImplyLeading: false,
      ),
      body: bookings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.confirmation_number_outlined, size: 60, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Әзірге белсенді брондаулар жоқ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Турлар каталогынан өзіңізге ұнаған саяхатты таңдап, брондаңыз. Барлық деректер локалды сақталады.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () => setState(() => _currentTabIndex = 1),
                      child: const Text('Каталогқа өту', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _repo.syncWithServer(),
              child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                final isConfirmed = b.status == BookingStatus.confirmed;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            b.id,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isConfirmed
                                      ? AppColors.success.withOpacity(0.12)
                                      : AppColors.accentGold.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isConfirmed ? 'Расталды' : 'Күтілуде',
                                  style: TextStyle(
                                    color: isConfirmed ? AppColors.success : AppColors.accentGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // 9. PATCH /bookings/{id}
                              IconButton(
                                icon: const Icon(Icons.sync_alt, size: 18, color: AppColors.primary),
                                tooltip: 'Мәртебені ауыстыру (PATCH)',
                                onPressed: () async {
                                  final newStatus = isConfirmed ? BookingStatus.cancelled : BookingStatus.confirmed;
                                  await _repo.updateBookingStatus(b.id, newStatus);
                                },
                              ),
                              // 10. DELETE /bookings/{id}
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                tooltip: 'Брондауды өшіру (DELETE)',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                      title: const Text('Брондауды өшіру'),
                                      content: Text('№${b.id} брондауын деректер қорынан өшіргіңіз келе ме?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Жоқ')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Өшіру', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await _repo.deleteBooking(b.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        b.tourName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(b.date, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(width: 16),
                          const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('${b.peopleCount} адам', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                              label: const Text('QR Билетті ашу', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: QrTicketWidget(booking: b),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 10. Update booking status
                          TextButton.icon(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            icon: Icon(isConfirmed ? Icons.cancel_outlined : Icons.check_circle_outline,
                                size: 16, color: isConfirmed ? AppColors.accentGold : AppColors.success),
                            label: Text(
                              isConfirmed ? 'Күтуге ауыстыру' : 'Растау',
                              style: TextStyle(
                                fontSize: 12,
                                color: isConfirmed ? AppColors.accentGold : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () async {
                              final updated = b.copyWith(
                                status: isConfirmed ? BookingStatus.pending : BookingStatus.confirmed,
                              );
                              await _repo.updateBooking(updated);
                            },
                          ),
                          Row(
                            children: [
                              const Text('Жалпы құны: ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              Text(
                                '${b.totalPrice} ₸',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }
}
