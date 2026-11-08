import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:steppetrip/models/tour_place.dart';
import 'package:steppetrip/models/booking_model.dart';
import 'package:steppetrip/models/review_model.dart';
import 'package:steppetrip/services/api_service.dart';
import 'package:steppetrip/services/database_helper.dart';
import 'package:steppetrip/services/tour_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Практикалық жұмыс №5: REST API, JSON Models, Error Handling & SQLite Sync', () {
    late ApiService api;
    late Database inMemoryDb;
    late TourRepository repo;

    setUp(() async {
      // 1. Инициализация ApiService (симуляциялық сервер режимінде)
      api = ApiService(simulateBackend: true);
      api.forceSimulateNetworkError = false;
      api.forceSimulateTimeout = false;
      api.forceSimulateServerError = false;

      // 2. Инициализация In-Memory SQLite деректер қоры
      inMemoryDb = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
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
            await db.execute('''
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
                notes TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE reviews (
                id TEXT PRIMARY KEY,
                tourId TEXT NOT NULL,
                userName TEXT NOT NULL,
                rating INTEGER NOT NULL,
                comment TEXT NOT NULL,
                date TEXT NOT NULL,
                tags TEXT NOT NULL,
                userAvatar TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE categories (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                iconName TEXT NOT NULL,
                placesCount INTEGER NOT NULL DEFAULT 0
              )
            ''');
            await db.execute('''
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
            await db.execute('''
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

      DatabaseHelper.setMockDatabase(inMemoryDb);
      repo = TourRepository.instance;
      repo.setApiServiceForTesting(api);
      await repo.initialize();
    });

    tearDown(() async {
      await inMemoryDb.close();
      DatabaseHelper.setMockDatabase(null);
    });

    // ========================================================================
    // 5 & 6. GET СҰРАУЫ ЖӘНЕ JSON -> DART MODEL ТҮРЛЕНДІРУ
    // ========================================================================
    test('5 & 6. GET /tours - Серверден деректерді алу және TourPlace моделіне түрлендіру', () async {
      final tours = await api.getTours();

      expect(tours, isNotEmpty);
      expect(tours.first, isA<TourPlace>());
      expect(tours.first.id, equals('tp_01'));
      expect(tours.first.name, contains('Көлсай'));
      expect(tours.first.pricePerPerson, greaterThan(0));
      expect(tours.first.highlights, isA<List<String>>());

      // JSON се Serialization / Deserialization тесті
      final jsonMap = tours.first.toJson();
      final fromJsonTour = TourPlace.fromJson(jsonMap);
      expect(fromJsonTour.id, equals(tours.first.id));
      expect(fromJsonTour.name, equals(tours.first.name));
    });

    test('5 & 6. GET /bookings - Серверден брондауларды алу және BookingModel моделіне түрлендіру', () async {
      final bookings = await api.getBookings();

      expect(bookings, isNotEmpty);
      expect(bookings.first, isA<BookingModel>());
      expect(bookings.first.id, startsWith('BK-'));
      expect(bookings.first.totalPrice, greaterThan(0));

      final jsonMap = bookings.first.toJson();
      final fromJsonBooking = BookingModel.fromJson(jsonMap);
      expect(fromJsonBooking.id, equals(bookings.first.id));
      expect(fromJsonBooking.status, equals(bookings.first.status));
    });

    test('5 & 6. GET /reviews - Тур бойынша пікірлерді алу және ReviewModel моделіне түрлендіру', () async {
      final reviews = await api.getReviews('tp_01');

      expect(reviews, isNotEmpty);
      expect(reviews.first, isA<ReviewModel>());
      expect(reviews.first.tourId, equals('tp_01'));
      expect(reviews.first.rating, equals(5));

      final jsonMap = reviews.first.toJson();
      final fromJsonRev = ReviewModel.fromJson(jsonMap);
      expect(fromJsonRev.id, equals(reviews.first.id));
      expect(fromJsonRev.userName, equals(reviews.first.userName));
    });

    // ========================================================================
    // 8. POST СҰРАУЛАРЫ (CREATE)
    // ========================================================================
    test('8. POST /tours - Жаңа саяхат орнын серверге жіберу (HTTP 201 Created)', () async {
      const newTour = TourPlace(
        id: 'tp_test_100',
        name: 'Алтын Емел (Әнші құм)',
        region: 'Алматы облысы',
        category: 'Ұлттық парктер',
        rating: 4.9,
        reviewsCount: 75,
        pricePerPerson: 25000,
        description: 'Әнші құм мен Ақтау, Қатутау борлы таулары',
        imageUrl: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9',
        highlights: ['Әнші құм', 'Ақтау таулары'],
        bestSeason: 'Мамыр - Қыркүйек',
        isFavorite: false,
      );

      final created = await api.createTour(newTour);

      expect(created.id, equals('tp_test_100'));
      expect(created.name, equals('Алтын Емел (Әнші құм)'));

      // Серверден қайта оқып тексеру
      final fetched = await api.getTourById('tp_test_100');
      expect(fetched.name, equals('Алтын Емел (Әнші құм)'));
      expect(fetched.pricePerPerson, equals(25000));
    });

    test('8. POST /bookings - Жаңа брондауды серверге жіберу', () async {
      const newBooking = BookingModel(
        id: 'BK-2026-9999',
        tourId: 'tp_01',
        tourName: 'Көлсай және Қайыңды көлдері',
        date: '25.11.2026',
        peopleCount: 3,
        totalPrice: 55500,
        status: BookingStatus.confirmed,
        clientName: 'Айдос Нұрлан',
        clientPhone: '+7 777 000 11 22',
        notes: 'REST API сынағы',
      );

      final created = await api.createBooking(newBooking);

      expect(created.id, equals('BK-2026-9999'));
      expect(created.clientName, equals('Айдос Нұрлан'));
      expect(created.totalPrice, equals(55500));

      final allBookings = await api.getBookings();
      expect(allBookings.any((b) => b.id == 'BK-2026-9999'), isTrue);
    });

    // ========================================================================
    // 9. PUT ЖӘНЕ PATCH СҰРАУЛАРЫ (UPDATE)
    // ========================================================================
    test('9. PUT /tours/{id} - Бар ақпаратты серверде толық өзгерту', () async {
      final original = await api.getTourById('tp_01');
      final updatedTour = original.copyWith(
        name: 'Көлсай, Қайыңды және Қара көл (Жаңартылған)',
        pricePerPerson: 21000,
        description: 'Жаңартылған сипаттама мен қызметтер тізімі',
      );

      final result = await api.updateTour('tp_01', updatedTour);

      expect(result.name, equals('Көлсай, Қайыңды және Қара көл (Жаңартылған)'));
      expect(result.pricePerPerson, equals(21000));

      final reFetched = await api.getTourById('tp_01');
      expect(reFetched.name, equals('Көлсай, Қайыңды және Қара көл (Жаңартылған)'));
    });

    test('9. PATCH /bookings/{id} - Брондау мәртебесін өзгерту (Status Update)', () async {
      final bookings = await api.getBookings();
      final target = bookings.first;

      // Мәртебені cancelled-ке өзгерту
      final patched = await api.patchBookingStatus(target.id, BookingStatus.cancelled);
      expect(patched.status, equals(BookingStatus.cancelled));

      final reFetched = await api.getBookings();
      final updated = reFetched.firstWhere((b) => b.id == target.id);
      expect(updated.status, equals(BookingStatus.cancelled));
    });

    // ========================================================================
    // 10. DELETE СҰРАУЛАРЫ (DELETE)
    // ========================================================================
    test('10. DELETE /tours/{id} - Саяхат орнын серверден өшіру', () async {
      // Алдымен сынақтық тур қосамыз
      const tempTour = TourPlace(
        id: 'tp_delete_me',
        name: 'Өшірілетін тур',
        region: 'Алматы',
        category: 'Эко-турлар',
        rating: 4.0,
        reviewsCount: 1,
        pricePerPerson: 10000,
        description: 'Өшірілуге арналған сынақ туры',
        imageUrl: 'https://unsplash.com/test.jpg',
        highlights: ['Сынақ'],
        bestSeason: 'Жыл бойы',
      );
      await api.createTour(tempTour);

      // Өшіру сұрауын орындау
      final deleted = await api.deleteTour('tp_delete_me');
      expect(deleted, isTrue);

      // Өшірілген соң оқу NotFoundException (404) беруі тиіс
      expect(
        () async => await api.getTourById('tp_delete_me'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('10. DELETE /bookings/{id} - Брондауды жою', () async {
      final bookings = await api.getBookings();
      final targetId = bookings.first.id;

      final deleted = await api.deleteBooking(targetId);
      expect(deleted, isTrue);

      final reFetched = await api.getBookings();
      expect(reFetched.any((b) => b.id == targetId), isFalse);
    });

    // ========================================================================
    // 14, 15, 16, 17. ҚАТЕЛЕРДІ ЖӘНЕ ЕРЕКШЕ ЖАҒДАЙЛАРДЫ ӨҢДЕУ (EXCEPTIONS)
    // ========================================================================
    test('14. Сервер 404 (NotFoundException) және 500 (ServerException) қателерін өңдеу', () async {
      // 404
      expect(
        () async => await api.getTourById('non_existent_id_9999'),
        throwsA(isA<NotFoundException>()),
      );

      // 500
      api.forceSimulateServerError = true;
      expect(
        () async => await api.getTours(),
        throwsA(isA<ServerException>()),
      );
    });

    test('15. Интернет байланысы болмаған жағдайды (NetworkException) өңдеу', () async {
      api.forceSimulateNetworkError = true;

      expect(
        () async => await api.getTours(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('16. Сервер ұзақ жауап берген кездегі Timeout жағдайын өңдеу', () async {
      api.forceSimulateTimeout = true;

      expect(
        () async => await api.getTours(),
        throwsA(isA<ApiTimeoutException>()),
      );
    });

    // ========================================================================
    // 18. СЕРВЕРДЕН АЛЫНҒАН ДЕРЕКТЕРДІ ЛОКАЛДЫ SQLite-ПЕН БАЙЛАНЫСТЫРУ
    // ========================================================================
    test('18. Серверлік деректерді SQLite базасына синхрондау және кэштеу', () async {
      // Серверден деректерді алып SQLite-қа сақтау
      final syncSuccess = await repo.syncWithServer();
      expect(syncSuccess, isTrue);
      expect(repo.isOfflineMode, isFalse);
      expect(repo.tours, isNotEmpty);

      // Жергілікті SQLite қорынан тікелей тексеру
      final localTours = await DatabaseHelper.instance.getAllTours();
      expect(localTours.length, equals(repo.tours.length));

      // Енді желіні өшіріп тексереміз (Offline fallback)
      api.forceSimulateNetworkError = true;
      final offlineSync = await repo.syncWithServer();
      expect(offlineSync, isFalse);
      expect(repo.isOfflineMode, isTrue);
      // Желі болмаса да деректер SQLite кэшінен қолжетімді болып қалады!
      expect(repo.tours, isNotEmpty);
    });

    test('18. POST жасағанда әрі Серверге әрі SQLite қорына қатар сақталуы', () async {
      const tourToSync = TourPlace(
        id: 'tp_both_sync',
        name: 'Шарын Каньоны (Синхронды тур)',
        region: 'Алматы облысы',
        category: 'Каньондар',
        rating: 4.8,
        reviewsCount: 10,
        pricePerPerson: 18000,
        description: 'Серверлік және жергілікті синхрондау тесті',
        imageUrl: 'https://images.unsplash.com/photo-1511447333015-45b65e60f6d5',
        highlights: ['Синхронизация'],
        bestSeason: 'Мамыр',
      );

      final success = await repo.createTour(tourToSync);
      expect(success, isTrue);

      // 1. Серверден тексеру
      final serverTour = await api.getTourById('tp_both_sync');
      expect(serverTour.name, equals('Шарын Каньоны (Синхронды тур)'));

      // 2. Локалды SQLite-тан тексеру
      final localTour = await DatabaseHelper.instance.getTourById('tp_both_sync');
      expect(localTour, isNotNull);
      expect(localTour!.name, equals('Шарын Каньоны (Синхронды тур)'));
    });

    // ========================================================================
    // 20. ИНТЕРФЕЙС ЖӘНЕ СЕБЕПТІ КҮЙЛЕРДІҢ ЖАҢАРТЫЛУЫ (STATE UPDATE)
    // ========================================================================
    test('20. Серверлік әрекеттерден кейін интерфейс тыңдаушыларының (listeners) шақырылуы', () async {
      int notifyCount = 0;
      repo.addListener(() {
        notifyCount++;
      });

      // Жаңа тур қосу бірнеше рет күйді жаңартады (Loading -> Complete)
      const testPlace = TourPlace(
        id: 'tp_notify_test',
        name: 'Тыңдаушы сынағы',
        region: 'Астана',
        category: 'Эко-турлар',
        rating: 5.0,
        reviewsCount: 1,
        pricePerPerson: 12000,
        description: 'Тест',
        imageUrl: 'https://unsplash.com/test.jpg',
        highlights: ['Тест'],
        bestSeason: 'Жаз',
      );

      await repo.createTour(testPlace);
      expect(notifyCount, greaterThanOrEqualTo(2));
      expect(repo.tours.any((t) => t.id == 'tp_notify_test'), isTrue);
    });
  });
}

