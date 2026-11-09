-- ============================================================================
-- SteppeTrip: Supabase PostgreSQL Деректер қорының толық схемасы
-- Орындау орны: Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ============================================================================

-- 1. Пайдаланушылар мен Гидтер кестесі (users)
CREATE TABLE IF NOT EXISTS public.users (
  id TEXT PRIMARY KEY,
  "fullName" TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL,
  "avatarUrl" TEXT NOT NULL DEFAULT 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
  "preferredLanguage" TEXT NOT NULL DEFAULT 'Қазақша',
  "completedTours" INTEGER NOT NULL DEFAULT 0,
  role TEXT NOT NULL DEFAULT 'tourist',
  "isApproved" INTEGER NOT NULL DEFAULT 1,
  password TEXT NOT NULL DEFAULT '123456',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Турлар каталогы кестесі (tours)
CREATE TABLE IF NOT EXISTS public.tours (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  region TEXT NOT NULL,
  category TEXT NOT NULL,
  rating DOUBLE PRECISION NOT NULL DEFAULT 5.0,
  "reviewsCount" INTEGER NOT NULL DEFAULT 1,
  "pricePerPerson" INTEGER NOT NULL,
  description TEXT NOT NULL,
  "imageUrl" TEXT NOT NULL,
  highlights TEXT NOT NULL,
  "bestSeason" TEXT NOT NULL DEFAULT 'Мамыр - Қазан',
  "isFavorite" INTEGER NOT NULL DEFAULT 0
);

-- 3. Брондаулар және QR билеттер кестесі (bookings)
CREATE TABLE IF NOT EXISTS public.bookings (
  id TEXT PRIMARY KEY,
  "tourId" TEXT NOT NULL,
  "tourName" TEXT NOT NULL,
  date TEXT NOT NULL,
  "peopleCount" INTEGER NOT NULL DEFAULT 1,
  "totalPrice" INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'confirmed',
  "clientName" TEXT NOT NULL,
  "clientPhone" TEXT NOT NULL,
  notes TEXT DEFAULT ''
);

-- 4. Пікірлер кестесі (reviews)
CREATE TABLE IF NOT EXISTS public.reviews (
  id TEXT PRIMARY KEY,
  "tourId" TEXT NOT NULL,
  "userName" TEXT NOT NULL,
  rating INTEGER NOT NULL DEFAULT 5,
  comment TEXT NOT NULL,
  date TEXT NOT NULL,
  tags TEXT NOT NULL DEFAULT '',
  "userAvatar" TEXT DEFAULT ''
);

-- RLS (Row Level Security) және Data API рұқсаттарын беру (anon / authenticated үшін)
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.users TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.tours TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.bookings TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.reviews TO anon, authenticated, service_role;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all on users" ON public.users;
CREATE POLICY "Allow all on users" ON public.users FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on tours" ON public.tours;
CREATE POLICY "Allow all on tours" ON public.tours FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on bookings" ON public.bookings;
CREATE POLICY "Allow all on bookings" ON public.bookings FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on reviews" ON public.reviews;
CREATE POLICY "Allow all on reviews" ON public.reviews FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================================
-- Бастапқы деректерді толтыру (Дінмұхаммед Админ + Турлар + Билеттер)
-- ============================================================================

INSERT INTO public.users (id, "fullName", email, phone, "avatarUrl", "preferredLanguage", "completedTours", role, "isApproved", password)
VALUES (
  'usr_admin_01',
  'Дінмұхаммед Бақытұлы',
  'dinmuhammed@steppetrip.kz',
  '+7 (708) 555-44-33',
  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
  'Қазақша',
  25,
  'admin',
  1,
  '123456'
) ON CONFLICT (id) DO UPDATE SET role = 'admin', "isApproved" = 1;

INSERT INTO public.tours (id, name, region, category, rating, "reviewsCount", "pricePerPerson", description, "imageUrl", highlights, "bestSeason", "isFavorite")
VALUES
  ('tp_01', 'Көлсай және Қайыңды көлдері', 'Алматы облысы', 'Көлдер мен таулар', 4.9, 328, 25000, 'Солтүстік Тянь-Шань інжу-маржаны саналатын Көлсай мен су астындағы шыршаларымен танымал Қайыңды көліне 2 күндік ұмытылмас саяхат.', 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1000&q=80', 'Атпен серуендеу|Қайықпен жүзу|Киіз үйде қону|Кәсіби фотосессия', 'Мамыр - Қазан', 1),
  ('tp_02', 'Шарын каньоны: Қамалдар аңғары', 'Алматы облысы', 'Каньондар', 4.8, 245, 15000, 'Миллиондаған жылдар бойы қалыптасқан қызыл жартасты Шарын шатқалы.', 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=1000&q=80', 'Қамалдар аңғары|Шарын өзені|Панорамалық алаң|Гид экскурсиясы', 'Сәуір - Қараша', 0),
  ('tp_03', 'Бурабай ұлттық паркі', 'Ақмола облысы', 'Ұлттық парктер', 4.9, 412, 32000, 'Қазақстанның Швейцариясы атанған Бурабай өлкесі, Жұмбақтас пен Оқжетпес шыңы.', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=1000&q=80', 'Жұмбақтас жартасы|Оқжетпес шыңы|Абылай хан алаңы|Қарағайлы орман', 'Жыл бойы', 1),
  ('tp_04', 'Түркістан: Қожа Ахмет Ясауи кесенесі', 'Түркістан облысы', 'Тарихи орындар', 5.0, 520, 28000, 'Түркі әлемінің рухани астанасы Түркістанға және ЮНЕСКО мұрасы Ясауи кесенесіне тарихи тур.', 'https://images.unsplash.com/photo-1548013146-72479768bada?auto=format&fit=crop&w=1000&q=80', 'Ясауи кесенесі|Керуен Сарай|Арыстан баб|Ұлттық тағамдар', 'Жыл бойы', 0),
  ('tp_05', 'Маңғыстау: Бозжыра шатқалы', 'Маңғыстау облысы', 'Каньондар', 4.9, 189, 65000, 'Ежелгі Тетис мұхитының табаны болған Бозжыра борлы жартастарына джип-тур.', 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=1000&q=80', 'Джип-сафари|Жұлдызды аспан астында кемпинг|Бозжыра тістері|Тұзбайыр соры', 'Сәуір - Қазан', 1),
  ('tp_06', 'Катонқарағай және Рахман қайнары', 'Шығыс Қазақстан облысы', 'Эко-турлар', 4.8, 156, 85000, 'Алтай тауларының ең биік нүктесі Мұзтау мен шипалы Рахман бұлақтарына эко-саяхат.', 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1000&q=80', 'Мұзтау көрінісі|Марал шаруашылығы|Таулы өзендер|Алтай балы', 'Маусым - Қыркүйек', 0)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.bookings (id, "tourId", "tourName", date, "peopleCount", "totalPrice", status, "clientName", "clientPhone", notes)
VALUES
  ('BK-2026-001', 'tp_01', 'Көлсай және Қайыңды көлдері', '15 Маусым 2026', 2, 50000, 'confirmed', 'Дінмұхаммед Бақытұлы', '+7 (708) 555-44-33', 'Алдыңғы қатардан орын'),
  ('BK-2026-002', 'tp_04', 'Түркістан: Қожа Ахмет Ясауи кесенесі', '22 Шілде 2026', 4, 112000, 'pending', 'Дінмұхаммед Бақытұлы', '+7 (708) 555-44-33', 'Отбасылық саяхат'),
  ('BK-01', 'tp_01', 'Көлсай және Қайыңды көлдері', '15.11.2026', 2, 45000, 'confirmed', 'Дінмұхаммед Бақытұлы', '+7 (708) 555-44-33', 'Тур билеті сәтті расталған')
ON CONFLICT (id) DO NOTHING;

