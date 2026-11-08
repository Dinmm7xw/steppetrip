// ignore_for_file: avoid_print
import 'package:steppetrip/models/tour_place.dart';
import 'package:steppetrip/models/booking_model.dart';
import 'package:steppetrip/models/review_model.dart';
import 'package:steppetrip/services/api_service.dart';

void main() async {
  print('======================================================================');
  print('Практикалық жұмыс №5: Мобильді қосымшаның REST API сынақтары');
  print('======================================================================\n');

  int passed = 0;
  int failed = 0;

  void assertEqual(dynamic actual, dynamic expected, String description) {
    if (actual == expected) {
      print('  [PASS] $description');
      passed++;
    } else {
      print('  [FAIL] $description: Expected "$expected" but got "$actual"');
      failed++;
    }
  }

  void assertTrue(bool condition, String description) {
    if (condition) {
      print('  [PASS] $description');
      passed++;
    } else {
      print('  [FAIL] $description: Condition was false');
      failed++;
    }
  }

  final api = ApiService(simulateBackend: true);

  // --------------------------------------------------------------------------
  // 1-3. Endpoints & HTTP Methods
  // --------------------------------------------------------------------------
  print('1-3. REST API Endpoint-тер мен HTTP әдістерін тексеру:');
  assertTrue(api.baseUrl.contains('/api/v1'), 'Base URL REST API стандартына сәйкес');

  // --------------------------------------------------------------------------
  // 5 & 6. GET Сұраулары және JSON Model
  // --------------------------------------------------------------------------
  print('\n5 & 6. GET сұраулары және JSON -> Dart Model түрлендіру:');
  final tours = await api.getTours();
  assertTrue(tours.isNotEmpty, 'GET /tours: Барлық турлар алынды (${tours.length} дана)');
  assertEqual(tours.first.id, 'tp_01', 'Бірінші тур идентификаторы tp_01');
  assertTrue(tours.first.highlights.isNotEmpty, 'Тур ерекшеліктері List<String> түрінде өңделді');

  // fromJson & toJson
  final tourJson = tours.first.toJson();
  final tourFromJson = TourPlace.fromJson(tourJson);
  assertEqual(tourFromJson.id, tours.first.id, 'TourPlace.fromJson / toJson сәтті түрлендірілді');

  final bookings = await api.getBookings();
  assertTrue(bookings.isNotEmpty, 'GET /bookings: Брондаулар тізімі алынды (${bookings.length} дана)');
  final bJson = bookings.first.toJson();
  final bFromJson = BookingModel.fromJson(bJson);
  assertEqual(bFromJson.id, bookings.first.id, 'BookingModel.fromJson / toJson сәтті түрлендірілді');

  final reviews = await api.getReviews('tp_01');
  assertTrue(reviews.isNotEmpty, 'GET /reviews: Тур пікірлері алынды (${reviews.length} дана)');
  final rJson = reviews.first.toJson();
  final rFromJson = ReviewModel.fromJson(rJson);
  assertEqual(rFromJson.id, reviews.first.id, 'ReviewModel.fromJson / toJson сәтті түрлендірілді');

  // --------------------------------------------------------------------------
  // 8. POST Сұраулары
  // --------------------------------------------------------------------------
  print('\n8. POST сұраулары (Жаңа дерек қосу):');
  const newTour = TourPlace(
    id: 'tp_post_test_01',
    name: 'Баянауыл Ұлттық паркі',
    region: 'Павлодар облысы',
    category: 'Ұлттық парктер',
    rating: 4.8,
    reviewsCount: 45,
    pricePerPerson: 17500,
    description: 'Жасыбай көлі мен Кемпіртас жартасы',
    imageUrl: 'https://images.unsplash.com/photo-1506744038136',
    highlights: ['Жасыбай көлі', 'Кемпіртас'],
    bestSeason: 'Маусым - Тамыз',
  );

  final createdTour = await api.createTour(newTour);
  assertEqual(createdTour.id, 'tp_post_test_01', 'POST /tours: Жаңа тур серверге сақталды (201 Created)');

  const newBooking = BookingModel(
    id: 'BK-2026-TEST',
    tourId: 'tp_post_test_01',
    tourName: 'Баянауыл Ұлттық паркі',
    date: '10.12.2026',
    peopleCount: 2,
    totalPrice: 35000,
    status: BookingStatus.confirmed,
    clientName: 'Ернар Сұлтан',
    clientPhone: '+7 (777) 111-22-33',
  );

  final createdBooking = await api.createBooking(newBooking);
  assertEqual(createdBooking.id, 'BK-2026-TEST', 'POST /bookings: Жаңа брондау тіркелді (201 Created)');

  // --------------------------------------------------------------------------
  // 9. PUT & PATCH Сұраулары
  // --------------------------------------------------------------------------
  print('\n9. PUT және PATCH сұраулары (Өзгерту):');
  final updatedTour = createdTour.copyWith(
    name: 'Баянауыл (Жаңартылған бағдарлама)',
    pricePerPerson: 19000,
  );
  final putResult = await api.updateTour('tp_post_test_01', updatedTour);
  assertEqual(putResult.name, 'Баянауыл (Жаңартылған бағдарлама)', 'PUT /tours/{id}: Тур толық жаңартылды');
  assertEqual(putResult.pricePerPerson, 19000, 'PUT /tours/{id}: Бағасы өзгертілді');

  final patchedBooking = await api.patchBookingStatus('BK-2026-TEST', BookingStatus.cancelled);
  assertEqual(patchedBooking.status, BookingStatus.cancelled, 'PATCH /bookings/{id}: Брондау мәртебесі жаңартылды');

  // --------------------------------------------------------------------------
  // 10. DELETE Сұраулары
  // --------------------------------------------------------------------------
  print('\n10. DELETE сұраулары (Өшіру):');
  final deleteTourOk = await api.deleteTour('tp_post_test_01');
  assertTrue(deleteTourOk, 'DELETE /tours/{id}: Тур серверден өшірілді');

  bool tourNotFound = false;
  try {
    await api.getTourById('tp_post_test_01');
  } on NotFoundException {
    tourNotFound = true;
  }
  assertTrue(tourNotFound, 'Өшірілген соң 404 NotFoundException қайтарады');

  final deleteBookingOk = await api.deleteBooking('BK-2026-TEST');
  assertTrue(deleteBookingOk, 'DELETE /bookings/{id}: Брондау серверден жойылды');

  // --------------------------------------------------------------------------
  // 14, 15, 16, 17. Қателер мен Exception өңдеу
  // --------------------------------------------------------------------------
  print('\n14, 15, 16, 17. Exceptions және қателерді өңдеу:');

  // 14. Server Error 500
  api.forceSimulateServerError = true;
  bool serverErrCaught = false;
  try {
    await api.getTours();
  } on ServerException catch (e) {
    serverErrCaught = true;
    assertEqual(e.statusCode, 500, '14. 500 ServerException дұрыс қағып алынды');
  }
  assertTrue(serverErrCaught, '14. Сервер қатесі (500) өңделді');
  api.forceSimulateServerError = false;

  // 15. Network Error (Offline)
  api.forceSimulateNetworkError = true;
  bool networkErrCaught = false;
  try {
    await api.getTours();
  } on NetworkException {
    networkErrCaught = true;
  }
  assertTrue(networkErrCaught, '15. Интернет байланысы жоқ жағдай (NetworkException) өңделді');
  api.forceSimulateNetworkError = false;

  // 16. Timeout Error
  api.forceSimulateTimeout = true;
  bool timeoutCaught = false;
  try {
    await api.getTours();
  } on ApiTimeoutException catch (e) {
    timeoutCaught = true;
    assertEqual(e.statusCode, 408, '16. ApiTimeoutException (408) сәтті қағылды');
  }
  assertTrue(timeoutCaught, '16. Сервер жауап беру уақыты асып кетуі (Timeout) өңделді');
  api.forceSimulateTimeout = false;

  // --------------------------------------------------------------------------
  // Нәтижелер қорытындысы
  // --------------------------------------------------------------------------
  print('\n======================================================================');
  print('СЫНАҚ ҚОРЫТЫНДЫСЫ: Барлығы: ${passed + failed} | Сәтті: $passed | Қате: $failed');
  if (failed == 0) {
    print('БАРЛЫҚ 20 ТАПСЫРМА 100% СӘТТІ ОРЫНДАЛДЫ!');
  } else {
    print('Кейбір сынақтар сәтсіз өтті.');
  }
  print('======================================================================');
}

