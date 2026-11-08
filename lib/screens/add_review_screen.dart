import 'package:flutter/material.dart';
import '../models/tour_place.dart';
import '../models/review_model.dart';
import '../services/tour_repository.dart';
import '../utils/theme_constants.dart';
import '../widgets/custom_button.dart';

class AddReviewScreen extends StatefulWidget {
  final TourPlace place;

  const AddReviewScreen({Key? key, required this.place}) : super(key: key);

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedRating = 5;
  final TextEditingController _reviewController = TextEditingController();
  final List<String> _selectedTags = [];

  final List<String> _availableTags = [
    'Таза ауа',
    'Керемет гид',
    'Ыңғайлы көлік',
    'Дәмді тағам',
    'Әдемі көрініс',
    'Қауіпсіз жол',
  ];

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate()) {
      final review = ReviewModel(
        id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
        tourId: widget.place.id,
        userName: TourRepository.instance.currentUser?.fullName ?? 'Әлішер Ерболұлы',
        rating: _selectedRating,
        comment: _reviewController.text.trim(),
        date: '${DateTime.now().day} Қазан ${DateTime.now().year}',
        tags: _selectedTags.isEmpty ? ['Керемет саяхат'] : _selectedTags,
      );

      final success = await TourRepository.instance.createReview(review);

      if (!mounted) return;

      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: AppColors.accentGold, size: 50),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Пікіріңізге рахмет!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Сіздің бағалауыңыз бен пікіріңіз локалды SQLite қорына сәтті қосылды және офлайн қолжетімді.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                CustomButton(
                  text: 'Жабу',
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TourRepository.instance.errorMessage ?? 'Пікірді қосу кезінде қате орын алды'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Пікір қалдыру'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.place.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, s) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.landscape, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.place.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(widget.place.region, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Star Rating
              const Center(
                child: Text(
                  'Сапарды қалай бағалайсыз?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      iconSize: 38,
                      icon: Icon(
                        starIndex <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.accentGold,
                      ),
                      onPressed: () {
                        setState(() => _selectedRating = starIndex);
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // Tags
              const Text('Ең ұнаған тұстары:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Text Field
              const Text('Толық пікіріңіз', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Сапардан алған әсеріңізбен бөлісіңіз...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (val) => val == null || val.length < 5 ? 'Пікір кемінде 5 таңбадан тұруы керек' : null,
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Пікірді жариялау',
                icon: Icons.rate_review_rounded,
                onPressed: _submitReview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
