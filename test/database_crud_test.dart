import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:steppetrip/models/tour_place.dart';
import 'package:steppetrip/models/booking_model.dart';
import 'package:steppetrip/models/review_model.dart';
import 'package:steppetrip/models/category_model.dart';
import 'package:steppetrip/models/favorite_model.dart';
import 'package:steppetrip/models/user_model.dart';
import 'package:steppetrip/services/database_helper.dart';
import 'package:steppetrip/services/tour_repository.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for headless desktop/testing environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Практикалық жұмыс №4: SQLite & Models & CRUD сынақтары', () {
    late Database db;

    setUp(() async {
      // 7. Initialize in-memory SQLite database for testing
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (database, version) async {
            // Create tables
            await database.execute('''
              CREATE TABLE tours (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                region TEXT NOT NULL,
                category TEXT NOT NULL,
                rating REAL NOT NULL,
                reviewsCount INTEGER NOT NULL,
                pricePerPerson INTEGER NOT NULL,
                description TEXT NOT NULL,
                imageUrl TEXT NOT NULL,
                highlights TEXT NOT NULL,
                bestSeason TEXT NOT NULL,
                isFavorite INTEGER NOT NULL DEFAULT 0
              )
            ''');

            await database.execute('''
              CREATE TABLE bookings (
                id TEXT PRIMARY KEY,
                tourId TEXT NOT NULL,
                tourName TEXT NOT NULL,
                date TEXT NOT NULL,
                peopleCount INTEGER NOT NULL,
                totalPrice INTEGER NOT NULL,
                status TEXT NOT NULL,
                clientName TEXT NOT NULL,
                clientPhone TEXT NOT NULL,
                notes TEXT,
                FOREIGN KEY (tourId) REFERENCES tours (id) ON DELETE CASCADE
              )
            ''');

            await database.execute('''
              CREATE TABLE reviews (
                id TEXT PRIMARY KEY,
                tourId TEXT NOT NULL,
                userName TEXT NOT NULL,
                rating INTEGER NOT NULL,
                comment TEXT NOT NULL,
                date TEXT NOT NULL,
                tags TEXT NOT NULL,
                userAvatar TEXT,
                FOREIGN KEY (tourId) REFERENCES tours (id) ON DELETE CASCADE
              )
            ''');

            await database.execute('''
              CREATE TABLE categories (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                iconName TEXT NOT NULL,
                placesCount INTEGER NOT NULL DEFAULT 0
              )
            ''');

            await database.execute('''
              CREATE TABLE users (
                id TEXT PRIMARY KEY,
                fullName TEXT NOT NULL,
                email TEXT NOT NULL,
                phone TEXT NOT NULL,
                avatarUrl TEXT NOT NULL,
                preferredLanguage TEXT NOT NULL,
                completedTours INTEGER NOT NULL DEFAULT 0
              )
            ''');

            await database.execute('''
              CREATE TABLE favorites (
                id TEXT PRIMARY KEY,
                userId TEXT NOT NULL,
                tourId TEXT NOT NULL,
                addedAt TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      DatabaseHelper.setMockDatabase(db);
    });

    tearDown(() async {
      await db.close();
      DatabaseHelper.setMockDatabase(null);
    });

    test('1-4. 4-6 Модельдердің құрылымын, өрістерін және байланысын тексеру', () {
      // TourPlace
      const tour = TourPlace(
        id: 'tp_test_1',
        name: 'Шарын шатқалы',
        region: 'Алматы облысы',
        category: 'Каньондар',
        rating: 4.8,
        reviewsCount: 120,
        pricePerPerson: 15000,
        description: 'Қазақстанның әйгілі каньоны',
        imageUrl: 'https://example.com/charyn.jpg',
        highlights: ['Табиғат', 'Фотосессия'],
        bestSeason: 'Сәуір - Қазан',
        isFavorite: true,
      );

      final tourMap = tour.toMap();
      expect(tourMap['id'], 'tp_test_1');
      expect(tourMap['isFavorite'], 1);

      final restoredTour = TourPlace.fromMap(tourMap);
      expect(restoredTour.name, 'Шарын шатқалы');
      expect(restoredTour.highlights.length, 2);
      expect(restoredTour.isFavorite, true);

      // BookingModel (tourId байланысы)
      const booking = BookingModel(
        id: 'BK-001',
        tourId: 'tp_test_1',
        tourName: 'Шарын шатқалы',
        date: '20.06.2026',
        peopleCount: 2,
        totalPrice: 30000,
        status: BookingStatus.confirmed,
        clientName: 'Әлішер Ербол',
        clientPhone: '+77071234567',
      );
      expect(booking.tourId, tour.id);

      // ReviewModel (tourId байланысы)
      const review = ReviewModel(
        id: 'rev_001',
        tourId: 'tp_test_1',
        userName: 'Айгүл',
        rating: 5,
        comment: 'Керемет жер!',
        date: '10.05.2026',
        tags: ['Таза ауа'],
      );
      expect(review.tourId, tour.id);

      // CategoryModel
      const cat = CategoryModel(id: 'cat_1', name: 'Каньондар', iconName: 'terrain');
      expect(cat.name, tour.category);

      // UserModel
      const user = UserModel(
        id: 'u_1',
        fullName: 'Әлішер',
        email: 'alisher@test.kz',
        phone: '+77011112233',
        avatarUrl: '',
      );

      // FavoriteModel (userId және tourId байланысы)
      const fav = FavoriteModel(id: 'f_1', userId: 'u_1', tourId: 'tp_test_1', addedAt: '2026-10-30');
      expect(fav.tourId, tour.id);
      expect(fav.userId, user.id);
    });

    test('8-11. SQLite CRUD операцияларын толық тексеру (Create, Read, Update, Delete)', () async {
      final helper = DatabaseHelper.instance;

      // 8. CREATE TOUR
      const newTour = TourPlace(
        id: 'tp_burabay',
        name: 'Бурабай Ұлттық паркі',
        region: 'Ақмола облысы',
        category: 'Ұлттық парктер',
        rating: 4.7,
        reviewsCount: 50,
        pricePerPerson: 16000,
        description: 'Қазақстан Швейцариясы',
        imageUrl: 'https://example.com/burabay.jpg',
        highlights: ['Оқжетпес', 'Жұмбақтас'],
        bestSeason: 'Жаз',
        isFavorite: false,
      );
      await helper.insertTour(newTour);

      // 9. READ TOURS
      var tours = await helper.getAllTours();
      expect(tours.length, 1);
      expect(tours.first.name, 'Бурабай Ұлттық паркі');

      // 10. UPDATE TOUR
      final updatedTour = newTour.copyWith(pricePerPerson: 18500, rating: 4.9);
      await helper.updateTour(updatedTour);

      final fetched = await helper.getTourById('tp_burabay');
      expect(fetched?.pricePerPerson, 18500);
      expect(fetched?.rating, 4.9);

      // 8. CREATE BOOKING
      const booking = BookingModel(
        id: 'BK-TEST-100',
        tourId: 'tp_burabay',
        tourName: 'Бурабай Ұлттық паркі',
        date: '15.07.2026',
        peopleCount: 3,
        totalPrice: 55500,
        status: BookingStatus.pending,
        clientName: 'Қайрат',
        clientPhone: '+77079998877',
      );
      await helper.insertBooking(booking);

      // 9. READ BOOKINGS
      var bookings = await helper.getAllBookings();
      expect(bookings.length, 1);
      expect(bookings.first.id, 'BK-TEST-100');

      // 10. UPDATE BOOKING
      await helper.updateBooking(booking.copyWith(status: BookingStatus.confirmed));
      bookings = await helper.getAllBookings();
      expect(bookings.first.status, BookingStatus.confirmed);

      // 11. DELETE BOOKING
      await helper.deleteBooking('BK-TEST-100');
      bookings = await helper.getAllBookings();
      expect(bookings.isEmpty, true);

      // 11. DELETE TOUR
      await helper.deleteTour('tp_burabay');
      tours = await helper.getAllTours();
      expect(tours.isEmpty, true);
    });

    test('13. Іздеу (Search) функциясын тексеру', () async {
      final helper = DatabaseHelper.instance;

      await helper.insertTour(const TourPlace(
        id: 'tp_1',
        name: 'Көлсай көлдері',
        region: 'Алматы облысы',
        category: 'Көлдер мен таулар',
        rating: 4.9,
        reviewsCount: 100,
        pricePerPerson: 18000,
        description: 'Тянь-Шань тауларының мөлдір көлдері',
        imageUrl: '',
        highlights: [],
        bestSeason: 'Жаз',
      ));

      await helper.insertTour(const TourPlace(
        id: 'tp_2',
        name: 'Ясауи кесенесі',
        region: 'Түркістан қаласы',
        category: 'Тарихи орындар',
        rating: 5.0,
        reviewsCount: 200,
        pricePerPerson: 22000,
        description: 'Ортағасырлық ғажайып сәулет',
        imageUrl: '',
        highlights: [],
        bestSeason: 'Жыл бойы',
      ));

      // Атауы бойынша іздеу
      final searchByName = await helper.searchAndFilterTours(query: 'Көлсай');
      expect(searchByName.length, 1);
      expect(searchByName.first.id, 'tp_1');

      // Аймағы бойынша іздеу
      final searchByRegion = await helper.searchAndFilterTours(query: 'Түркістан');
      expect(searchByRegion.length, 1);
      expect(searchByRegion.first.id, 'tp_2');

      // Табылмаған сұрау (Empty state тексерісі)
      final searchNotFound = await helper.searchAndFilterTours(query: 'Париж');
      expect(searchNotFound.isEmpty, true);
    });

    test('14. Сүзгілеу (Filter) критерийлерін тексеру', () async {
      final helper = DatabaseHelper.instance;

      await helper.insertTour(const TourPlace(
        id: 'tp_1',
        name: 'Көлсай',
        region: 'Алматы',
        category: 'Көлдер мен таулар',
        rating: 4.9,
        reviewsCount: 10,
        pricePerPerson: 15000,
        description: '',
        imageUrl: '',
        highlights: [],
        bestSeason: '',
      ));

      await helper.insertTour(const TourPlace(
        id: 'tp_2',
        name: 'Бозжыра',
        region: 'Маңғыстау',
        category: 'Каньондар',
        rating: 4.6,
        reviewsCount: 10,
        pricePerPerson: 35000,
        description: '',
        imageUrl: '',
        highlights: [],
        bestSeason: '',
      ));

      // Санат бойынша сүзгілеу
      final canyonFilter = await helper.searchAndFilterTours(category: 'Каньондар');
      expect(canyonFilter.length, 1);
      expect(canyonFilter.first.name, 'Бозжыра');

      // Баға бойынша сүзгілеу
      final cheapFilter = await helper.searchAndFilterTours(maxPrice: 20000);
      expect(cheapFilter.length, 1);
      expect(cheapFilter.first.name, 'Көлсай');

      // Рейтинг бойынша сүзгілеу
      final ratingFilter = await helper.searchAndFilterTours(minRating: 4.8);
      expect(ratingFilter.length, 1);
      expect(ratingFilter.first.name, 'Көлсай');
    });

    test('15. Кемінде екі параметр бойынша сұрыптауды (Sort) тексеру', () async {
      final helper = DatabaseHelper.instance;

      await helper.insertTour(const TourPlace(
        id: 'tp_a',
        name: 'Алма-Арасан',
        region: 'Алматы',
        category: 'Таулар',
        rating: 4.5,
        reviewsCount: 10,
        pricePerPerson: 10000,
        description: '',
        imageUrl: '',
        highlights: [],
        bestSeason: '',
      ));

      await helper.insertTour(const TourPlace(
        id: 'tp_b',
        name: 'Баянауыл',
        region: 'Павлодар',
        category: 'Парктер',
        rating: 4.9,
        reviewsCount: 20,
        pricePerPerson: 25000,
        description: '',
        imageUrl: '',
        highlights: [],
        bestSeason: '',
      ));

      // 1-параметр: Баға бойынша арзаннан қымбатқа (price_asc)
      final priceAsc = await helper.searchAndFilterTours(sortBy: 'price_asc');
      expect(priceAsc.first.pricePerPerson, 10000);
      expect(priceAsc.last.pricePerPerson, 25000);

      // 2-параметр: Баға бойынша қымбаттан арзанға (price_desc)
      final priceDesc = await helper.searchAndFilterTours(sortBy: 'price_desc');
      expect(priceDesc.first.pricePerPerson, 25000);
      expect(priceDesc.last.pricePerPerson, 10000);

      // 3-параметр: Рейтинг бойынша (rating_desc)
      final ratingDesc = await helper.searchAndFilterTours(sortBy: 'rating_desc');
      expect(ratingDesc.first.rating, 4.9);

      // 4-параметр: Атауы бойынша (name_asc)
      final nameAsc = await helper.searchAndFilterTours(sortBy: 'name_asc');
      expect(nameAsc.first.name, 'Алма-Арасан');
      expect(nameAsc.last.name, 'Баянауыл');
    });

    test('16. Favorites (Таңдаулылар) сақтау және өзгерту функциясын тексеру', () async {
      final helper = DatabaseHelper.instance;

      await helper.insertTour(const TourPlace(
        id: 'tp_fav_test',
        name: 'Қайыңды көлі',
        region: 'Алматы облысы',
        category: 'Көлдер',
        rating: 4.9,
        reviewsCount: 30,
        pricePerPerson: 17000,
        description: '',
        imageUrl: '',
        highlights: [],
        bestSeason: '',
        isFavorite: false,
      ));

      var favorites = await helper.getFavoriteTours();
      expect(favorites.isEmpty, true);

      // Таңдаулыға қосу
      final isFav1 = await helper.toggleFavorite('tp_fav_test');
      expect(isFav1, true);

      favorites = await helper.getFavoriteTours();
      expect(favorites.length, 1);
      expect(favorites.first.id, 'tp_fav_test');

      // Таңдаулыдан алу
      final isFav2 = await helper.toggleFavorite('tp_fav_test');
      expect(isFav2, false);

      favorites = await helper.getFavoriteTours();
      expect(favorites.isEmpty, true);
    });

    test('12. TourRepository интерфейсі арқылы жұмыс істеуді тексеру', () async {
      final repo = TourRepository.instance;
      await repo.initialize();

      // Жаңа тур қосу (Create)
      final added = await repo.createTour(const TourPlace(
        id: 'tp_repo_test',
        name: 'Шарын каньоны',
        region: 'Алматы облысы',
        category: 'Каньондар',
        rating: 4.8,
        reviewsCount: 15,
        pricePerPerson: 14000,
        description: 'Әдемі шатқал',
        imageUrl: '',
        highlights: [],
        bestSeason: 'Жаз',
      ));
      expect(added, true);
      expect(repo.tours.any((t) => t.id == 'tp_repo_test'), true);

      // Таңдаулыны ауыстыру (Favorite)
      await repo.toggleFavorite('tp_repo_test');
      expect(repo.favoriteTours.any((t) => t.id == 'tp_repo_test'), true);

      // Турды өшіру (Delete)
      final deleted = await repo.deleteTour('tp_repo_test');
      expect(deleted, true);
      expect(repo.tours.any((t) => t.id == 'tp_repo_test'), false);
    });
  });
}
