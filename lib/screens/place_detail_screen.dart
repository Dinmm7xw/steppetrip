import 'package:flutter/material.dart';
import '../models/tour_place.dart';
import '../models/review_model.dart';
import '../services/tour_repository.dart';
import '../utils/theme_constants.dart';
import '../widgets/custom_button.dart';
import 'booking_screen.dart';
import 'add_review_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  final TourPlace place;

  const PlaceDetailScreen({Key? key, required this.place}) : super(key: key);

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late TourPlace _currentPlace;
  late bool _isFavorite;
  List<ReviewModel> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _currentPlace = widget.place;
    _isFavorite = widget.place.isFavorite;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final list = await TourRepository.instance.getReviewsForTour(_currentPlace.id);
    if (mounted) {
      setState(() {
        _reviews = list;
        _loadingReviews = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final newStatus = await TourRepository.instance.toggleFavorite(_currentPlace.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = newStatus;
      _currentPlace = _currentPlace.copyWith(isFavorite: newStatus);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Таңдаулыларға қосылды (SQLite)!' : 'Таңдаулылардан алынды'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 10. Update Tour operation
  Future<void> _showEditTourDialog() async {
    final nameCtrl = TextEditingController(text: _currentPlace.name);
    final priceCtrl = TextEditingController(text: _currentPlace.pricePerPerson.toString());
    final descCtrl = TextEditingController(text: _currentPlace.description);

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Турды өзгерту (Update)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
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
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Бағасы (бір адамға, ₸)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 4,
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болдырмау'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newPrice = int.tryParse(priceCtrl.text) ?? _currentPlace.pricePerPerson;
              final editedTour = _currentPlace.copyWith(
                name: nameCtrl.text.trim(),
                pricePerPerson: newPrice,
                description: descCtrl.text.trim(),
              );
              final success = await TourRepository.instance.updateTour(editedTour);
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
      final fresh = await TourRepository.instance.searchFilterSort(query: _currentPlace.name);
      if (!mounted) return;
      if (fresh.isNotEmpty) {
        setState(() => _currentPlace = fresh.first);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тур деректері SQLite қорында сәтті жаңартылды!')),
      );
    }
  }

  // 11. Delete Tour operation
  Future<void> _confirmDeleteTour() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Турды өшіру (Delete)', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('${_currentPlace.name} турын локалды деректер қорынан біржола өшіргіңіз келе ме?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Жоқ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Иә, өшіру', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await TourRepository.instance.deleteTour(_currentPlace.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Тур деректер қорынан өшірілді')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = _currentPlace;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Dynamic Header Image
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              // Edit button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    onPressed: _showEditTourDialog,
                  ),
                ),
              ),
              // Delete button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    onPressed: _confirmDeleteTour,
                  ),
                ),
              ),
              // Favorite button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : AppColors.textPrimary,
                      size: 20,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                place.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.primaryLight,
                  child: const Center(child: Icon(Icons.landscape, size: 80, color: Colors.white)),
                ),
              ),
            ),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Region
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.region,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stat Badges Row
                  Row(
                    children: [
                      _buildStatBadge(
                        icon: Icons.star_rounded,
                        iconColor: AppColors.accentGold,
                        title: '${place.rating}',
                        subtitle: '${place.reviewsCount} пікір',
                      ),
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        icon: Icons.calendar_month,
                        iconColor: AppColors.primary,
                        title: 'Маусым',
                        subtitle: place.bestSeason,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        icon: Icons.category,
                        iconColor: AppColors.primaryLight,
                        title: 'Санат',
                        subtitle: place.category,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Highlights / Ерекшеліктері
                  const Text(
                    'Тур ерекшеліктері',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: place.highlights.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              item,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Description / Сипаттамасы
                  const Text(
                    'Толық сипаттамасы',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    place.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add Review Action Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Бұл турға пікір қалдыру', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddReviewScreen(place: place)),
                      );
                      _loadReviews();
                    },
                  ),
                  const SizedBox(height: 24),

                  // 9. Read: Reviews List from SQLite
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Пікірлер мен бағалаулар (SQLite)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${_reviews.length} пікір',
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_loadingReviews)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (_reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('Бұл тур бойынша әзірге пікір жоқ. Алғашқы болып пікір қалдырыңыз!',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ),
                    )
                  else
                    ..._reviews.map((rev) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primaryLight,
                                        child: Text(
                                          rev.userName.isNotEmpty ? rev.userName[0] : '?',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(rev.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (i) => Icon(
                                          i < rev.rating ? Icons.star : Icons.star_border,
                                          color: AppColors.accentGold,
                                          size: 15,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                        onPressed: () async {
                                          await TourRepository.instance.deleteReview(rev.id, place.id);
                                          _loadReviews();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(rev.comment, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                              const SizedBox(height: 6),
                              Text(rev.date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        )),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Бір адамға:',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Text(
                    '${place.pricePerPerson} ₸',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: CustomButton(
                  text: 'Брондау',
                  icon: Icons.calendar_today_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(place: place),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
