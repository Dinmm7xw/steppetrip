import 'package:flutter/foundation.dart';
import '../models/tour_place.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import 'database_helper.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

/// Практикалық жұмыс №5: Repository Pattern & Offline-First REST API Sync
class TourRepository extends ChangeNotifier {
  static final TourRepository instance = TourRepository._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  ApiService _apiService = ApiService.instance;

  TourRepository._internal();

  // Test setup helper to inject custom or mock ApiService
  void setApiServiceForTesting(ApiService api) {
    _apiService = api;
  }

  ApiService get apiService => _apiService;

  List<TourPlace> _tours = [];
  List<TourPlace> _favoriteTours = [];
  List<BookingModel> _bookings = [];
  List<CategoryModel> _categories = [];
  UserModel? _currentUser;

  // 12. Loading күйі
  bool _isLoading = false;

  // 13. Сәттілік хабарламасы (Success state)
  String? _successMessage;

  // 14, 15, 16, 17. Қате күйлері (Error state)
  String? _errorMessage;

  // 15, 18. Желі күйі мен жергілікті байланыс
  bool _isOfflineMode = false;
  DateTime? _lastSyncTime;

  // Getters
  List<TourPlace> get tours => _tours;
  List<TourPlace> get favoriteTours => _favoriteTours;
  List<BookingModel> get bookings => _bookings;
  List<CategoryModel> get categories => _categories;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get successMessage => _successMessage;
  String? get errorMessage => _errorMessage;
  bool get isOfflineMode => _isOfflineMode;
  DateTime? get lastSyncTime => _lastSyncTime;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearMessages() {
    _successMessage = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ==========================================================================
  // 11. async/await & 18. Серверлік деректерді локалды SQLite-пен синхрондау
  // ==========================================================================

  /// Initialize: алдымен SQLite-тан жүктейді, сосын сервермен синхрондайды
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Жергілікті SQLite қорын іске қосу
      await _dbHelper.database;
      await refreshAllData();

      // 2. Сервермен (REST API) синхрондау
      await syncWithServer();
    } catch (e, stack) {
      debugPrint('Error initializing: $e\n$stack');
      _errorMessage = 'Инициализация кезінде қате орын алды: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 5, 18. Серверден GET сұрауы арқылы барлық деректерді алып, SQLite-қа сақтау
  Future<bool> syncWithServer() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 5. GET /tours
      final remoteTours = await _apiService.getTours();
      // 18. Сервер деректерін жергілікті SQLite базасына сақтау
      for (var tour in remoteTours) {
        await _dbHelper.insertTour(tour);
      }

      // 5. GET /bookings
      final remoteBookings = await _apiService.getBookings();
      for (var b in remoteBookings) {
        await _dbHelper.insertBooking(b);
      }

      _isOfflineMode = false;
      _lastSyncTime = DateTime.now();
      _successMessage = 'Сервермен синхрондау сәтті аяқталды (HTTP 200 OK)';

      await refreshAllData();
      return true;
    } on NetworkException catch (e) {
      // 15. Интернет байланысы жоқ болғанда
      _isOfflineMode = true;
      _errorMessage = e.message;
      debugPrint('Sync failed (offline): ${e.message}');
      await refreshAllData(); // Локалды базадан оқиды
      return false;
    } on ApiTimeoutException catch (e) {
      // 16. Сервер timeout болғанда
      _isOfflineMode = true;
      _errorMessage = e.message;
      debugPrint('Sync timeout: ${e.message}');
      await refreshAllData();
      return false;
    } on ServerException catch (e) {
      // 14. Сервер қатесі (500)
      _errorMessage = e.message;
      debugPrint('Server error: ${e.message}');
      await refreshAllData();
      return false;
    } catch (e) {
      // 17. Басқа қателер
      _errorMessage = 'Синхрондау қатесі: $e';
      await refreshAllData();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Жергілікті SQLite деректерін оқу (Local Read)
  Future<void> refreshAllData() async {
    try {
      _tours = await _dbHelper.getAllTours();
      _favoriteTours = await _dbHelper.getFavoriteTours();
      _bookings = await _dbHelper.getAllBookings();
      _categories = await _dbHelper.getAllCategories();
      _currentUser = await _dbHelper.getUserProfile();
    } catch (e) {
      debugPrint('Error loading local data: $e');
      _errorMessage = 'Локалды деректерді оқу қатесі';
    }

    // Web немесе бастапқы жүктелу үшін MockData fallback
    if (_tours.isEmpty) {
      _tours = List.from(MockDataService.tourPlaces);
      _favoriteTours = _tours.where((t) => t.isFavorite).toList();
      _bookings = List.from(MockDataService.mockBookings);
      _currentUser ??= MockDataService.currentUser;
    }
    notifyListeners();
  }

  // ==========================================================================
  // 8. POST СҰРАУЛАРЫ (CREATE) - Серверге жіберу және локалды сақтау
  // ==========================================================================

  /// 8, 18. POST /tours - жаңа турды серверге жіберу және SQLite-қа жазу
  Future<bool> createTour(TourPlace tour) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Серверге POST сұрауын орындау
      final createdTour = await _apiService.createTour(tour);
      // 2. Локалды SQLite базасына да сақтау
      await _dbHelper.insertTour(createdTour);
      _successMessage = 'Жаңа тур серверге сәтті қосылды (HTTP 201 Created)';
      await refreshAllData();
      return true;
    } on NetworkException catch (e) {
      // Офлайн режимде жергілікті сақтап қою
      _isOfflineMode = true;
      await _dbHelper.insertTour(tour);
      _errorMessage = 'Желі жоқ: Тур локалды сақталды (${e.message})';
      await refreshAllData();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Турды қосу қатесі: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 8, 18. POST /bookings - жаңа брондау жасау
  Future<bool> createBooking(BookingModel booking) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final created = await _apiService.createBooking(booking);
      await _dbHelper.insertBooking(created);
      _successMessage = 'Брондау серверге сәтті тіркелді (HTTP 201 Created)';
      await refreshAllData();
      return true;
    } on NetworkException catch (e) {
      _isOfflineMode = true;
      await _dbHelper.insertBooking(booking);
      _errorMessage = 'Желі жоқ: Брондау локалды сақталды (${e.message})';
      await refreshAllData();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Брондау қатесі: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 8, 18. POST /reviews - пікір қалдыру
  Future<bool> createReview(ReviewModel review) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final created = await _apiService.createReview(review);
      await _dbHelper.insertReview(created);
      _successMessage = 'Пікіріңіз серверге сәтті қосылды (HTTP 201 Created)';
      await refreshAllData();
      return true;
    } on NetworkException catch (e) {
      _isOfflineMode = true;
      await _dbHelper.insertReview(review);
      _errorMessage = 'Желі жоқ: Пікір локалды сақталды (${e.message})';
      await refreshAllData();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Пікір қосу қатесі: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================================================
  // 9. PUT ЖӘНЕ PATCH СҰРАУЛАРЫ (UPDATE)
  // ==========================================================================

  /// 9, 18. PUT /tours/{id} - тур мәліметін толық жаңарту
  Future<bool> updateTour(TourPlace tour) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateTour(tour.id, tour);
      await _dbHelper.updateTour(updated);
      _successMessage = 'Тур мәліметі серверде сәтті жаңартылды (HTTP 200 OK)';
      await refreshAllData();
      return true;
    } on NetworkException catch (e) {
      _isOfflineMode = true;
      await _dbHelper.updateTour(tour);
      _errorMessage = 'Желі жоқ: Локалды жаңартылды (${e.message})';
      await refreshAllData();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Турды өзгерту қатесі: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 9, 18. PATCH /bookings/{id} - брондау мәртебесін өзгерту
  Future<bool> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _apiService.patchBookingStatus(bookingId, newStatus);
      await _dbHelper.updateBooking(updated);
      _successMessage = 'Брондау мәртебесі серверде жаңартылды (HTTP 200 OK)';
      await refreshAllData();
      return true;
    } on NetworkException catch (e) {
      _isOfflineMode = true;
      final local = _bookings.firstWhere((b) => b.id == bookingId).copyWith(status: newStatus);
      await _dbHelper.updateBooking(local);
      _errorMessage = 'Желі жоқ: Мәртебе локалды жаңартылды (${e.message})';
      await refreshAllData();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Мәртебені өзгерту қатесі: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update booking backward-compatibility helper
  Future<bool> updateBooking(BookingModel booking) async {
    return await updateBookingStatus(booking.id, booking.status);
  }

  /// Update user profile
  Future<bool> updateProfile(UserModel user) async {
    try {
      await _dbHelper.updateUserProfile(user);
      _currentUser = user;
      _successMessage = 'Профиль сәтті жаңартылды';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Профильді жаңарту сәтсіз аяқталды';
      notifyListeners();
      return false;
    }
  }

  // ==========================================================================
  // 10. DELETE СҰРАУЛАРЫ
  // ==========================================================================

  /// 10, 18. DELETE /tours/{id} - турды өшіру
  Future<bool> deleteTour(String id) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteTour(id);
      await _dbHelper.deleteTour(id);
      _successMessage = 'Тур серверден және базадан сәтті өшірілді (HTTP 200 OK)';
      await refreshAllData();
      return true;
    } on NetworkException catch (e) {
      _isOfflineMode = true;
      await _dbHelper.deleteTour(id);
      _errorMessage = 'Желі жоқ: Тур локалды өшірілді (${e.message})';
      await refreshAllData();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Турды өшіру қатесі: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 10, 18. DELETE /bookings/{id} - брондауды өшіру
  Future<bool> deleteBooking(String id) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteBooking(id);
      await _dbHelper.deleteBooking(id);
      _successMessage = 'Брондау серверден сәтті өшірілді (HTTP 200 OK)';
      await refreshAllData();
      return true;
    } on NetworkException catch (e) {
      _isOfflineMode = true;
      await _dbHelper.deleteBooking(id);
      _errorMessage = 'Желі жоқ: Брондау локалды өшірілді (${e.message})';
      await refreshAllData();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Брондауды өшіру қатесі: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 10, 18. DELETE /reviews/{id} - пікірді өшіру
  Future<bool> deleteReview(String id, String tourId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteReview(id);
      await _dbHelper.deleteReview(id, tourId);
      _successMessage = 'Пікір серверден сәтті жойылды';
      await refreshAllData();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Пікірді өшіру қатесі: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================================================
  // ТАҢДАУЛЫЛАР ЖӘНЕ ІЗДЕУ (SQLite жергілікті мүмкіндіктері)
  // ==========================================================================

  Future<bool> toggleFavorite(String tourId) async {
    try {
      final isNowFavorite = await _dbHelper.toggleFavorite(tourId);
      await refreshAllData();
      return isNowFavorite;
    } catch (e) {
      _errorMessage = 'Таңдаулыларды өзгерту кезінде қате пайда болды';
      notifyListeners();
      return false;
    }
  }

  Future<List<TourPlace>> searchFilterSort({
    String query = '',
    String category = 'Барлығы',
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String sortBy = 'rating_desc',
  }) async {
    try {
      return await _dbHelper.searchAndFilterTours(
        query: query,
        category: category,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        sortBy: sortBy,
      );
    } catch (e) {
      _errorMessage = 'Іздеу кезінде қате орын алды';
      notifyListeners();
      return [];
    }
  }

  Future<List<ReviewModel>> getReviewsForTour(String tourId) async {
    try {
      // 18. Алдымен серверден жаңартып алуға тырысамыз
      try {
        final remote = await _apiService.getReviews(tourId);
        for (var r in remote) {
          await _dbHelper.insertReview(r);
        }
      } catch (_) {
        // Офлайн болса жергіліктісін қолданады
      }
      return await _dbHelper.getReviewsForTour(tourId);
    } catch (e) {
      return [];
    }
  }

  Future<void> resetToDefault() async {
    try {
      await _dbHelper.clearAllData();
      await refreshAllData();
    } catch (e) {
      debugPrint('Error resetting data: $e');
    }
  }
}
