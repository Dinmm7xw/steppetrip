import 'package:flutter/material.dart';
import '../services/tour_repository.dart';
import '../utils/theme_constants.dart';
import '../widgets/place_card.dart';
import 'place_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TourRepository _repo = TourRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _removeFavorite(String placeId) async {
    final success = await _repo.toggleFavorite(placeId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Таңдаулыларға қайта қосылды' : 'Таңдаулылардан алынды'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritePlaces = _repo.favoriteTours;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Таңдаулы орындар'),
        automaticallyImplyLeading: false,
      ),
      body: favoritePlaces.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border_rounded, size: 64, color: AppColors.primary),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Таңдаулылар тізімі бос',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Өзіңізге ұнаған турларды жүрекше батырмасын басып сақтаңыз. Олар осы жерде және офлайн режимде қолжетімді болады.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: favoritePlaces.length,
              itemBuilder: (context, index) {
                final place = favoritePlaces[index];
                return PlaceCard(
                  place: place,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
                    );
                  },
                  onFavoriteTap: () => _removeFavorite(place.id),
                );
              },
            ),
    );
  }
}
