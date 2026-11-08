import 'package:flutter/material.dart';
import '../models/tour_place.dart';
import '../services/tour_repository.dart';
import '../utils/theme_constants.dart';
import '../widgets/place_card.dart';
import 'place_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TourRepository _repo = TourRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Барлығы';
  RangeValues _priceRange = const RangeValues(10000, 45000);
  double _minRating = 4.0;
  bool _showFilters = false;

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
    _searchController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  // 13. Search & 14. Filter
  List<TourPlace> get _filteredResults {
    return _repo.tours.where((place) {
      final matchesQuery = _searchQuery.isEmpty ||
          place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          place.region.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          place.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'Барлығы' || place.category == _selectedCategory;
      final matchesPrice = place.pricePerPerson >= _priceRange.start && place.pricePerPerson <= _priceRange.end;
      final matchesRating = place.rating >= _minRating;

      return matchesQuery && matchesCat && matchesPrice && matchesRating;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Барлығы';
      _priceRange = const RangeValues(10000, 45000);
      _minRating = 4.0;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Бағыттарды іздеу'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _showFilters ? AppColors.accentGold : AppColors.primary,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Таулар, көлдер, каньондар...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Collapsible Filters Panel
          if (_showFilters)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Сүзгілер (SQLite бойынша)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Тазарту', style: TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ),

                  // Categories
                  const Text('Санат бойынша:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Баға диапазоны:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        '${_priceRange.start.toInt()} ₸ - ${_priceRange.end.toInt()} ₸',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 10000,
                    max: 45000,
                    divisions: 7,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    labels: RangeLabels('${_priceRange.start.toInt()}', '${_priceRange.end.toInt()}'),
                    onChanged: (vals) => setState(() => _priceRange = vals),
                  ),
                ],
              ),
            ),

          // Results counter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Табылғаны: ${results.length} бағыт',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // 17. Empty state or Results List
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Сұрауыңыз бойынша ештеңе табылмады',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Сүзгілерді немесе іздеу сөзін өзгертіп көріңіз',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final place = results[index];
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
