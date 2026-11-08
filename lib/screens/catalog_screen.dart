import 'package:flutter/material.dart';
import '../models/tour_place.dart';
import '../services/tour_repository.dart';
import '../utils/theme_constants.dart';
import '../widgets/place_card.dart';
import 'place_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TourRepository _repo = TourRepository.instance;
  String _selectedCategory = 'Барлығы';
  String _sortBy = 'Рейтинг бойынша';

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
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // 14. Filtering & 15. Sorting by multiple parameters
  List<TourPlace> get _sortedPlaces {
    var list = _repo.tours.where((p) {
      return _selectedCategory == 'Барлығы' || p.category == _selectedCategory;
    }).toList();

    if (_sortBy == 'Бағасы (арзаннан)') {
      list.sort((a, b) => a.pricePerPerson.compareTo(b.pricePerPerson));
    } else if (_sortBy == 'Бағасы (қымбаттан)') {
      list.sort((a, b) => b.pricePerPerson.compareTo(a.pricePerPerson));
    } else if (_sortBy == 'Атауы (А-Я)') {
      list.sort((a, b) => a.name.compareTo(b.name));
    } else {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  // 8. Create Operation: Add new tour dialog
  Future<void> _showAddTourDialog() async {
    final nameCtrl = TextEditingController();
    final regionCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Көлдер мен таулар';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Жаңа тур қосу (Create)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  controller: regionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Аймағы (облыс, аудан)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: 'Санаты',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _categories
                      .where((c) => c != 'Барлығы')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Бағасы (1 адамға, ₸)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
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
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                final newTour = TourPlace(
                  id: 'tp_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  region: regionCtrl.text.trim().isEmpty ? 'Қазақстан' : regionCtrl.text.trim(),
                  category: category,
                  rating: 5.0,
                  reviewsCount: 1,
                  pricePerPerson: int.tryParse(priceCtrl.text) ?? 20000,
                  description: descCtrl.text.trim().isEmpty ? 'Жаңа саяхат орны' : descCtrl.text.trim(),
                  imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
                  highlights: ['Жаңа бағыт', 'Таза табиғат', 'Керемет демалыс'],
                  bestSeason: 'Мамыр - Қазан',
                  isFavorite: false,
                );

                final success = await _repo.createTour(newTour);
                if (context.mounted) {
                  Navigator.pop(context, success);
                }
              },
              child: const Text('Қосу (SQLite)', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Жаңа тур SQLite деректер қорына сәтті қосылды!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = _sortedPlaces;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Турлар каталогы'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'Жаңа тур қосу',
            onPressed: _showAddTourDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category selector horizontally
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // Sorting & stats bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${places.length} бағыт табылды',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, size: 18, color: AppColors.primary),
                  items: const [
                    DropdownMenuItem(value: 'Рейтинг бойынша', child: Text('Рейтинг бойынша', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'Бағасы (арзаннан)', child: Text('Бағасы (арзаннан)', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'Бағасы (қымбаттан)', child: Text('Бағасы (қымбаттан)', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'Атауы (А-Я)', child: Text('Атауы (А-Я)', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ],
            ),
          ),

          // 17. Empty state or List of Places
          Expanded(
            child: places.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.travel_explore, size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 14),
                          const Text(
                            'Бұл санатта әзірге турлар жоқ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Басқа санатты таңдаңыз немесе «+» батырмасымен жаңа тур қосыңыз.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: _showAddTourDialog,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Жаңа тур қосу', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return PlaceCard(
                        place: place,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PlaceDetailScreen(place: place)),
                          );
                        },
                        onFavoriteTap: () => _repo.toggleFavorite(place.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
