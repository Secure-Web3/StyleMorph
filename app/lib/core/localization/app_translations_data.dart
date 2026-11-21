/// Canonical multi-language lookup table (`en`, `ar`, `tr`) for domain entities,
/// mock catalog items, dropdown values, and dynamic labels whose canonical ID is Persian.
const Map<String, Map<String, String>> kDomainTranslations = {
  // ── User / Plan / Shell ─────────────────────────────────────────────────
  'سارا احمدی': {'en': 'Sara Ahmadi', 'ar': 'سارة أحمدي', 'tr': 'Sara Ahmadi'},
  'عادی (رایگان)': {
    'en': 'Basic (Free)',
    'ar': 'عادي (مجاني)',
    'tr': 'Temel (Ücretsiz)',
  },
  'پلن Plus': {'en': 'Plus Plan', 'ar': 'خطة Plus', 'tr': 'Plus Planı'},
  'پلن Pro': {'en': 'Pro Plan', 'ar': 'خطة Pro', 'tr': 'Pro Planı'},
  'پلن Ultra': {'en': 'Ultra Plan', 'ar': 'خطة Ultra', 'tr': 'Ultra Planı'},
  'سلام! چطور می‌تونم کمکتون کنم؟': {
    'en': 'Hello! How can I help you?',
    'ar': 'مرحباً! كيف يمكنني مساعدتك؟',
    'tr': 'Merhaba! Size nasıl yardımcı olabilirim?',
  },

  // ── Notifications ───────────────────────────────────────────────────────
  'تصویر پرتره ادیتوریال شما در آتلیه آماده شد!': {
    'en': 'Your editorial portrait in Atelier is ready!',
    'ar': 'صورتك التحريرية في الاستوديو جاهزة الآن!',
    'tr': 'Stüdyodaki editoryal portreniz hazır!',
  },
  'برای مشاهده، دانلود و اشتراک‌گذاری به بخش ساخته‌های من بروید.': {
    'en': 'Go to My Creations to view, download, and share.',
    'ar': 'انتقل إلى إبداعاتي للمشاهدة والتحميل والمشاركة.',
    'tr': 'Görüntülemek, indirmek ve paylaşmak için Tasarımlarım’a gidin.',
  },
  '۵ دقیقه پیش': {'en': '5 min ago', 'ar': 'منذ ٥ دقائق', 'tr': '5 dk önce'},
  'کت کتان بژ در لیست علاقه‌مندی‌های شما ۲۰٪ تخفیف خورد!': {
    'en': 'Beige linen coat in your wishlist is 20% off!',
    'ar': 'معطف الكتان البيج في قائمة رغباتك عليه خصم ٢٠٪!',
    'tr': 'Favorilerinizdeki bej keten ceket %20 indirimde!',
  },
  'فرصت محدود فروشنده تاییدشده با گارانتی تطابق سایز.': {
    'en': 'Limited offer from verified seller with size-fit guarantee.',
    'ar': 'عرض محدود من بائع موثق مع ضمان تطابق المقاس.',
    'tr': 'Onaylı satıcıdan beden uyum garantili sınırlı fırsat.',
  },
  '۲۲ دقیقه پیش': {
    'en': '22 min ago',
    'ar': 'منذ ٢٢ دقيقة',
    'tr': '22 dk önce',
  },
  'مریم کاظمی با لینک دعوت شما ثبت‌نام کرد و ۱۰۰ سکه به کیف پولتان اضافه شد.': {
    'en': 'Maryam Kazemi joined via your link and 100 coins were credited!',
    'ar': 'سجّلت مريم كاظمي عبر رابط دعوتك وتمت إضافة ١٠٠ عملة لمحفظتك.',
    'tr': 'Meryem Kazemi davet linkinizle katıldı ve 100 jeton eklendi!',
  },
  'پاداش سطح طلایی به حساب StyleCoin شما واریز شد.': {
    'en': 'Gold tier reward credited to your StyleCoin balance.',
    'ar': 'تم إيداع مكافأة المستوى الذهبي في رصيد StyleCoin.',
    'tr': 'Altın seviye ödülü StyleCoin hesabınıza yatırıldı.',
  },
  '۱ ساعت پیش': {
    'en': '1 hour ago',
    'ar': 'منذ ساعة واحدة',
    'tr': '1 saat önce',
  },
  'هوای امروز ۱۸ درجه و آفتابی است؛ رامین یک ست جدید از کمدتان آماده کرده!': {
    'en':
        'Today is 18°C & sunny; Ramin prepared a new outfit from your wardrobe!',
    'ar': 'الطقس اليوم ١٨ درجة ومشمس؛ رامين جهّز لك إطلالة جديدة من خزانتك!',
    'tr':
        'Bugün hava 18°C ve güneşli; Ramin gardırobunuzdan yeni bir kombin hazırladı!',
  },
  'ست پیشنهادی بر اساس برنامه روزمره و پالت رنگی شما چیده شده است.': {
    'en':
        'Recommended outfit curated for your daily schedule and color palette.',
    'ar': 'تم تنسيق الإطلالة بناءً على جدولك اليومي ولوحة ألوانك.',
    'tr':
        'Günlük programınız ve renk paletinize göre önerilen kombin hazırlandı.',
  },
  '۲ ساعت پیش': {'en': '2 hours ago', 'ar': 'منذ ساعتين', 'tr': '2 saat önce'},

  // ── Identity / AI DNA / Persona / Wallet / Referral Values ─────────────
  'سارا': {'en': 'Sara', 'ar': 'سارة', 'tr': 'Sara'},
  'احمدی': {'en': 'Ahmadi', 'ar': 'أحمدي', 'tr': 'Ahmadi'},
  'ایران': {'en': 'Iran', 'ar': 'إيران', 'tr': 'İran'},
  'تهران': {'en': 'Tehran', 'ar': 'طهران', 'tr': 'Tahran'},
  'خیابان ولیعصر، بالاتر از ونک، پلاک ۲۴': {
    'en': 'Valiasr St, above Vanak Sq, No. 24',
    'ar': 'شارع وليعصر، أعلى ساحة ونك، رقم ٢٤',
    'tr': 'Valiasr Cad., Vanak Meydanı yukarısı, No: 24',
  },
  'گندمی روشن': {'en': 'Light Wheat', 'ar': 'حنطي فاتح', 'tr': 'Açık Buğday'},
  'ساعت شنی': {'en': 'Hourglass', 'ar': 'الساعة الرملية', 'tr': 'Kum Saati'},
  'بیضی': {'en': 'Oval', 'ar': 'بيضاوي', 'tr': 'Oval'},
  'قهوه‌ای تیره - متوسط': {
    'en': 'Dark Brown - Medium',
    'ar': 'بني داكن - متوسط',
    'tr': 'Koyu Kahve - Orta',
  },
  'رامین': {'en': 'Ramin', 'ar': 'رامين', 'tr': 'Ramin'},
  'استایلیست ارشد': {
    'en': 'Senior Stylist',
    'ar': 'منسق أزياء أول',
    'tr': 'Kıdemli Stilist',
  },
  'خوش‌سلیقه، رک و سریع': {
    'en': 'Stylish, direct & fast',
    'ar': 'أنيق وصريح وسريع',
    'tr': 'Zevkli, açık sözlü ve hızlı',
  },
  'مرد — گرم و دوستانه': {
    'en': 'Male — Warm & friendly',
    'ar': 'رجل — دافئ وودود',
    'tr': 'Erkek — Sıcak ve samimi',
  },
  'لنا': {'en': 'Lena', 'ar': 'لينا', 'tr': 'Lena'},
  'مشاور زیبایی و مد': {
    'en': 'Beauty & Fashion Advisor',
    'ar': 'مستشارة الجمال والموضة',
    'tr': 'Güzellik ve Moda Danışmanı',
  },
  'خلاق، لطیف و به‌روز': {
    'en': 'Creative, gentle & trendy',
    'ar': 'مبدعة ولطيفة وعصرية',
    'tr': 'Yaratıcı, zarif ve güncel',
  },
  'زن — گرم و مهربان': {
    'en': 'Female — Warm & kind',
    'ar': 'امرأة — دافئة ولطيفة',
    'tr': 'Kadın — Sıcak ve nazik',
  },
  'آرش': {'en': 'Arash', 'ar': 'آرش', 'tr': 'Arash'},
  'مربی تندرستی': {
    'en': 'Wellness Coach',
    'ar': 'مدرب العافية',
    'tr': 'Sağlık Koçu',
  },
  'پرانرژی، دقیق و انگیزه‌بخش': {
    'en': 'Energetic, precise & motivating',
    'ar': 'نشيط ودقيق ومحفز',
    'tr': 'Enerjik, disiplinli ve motive edici',
  },
  'مرد — جوان و پرانرژی': {
    'en': 'Male — Young & energetic',
    'ar': 'رجل — شاب ونشيط',
    'tr': 'Erkek — Genç ve enerjik',
  },
  'مشاور شخصی': {
    'en': 'Personal Advisor',
    'ar': 'مستشارة شخصية',
    'tr': 'Kişisel Danışman',
  },
  'همدل، صبور و خوش‌برخورد': {
    'en': 'Empathetic, patient & warm',
    'ar': 'متعاطفة وصبورة ولطيفة',
    'tr': 'Empatik, sabırlı ve güler yüzlü',
  },
  'زن — آرام و دلگرم‌کننده': {
    'en': 'Female — Calm & reassuring',
    'ar': 'امرأة — هادئة ومشجعة',
    'tr': 'Kadın — Sakin ve güven verici',
  },
  'فرزانه': {'en': 'Farzaneh', 'ar': 'فرزانة', 'tr': 'Farzaneh'},
  'راهنمای آرامش': {
    'en': 'Mindfulness Guide',
    'ar': 'مرشدة الهدوء',
    'tr': 'Huzur Rehberi',
  },
  'آرام، دقیق و باحوصله': {
    'en': 'Calm, thoughtful & patient',
    'ar': 'هادئة ودقيقة وصبورة',
    'tr': 'Sakin, dikkatli ve sabırlı',
  },
  'زن — آرام و شمرده': {
    'en': 'Female — Calm & articulate',
    'ar': 'امرأة — هادئة وواضحة',
    'tr': 'Kadın — Sakin ve akıcı',
  },
  'نیلو': {'en': 'Nilo', 'ar': 'نيلو', 'tr': 'Nilo'},
  'فشنیستا': {'en': 'Fashionista', 'ar': 'عاشقة الموضة', 'tr': 'Moda İkonu'},
  'شیک، مدرن و بااعتمادبه‌نفس': {
    'en': 'Chic, modern & confident',
    'ar': 'أنيقة وعصرية وواثقة',
    'tr': 'Şık, modern ve özgüvenli',
  },
  'زن — جوان و شاد': {
    'en': 'Female — Young & cheerful',
    'ar': 'امرأة — شابة ومبتهجة',
    'tr': 'Kadın — Genç ve neşeli',
  },
  'صمیمی و دوستانه': {
    'en': 'Friendly & Casual',
    'ar': 'ودي وعفوي',
    'tr': 'Samimi ve Dostça',
  },
  'رسمی و تخصصی': {
    'en': 'Formal & Professional',
    'ar': 'رسمي ومهني',
    'tr': 'Resmi ve Uzman',
  },
  'منتقد صریح و رک': {
    'en': 'Direct & Candid Critic',
    'ar': 'ناقد صريح ومباشر',
    'tr': 'Açık Sözlü Eleştirmen',
  },
  'الهام‌بخش و انگیزشی': {
    'en': 'Inspiring & Motivating',
    'ar': 'ملهم ومحفز',
    'tr': 'İlham Verici',
  },
  'ملایم و انعطاف‌پذیر': {
    'en': 'Gentle & Flexible',
    'ar': 'لطيف ومرن',
    'tr': 'Yumuşak ve Esnek',
  },
  'متعادل و استاندارد': {
    'en': 'Balanced & Standard',
    'ar': 'متوازن وقياسي',
    'tr': 'Dengeli ve Standart',
  },
  'سخت‌گیر و تخصصی': {
    'en': 'Strict & Expert',
    'ar': 'صارم ومتخصص',
    'tr': 'Katı ve Profesyonel',
  },
  'کوتاه': {'en': 'Short', 'ar': 'قصير', 'tr': 'Kısa'},
  'متوسط': {'en': 'Medium', 'ar': 'متوسط', 'tr': 'Orta'},
  'مفصل': {'en': 'Detailed', 'ar': 'مفصل', 'tr': 'Detaylı'},
  'همه بخش‌ها': {
    'en': 'All Sections',
    'ar': 'جميع الأقسام',
    'tr': 'Tüm Bölümler',
  },
  'فقط تندرستی و استایلیست': {
    'en': 'Wellness & Stylist Only',
    'ar': 'العافية والمنسق فقط',
    'tr': 'Sadece Sağlık ve Stilist',
  },
  'خاموش': {'en': 'Off', 'ar': 'إيقاف', 'tr': 'Kapalı'},
  'مریم کاظمی': {
    'en': 'Maryam Kazemi',
    'ar': 'مريم كاظمي',
    'tr': 'Meryem Kazemi',
  },
  'علی رضاپور': {
    'en': 'Ali Rezapour',
    'ar': 'علي رضابور',
    'tr': 'Ali Rezapour',
  },
  'طلایی': {'en': 'Gold', 'ar': 'ذهبي', 'tr': 'Altın'},

  // ── Colors / Seasons / Occasions / Sizes / Materials ────────────────────
  'همه': {'en': 'All', 'ar': 'الكل', 'tr': 'Tümü'},
  'بهار': {'en': 'Spring', 'ar': 'الربيع', 'tr': 'İlkbahar'},
  'تابستان': {'en': 'Summer', 'ar': 'الصيف', 'tr': 'Yaz'},
  'پاییز': {'en': 'Fall', 'ar': 'الخريف', 'tr': 'Sonbahar'},
  'زمستان': {'en': 'Winter', 'ar': 'الشتاء', 'tr': 'Kış'},
  'همه فصل': {'en': 'All Seasons', 'ar': 'كل الفصول', 'tr': 'Dört Mevsim'},
  'بهار و تابستان': {
    'en': 'Spring & Summer',
    'ar': 'الربيع والصيف',
    'tr': 'İlkbahar & Yaz',
  },
  'پاییز و زمستان': {
    'en': 'Fall & Winter',
    'ar': 'الخريف والشتاء',
    'tr': 'Sonbahar & Kış',
  },
  'بهار و پاییز': {
    'en': 'Spring & Fall',
    'ar': 'الربيع والخريف',
    'tr': 'İlkbahar & Sonbahar',
  },
  'روزمره': {'en': 'Casual', 'ar': 'يومي', 'tr': 'Günlük'},
  'رسمی': {'en': 'Formal', 'ar': 'رسمي', 'tr': 'Resmi'},
  'ورزشی': {'en': 'Sport', 'ar': 'رياضي', 'tr': 'Spor'},
  'مجلسی': {'en': 'Evening', 'ar': 'سهرات', 'tr': 'Davet'},
  'کار': {'en': 'Work', 'ar': 'العمل', 'tr': 'İş'},
  'مهمانی': {'en': 'Party', 'ar': 'حفلة', 'tr': 'Parti'},
  'سفر': {'en': 'Travel', 'ar': 'سفر', 'tr': 'Seyahat'},
  'سیاه': {'en': 'Black', 'ar': 'أسود', 'tr': 'Siyah'},
  'مشکی': {'en': 'Black', 'ar': 'أسود', 'tr': 'Siyah'},
  'سفید': {'en': 'White', 'ar': 'أبيض', 'tr': 'Beyaz'},
  'بژ': {'en': 'Beige', 'ar': 'بيج', 'tr': 'Bej'},
  'قهوه‌ای': {'en': 'Brown', 'ar': 'بني', 'tr': 'Kahverengi'},
  'آبی': {'en': 'Blue', 'ar': 'أزرق', 'tr': 'Mavi'},
  'سرمه‌ای': {'en': 'Navy', 'ar': 'كحلي', 'tr': 'Lacivert'},
  'قرمز': {'en': 'Red', 'ar': 'أحمر', 'tr': 'Kırmızı'},
  'سبز': {'en': 'Green', 'ar': 'أخضر', 'tr': 'Yeşil'},
  'صورتی': {'en': 'Pink', 'ar': 'وردي', 'tr': 'Pembe'},
  'نقره‌ای': {'en': 'Silver', 'ar': 'فضي', 'tr': 'Gümüş'},
  'طوسی': {'en': 'Gray', 'ar': 'رمادي', 'tr': 'Gri'},
  'یونیورسال': {'en': 'One Size', 'ar': 'مقاس موحد', 'tr': 'Standart'},
  'بالاتنه': {'en': 'Top', 'ar': 'قطعة علوية', 'tr': 'Üst Giyim'},
  'پایین‌تنه': {'en': 'Bottom', 'ar': 'قطعة سفلية', 'tr': 'Alt Giyim'},
  'رویه‌پوش': {'en': 'Outerwear', 'ar': 'معطف', 'tr': 'Dış Giyim'},
  'لباس یکسره': {'en': 'One-Piece', 'ar': 'فستان كامل', 'tr': 'Tek Parça'},
  'یکسره': {'en': 'One-Piece', 'ar': 'قطعة واحدة', 'tr': 'Tek Parça'},
  'اسپورت': {'en': 'Sneakers', 'ar': 'رياضي', 'tr': 'Spor'},
  'پاشنه‌دار': {'en': 'Heels', 'ar': 'كعب عالٍ', 'tr': 'Topuklu'},
  'بوت': {'en': 'Boots', 'ar': 'بوت', 'tr': 'Bot'},
  'دستی': {'en': 'Handbag', 'ar': 'حقيبة يد', 'tr': 'El Çantası'},
  'کوله': {'en': 'Backpack', 'ar': 'حقيبة ظهر', 'tr': 'Sırt Çantası'},
  'دوشی': {'en': 'Shoulder Bag', 'ar': 'حقيبة كتف', 'tr': 'Omuz Çantası'},
  'کلاچ': {'en': 'Clutch', 'ar': 'كلاتش', 'tr': 'Portföy'},
  'گردنبند': {'en': 'Necklace', 'ar': 'عقد', 'tr': 'Kolye'},
  'گوشواره': {'en': 'Earrings', 'ar': 'أقراط', 'tr': 'Küpe'},
  'انگشتر': {'en': 'Ring', 'ar': 'خاتم', 'tr': 'Yüzük'},
  'دستبند': {'en': 'Bracelet', 'ar': 'سوار', 'tr': 'Bilezik'},
  'ساعت': {'en': 'Watch', 'ar': 'ساعة', 'tr': 'Saat'},
  'عینک': {'en': 'Eyewear', 'ar': 'نظارة', 'tr': 'Gözlük'},
  'شال': {'en': 'Scarf', 'ar': 'وشاح', 'tr': 'Şal'},
  'کمربند': {'en': 'Belt', 'ar': 'حزام', 'tr': 'Kemer'},
  'پنبه': {'en': 'Cotton', 'ar': 'قطن', 'tr': 'Pamuk'},
  'نخ / پنبه': {'en': 'Cotton', 'ar': 'قطن', 'tr': 'Pamuk'},
  'جین': {'en': 'Denim', 'ar': 'دنيم', 'tr': 'Kot / Denim'},
  'پشم': {'en': 'Wool', 'ar': 'صوف', 'tr': 'Yün'},
  'ساتن': {'en': 'Satin', 'ar': 'ساتان', 'tr': 'Saten'},
  'پنبه/پلی‌استر': {
    'en': 'Cotton / Polyester',
    'ar': 'قطن / بوليستر',
    'tr': 'Pamuk / Polyester',
  },
  'ویسکوز': {'en': 'Viscose', 'ar': 'فيسكوز', 'tr': 'Viskon'},
  'چرم مصنوعی': {'en': 'Faux Leather', 'ar': 'جلد صناعي', 'tr': 'Suni Deri'},
  'چرم': {'en': 'Leather', 'ar': 'جلد', 'tr': 'Deri'},
  'نایلون': {'en': 'Nylon', 'ar': 'نايلون', 'tr': 'Naylon'},
  'چرم لاکی': {'en': 'Patent Leather', 'ar': 'جلد لامع', 'tr': 'Rugan Deri'},
  'طلا': {'en': 'Gold', 'ar': 'ذهب', 'tr': 'Altın'},
  'نقره': {'en': 'Silver', 'ar': 'فضة', 'tr': 'Gümüş'},
  'پلاستیک': {'en': 'Acetate / Plastic', 'ar': 'بلاستيك', 'tr': 'Plastik'},

  // ── Wardrobe Item Names ─────────────────────────────────────────────────
  'پیراهن آبی کلاسیک': {
    'en': 'Classic Blue Shirt',
    'ar': 'قميص أزرق كلاسيكي',
    'tr': 'Klasik Mavi Gömlek',
  },
  'شلوار جین سرمه‌ای': {
    'en': 'Navy Denim Jeans',
    'ar': 'جينز كحلي',
    'tr': 'Lacivert Kot Pantolon',
  },
  'پالتو مشکی': {
    'en': 'Black Wool Coat',
    'ar': 'معطف أسود',
    'tr': 'Siyah Kaban',
  },
  'لباس مجلسی قرمز': {
    'en': 'Red Evening Dress',
    'ar': 'فستان سهرة أحمر',
    'tr': 'Kırmızı Abiye Elbise',
  },
  'هودی طوسی': {'en': 'Gray Hoodie', 'ar': 'هودي رمادي', 'tr': 'Gri Kapüşonlu'},
  'مانتو بژ': {
    'en': 'Beige Trench Coat',
    'ar': 'معطف بيج',
    'tr': 'Bej Trençkot',
  },
  'کتانی سفید': {
    'en': 'White Sneakers',
    'ar': 'حذاء رياضي أبيض',
    'tr': 'Beyaz Spor Ayakkabı',
  },
  'کفش پاشنه‌دار مشکی': {
    'en': 'Black Heeled Shoes',
    'ar': 'حذاء كعب أسود',
    'tr': 'Siyah Topuklu Ayakkabı',
  },
  'بوت قهوه‌ای': {
    'en': 'Brown Leather Boots',
    'ar': 'بوت بني',
    'tr': 'Kahverengi Bot',
  },
  'کفش رسمی طوسی': {
    'en': 'Gray Formal Shoes',
    'ar': 'حذاء رسمي رمادي',
    'tr': 'Gri Klasik Ayakkabı',
  },
  'کیف دستی بژ': {
    'en': 'Beige Handbag',
    'ar': 'حقيبة يد بيج',
    'tr': 'Bej El Çantası',
  },
  'کوله‌پشتی سیاه': {
    'en': 'Black Backpack',
    'ar': 'حقيبة ظهر سوداء',
    'tr': 'Siyah Sırt Çantası',
  },
  'کیف دوشی قرمز': {
    'en': 'Red Shoulder Bag',
    'ar': 'حقيبة كتف حمراء',
    'tr': 'Kırmızı Omuz Çantası',
  },
  'کیف مجلسی نقره‌ای': {
    'en': 'Silver Evening Clutch',
    'ar': 'حقيبة سهرة فضية',
    'tr': 'Gümüş Abiye Çanta',
  },
  'گردنبند طلایی': {
    'en': 'Gold Necklace',
    'ar': 'عقد ذهبي',
    'tr': 'Altın Kolye',
  },
  'گوشواره نقره‌ای': {
    'en': 'Silver Earrings',
    'ar': 'أقراط فضية',
    'tr': 'Gümüş Küpe',
  },
  'انگشتر نقره‌ای': {
    'en': 'Silver Ring',
    'ar': 'خاتم فضي',
    'tr': 'Gümüş Yüzük',
  },
  'دستبند طلایی': {
    'en': 'Gold Bracelet',
    'ar': 'سوار ذهبي',
    'tr': 'Altın Bilezik',
  },
  'ساعت چرمی': {
    'en': 'Leather Watch',
    'ar': 'ساعة جلدية',
    'tr': 'Deri Kayışlı Saat',
  },
  'عینک آفتابی': {
    'en': 'Sunglasses',
    'ar': 'نظارة شمسية',
    'tr': 'Güneş Gözlüğü',
  },
  'شال سبز': {'en': 'Green Wool Scarf', 'ar': 'وشاح أخضر', 'tr': 'Yeşil Şal'},
  'کمربند چرمی': {'en': 'Leather Belt', 'ar': 'حزام جلدي', 'tr': 'Deri Kemer'},

  // ── Shop Catalog ────────────────────────────────────────────────────────
  'پیراهن کتان آستین‌بلند': {
    'en': 'Long-Sleeve Linen Shirt',
    'ar': 'قميص كتان بأكمام طويلة',
    'tr': 'Uzun Kollu Keten Gömlek',
  },
  'کفش ورزشی ایر': {
    'en': 'Air Running Sneakers',
    'ar': 'حذاء إير الرياضي',
    'tr': 'Air Koşu Ayakkabısı',
  },
  'کاپشن زمستانه گوگلی': {
    'en': 'Winter Puffer Jacket',
    'ar': 'سترة شتوية منفوخة',
    'tr': 'Kışlık Şişme Mont',
  },
  'کیف دوشی چرم': {
    'en': 'Leather Shoulder Bag',
    'ar': 'حقيبة كتف جلدية',
    'tr': 'Deri Omuz Çantası',
  },
  'کوله‌پشتی روزمره': {
    'en': 'Everyday Backpack',
    'ar': 'حقيبة ظهر يومية',
    'tr': 'Günlük Sırt Çantası',
  },
  'ساعت مچی کلاسیک': {
    'en': 'Classic Wristwatch',
    'ar': 'ساعة يد كلاسيكية',
    'tr': 'Klasik Kol Saati',
  },
  'گردنبند آبکاری طلا': {
    'en': 'Gold-Plated Necklace',
    'ar': 'عقد مطلي بالذهب',
    'tr': 'Altın Kaplama Kolye',
  },
  'شال نخی ساده': {
    'en': 'Plain Cotton Scarf',
    'ar': 'وشاح قطني سادة',
    'tr': 'Düz Pamuklu Şal',
  },
  'شلوار جین راسته': {
    'en': 'Straight-Leg Denim Jeans',
    'ar': 'بنطال جينز بقصة مستقيمة',
    'tr': 'Düz Kesim Kot Pantolon',
  },
  'کفش پاشنه‌دار مجلسی': {
    'en': 'Evening High Heels',
    'ar': 'حذاء سهرة بكعب عالٍ',
    'tr': 'Abiye Topuklu Ayakkabı',
  },
  'رژلب مات ماندگار': {
    'en': 'Long-Wear Matte Lipstick',
    'ar': 'أحمر شفاه مطفي ثابت',
    'tr': 'Kalıcı Mat Ruj',
  },
  'پالت سایه ۱۲ رنگ': {
    'en': '12-Shade Eyeshadow Palette',
    'ar': 'باليت ظلال عيون ١٢ لون',
    'tr': '12 Renkli Far Paleti',
  },
  'کت اسپرت مردانه': {
    'en': "Men's Casual Blazer",
    'ar': 'بليزر رجالي أنيق',
    'tr': 'Erkek Spor Ceket',
  },
  'عینک آفتابی خلبانی': {
    'en': 'Aviator Sunglasses',
    'ar': 'نظارة شمسية أفياتور',
    'tr': 'Pilot Güneş Gözlüğü',
  },
  'سویشرت کلاه‌دار': {
    'en': 'Pullover Hoodie',
    'ar': 'سويتشيرت بغطاء رأس',
    'tr': 'Kapüşonlu Sweatshirt',
  },
  'کتانی سفید ساده': {
    'en': 'Minimal White Sneakers',
    'ar': 'حذاء رياضي أبيض بسيط',
    'tr': 'Sade Beyaz Spor Ayakkabı',
  },
  'زارا': {'en': 'Zara', 'ar': 'زارا', 'tr': 'Zara'},
  'نایک': {'en': 'Nike', 'ar': 'نايك', 'tr': 'Nike'},
  'استایل‌مورف': {'en': 'StyleMorph', 'ar': 'ستايل مورف', 'tr': 'StyleMorph'},
  'رز': {'en': 'Rose', 'ar': 'روز', 'tr': 'Rose'},
  'نورث': {'en': 'North', 'ar': 'نورث', 'tr': 'North'},
  'اورینت': {'en': 'Orient', 'ar': 'أورينت', 'tr': 'Orient'},
  'ژوپیتر': {'en': 'Jupiter', 'ar': 'جوبيتر', 'tr': 'Jupiter'},
  'ال‌سی': {'en': 'LC Waikiki', 'ar': 'إل سي', 'tr': 'LC Waikiki'},
  'نگار': {'en': 'Negar Beauty', 'ar': 'نغار', 'tr': 'Negar'},
  'ماوی': {'en': 'Mavi', 'ar': 'مافي', 'tr': 'Mavi'},
  'ری‌بن': {'en': 'Ray-Ban', 'ar': 'راي بان', 'tr': 'Ray-Ban'},
  'آدیداس': {'en': 'Adidas', 'ar': 'أديداس', 'tr': 'Adidas'},
  'فروشگاه زارا': {
    'en': 'Zara Store',
    'ar': 'متجر زارا',
    'tr': 'Zara Mağazası',
  },
  'بوتیک آرمان': {
    'en': 'Arman Boutique',
    'ar': 'بوتيك أرمان',
    'tr': 'Arman Butik',
  },
  'دیجی‌استایل': {'en': 'DigiStyle', 'ar': 'ديجي ستايل', 'tr': 'DigiStyle'},
  'نمایندگی نایک': {
    'en': 'Nike Official',
    'ar': 'توكيل نايك',
    'tr': 'Nike Yetkili Satıcı',
  },
  'اسپرت‌لند': {'en': 'SportLand', 'ar': 'سبورت لاند', 'tr': 'SportLand'},
  'گالری چرم رز': {
    'en': 'Rose Leather Gallery',
    'ar': 'معرض جلد روز',
    'tr': 'Rose Deri Galeri',
  },
  'زمان‌سنج': {'en': 'ZamanSanj', 'ar': 'زمان سنج', 'tr': 'ZamanSanj'},
  'ساعت‌پلاس': {'en': 'SaatPlus', 'ar': 'ساعة بلس', 'tr': 'SaatPlus'},
  'مد و مانتو سارا': {
    'en': 'Sara Fashion',
    'ar': 'أزياء سارة',
    'tr': 'Sara Moda',
  },
  'آرایشی نگار': {
    'en': 'Negar Cosmetics',
    'ar': 'مستحضرات نغار',
    'tr': 'Negar Kozmetik',
  },
  'نمایندگی ماوی': {
    'en': 'Mavi Official',
    'ar': 'توكيل مافي',
    'tr': 'Mavi Yetkili Satıcı',
  },
  'گالری اپتیک': {
    'en': 'Optic Gallery',
    'ar': 'معرض البصريات',
    'tr': 'Optik Galeri',
  },
  'نمایندگی آدیداس': {
    'en': 'Adidas Official',
    'ar': 'توكيل أديداس',
    'tr': 'Adidas Yetkili Satıcı',
  },
  '۱ تا ۲ روز': {'en': '1-2 days', 'ar': '١ إلى ٢ يوم', 'tr': '1-2 gün'},
  '۲ تا ۳ روز': {'en': '2-3 days', 'ar': '٢ إلى ٣ أيام', 'tr': '2-3 gün'},
  '۳ تا ۵ روز': {'en': '3-5 days', 'ar': '٣ إلى ٥ أيام', 'tr': '3-5 gün'},
  '۴ تا ۶ روز': {'en': '4-6 days', 'ar': '٤ إلى ٦ أيام', 'tr': '4-6 gün'},
  '۴ تا ۷ روز': {'en': '4-7 days', 'ar': '٤ إلى ٧ أيام', 'tr': '4-7 gün'},
  'کتان ۱۰۰٪': {'en': '100% Linen', 'ar': 'كتان ١٠٠٪', 'tr': '%100 Keten'},
  'پارچه مش و رویه‌ی مصنوعی': {
    'en': 'Mesh & synthetic upper',
    'ar': 'شبك وجزء علوي صناعي',
    'tr': 'File ve sentetik saya',
  },
  'پلی‌استر با پر مصنوعی': {
    'en': 'Polyester with faux down',
    'ar': 'بوليستر بحشوة صناعية',
    'tr': 'Sentetik dolgulu polyester',
  },
  'چرم طبیعی': {
    'en': 'Genuine Leather',
    'ar': 'جلد طبيعي',
    'tr': 'Hakiki Deri',
  },
  'پارچه ضدآب': {
    'en': 'Waterproof fabric',
    'ar': 'قماش مقاوم للماء',
    'tr': 'Su geçirmez kumaş',
  },
  'استیل ضدزنگ': {
    'en': 'Stainless steel',
    'ar': 'فولاذ مقاوم للصدأ',
    'tr': 'Paslanmaz çelik',
  },
  'مس با آبکاری طلا': {
    'en': 'Gold-plated brass',
    'ar': 'نحاس مطلي بالذهب',
    'tr': 'Altın kaplama pirinç',
  },
  'نخ ۱۰۰٪': {'en': '100% Cotton', 'ar': 'قطن ١٠٠٪', 'tr': '%100 Pamuk'},
  'جین ۹۸٪ پنبه': {
    'en': '98% Cotton Denim',
    'ar': 'جينز ٩٨٪ قطن',
    'tr': '%98 Pamuklu Kot',
  },
  'فرمول مات ضدلک': {
    'en': 'Smudge-proof matte formula',
    'ar': 'تركيبة مطفية ثابتة',
    'tr': 'Leke bırakmayan mat formül',
  },
  'پودری پیگمنت بالا': {
    'en': 'High-pigment powder',
    'ar': 'بودرة عالية التصبغ',
    'tr': 'Yüksek pigmentli pudra',
  },
  'ترکیب پشم و پلی‌استر': {
    'en': 'Wool & polyester blend',
    'ar': 'مزيج صوف وبوليستر',
    'tr': 'Yün ve polyester karışımı',
  },
  'فریم فلزی، لنز پلاریزه': {
    'en': 'Metal frame, polarized lens',
    'ar': 'إطار معدني وعدسة مستقطبة',
    'tr': 'Metal çerçeve, polarize cam',
  },
  'نخ و پلی‌استر': {
    'en': 'Cotton & polyester',
    'ar': 'قطن وبوليستر',
    'tr': 'Pamuk ve polyester',
  },
  'شلوار جین آبی': {'en': 'Blue jeans', 'ar': 'جينز أزرق', 'tr': 'Mavi kot'},
  'کیف دوشی بژ': {
    'en': 'Beige shoulder bag',
    'ar': 'حقيبة كتف بيج',
    'tr': 'Bej omuz çantası',
  },
  'ست ورزشی مشکی': {
    'en': 'Black sport set',
    'ar': 'طقم رياضي أسود',
    'tr': 'Siyah spor takımı',
  },
  'کفش ورزشی سفید': {
    'en': 'White sneakers',
    'ar': 'حذاء رياضي أبيض',
    'tr': 'Beyaz spor ayakkabı',
  },
  'پیراهن کتان': {'en': 'Linen shirt', 'ar': 'قميص كتان', 'tr': 'Keten gömlek'},
  'شال نخی': {'en': 'Cotton scarf', 'ar': 'وشاح قطني', 'tr': 'Pamuklu şal'},
  'کت اسپرت': {'en': 'Casual blazer', 'ar': 'بليزر كاجوال', 'tr': 'Spor ceket'},
  'کیف دوشی': {'en': 'Shoulder bag', 'ar': 'حقيبة كتف', 'tr': 'Omuz çantası'},
  'شلوار جین': {'en': 'Denim jeans', 'ar': 'بنطال جينز', 'tr': 'Kot pantolon'},
  'ساعت کلاسیک': {
    'en': 'Classic watch',
    'ar': 'ساعة كلاسيكية',
    'tr': 'Klasik saat',
  },

  // ── Stylist Catalog ─────────────────────────────────────────────────────
  'ست راحت شهری': {
    'en': 'Urban Casual Set',
    'ar': 'إطلالة المدينة المريحة',
    'tr': 'Şehir Rahat Kombini',
  },
  'ست بهاره روشن': {
    'en': 'Bright Spring Look',
    'ar': 'إطلالة الربيع المشرقة',
    'tr': 'Parlak Bahar Kombini',
  },
  'ست ساده و گرم': {
    'en': 'Cozy Minimal Layering',
    'ar': 'إطلالة بسيطة ودافئة',
    'tr': 'Sade ve Sıcak Kombin',
  },
  'هماهنگ با زیرتن گرم': {
    'en': 'Matches warm undertone',
    'ar': 'يناسب البشرة الدافئة',
    'tr': 'Sıcak alt tona uyumlu',
  },
  'مناسب ۱۸ درجه': {
    'en': 'Ideal for 18°C',
    'ar': 'مناسب لـ ١٨ درجة',
    'tr': '18°C için ideal',
  },
  'رنگ‌های پالت شما': {
    'en': 'Your palette colors',
    'ar': 'ألوان لوحتك',
    'tr': 'Palet renkleriniz',
  },
  'مناسب مهمانی': {
    'en': 'Party ready',
    'ar': 'مناسب للحفلات',
    'tr': 'Partiye uygun',
  },
  'لایه‌بندی راحت': {
    'en': 'Easy layering',
    'ar': 'تنسيق طبقات مريح',
    'tr': 'Rahat katmanlama',
  },
  'با ۵ لباس دیگر ست می‌شود': {
    'en': 'Pairs with 5 other pieces',
    'ar': 'يتناسق مع ٥ قطع أخرى',
    'tr': '5 farklı parçayla kombinlenir',
  },
  'بوت چرمی قهوه‌ای': {
    'en': 'Brown Leather Boots',
    'ar': 'بوت جلد بني',
    'tr': 'Kahverengi Deri Bot',
  },
  'پالتو مشکی اداری': {
    'en': 'Black Office Coat',
    'ar': 'معطف أسود للعمل',
    'tr': 'Siyah Ofis Kabanı',
  },
  'هودی طوسی ساده': {
    'en': 'Simple Gray Hoodie',
    'ar': 'هودي رمادي بسيط',
    'tr': 'Sade Gri Kapüşonlu',
  },
  'کفش رسمی چرم': {
    'en': 'Leather Formal Shoes',
    'ar': 'حذاء جلدي رسمي',
    'tr': 'Deri Klasik Ayakkabı',
  },
  'شال سبز پشمی': {
    'en': 'Green Wool Scarf',
    'ar': 'وشاح صوف أخضر',
    'tr': 'Yeşil Yün Şal',
  },
  'پیراهن آبی': {'en': 'Blue Shirt', 'ar': 'قميص أزرق', 'tr': 'Mavi Gömlek'},
  'سریع': {'en': 'Fast', 'ar': 'سريع', 'tr': 'Hızlı'},
  'استاندارد': {'en': 'Standard', 'ar': 'قياسي', 'tr': 'Standart'},
  'سینمایی (۴K)': {
    'en': 'Cinematic (4K)',
    'ar': 'سينمائي (4K)',
    'tr': 'Sinematik (4K)',
  },
  'وضوح استاندارد، پردازش سریع در ۵ ثانیه': {
    'en': 'Standard resolution, fast 5-second render',
    'ar': 'دقة قياسية، معالجة سريعة خلال ٥ ثوانٍ',
    'tr': 'Standart çözünürlük, 5 saniyede hızlı işlem',
  },
  'وضوح بالا با هماهنگی دقیق چین‌وچروک و بافت پارچه': {
    'en': 'High resolution with accurate fabric creases & texture',
    'ar': 'دقة عالية مع محاكاة دقيقة لطيات ونسيج القماش',
    'tr': 'Doğru kumaş kıvrımları ve dokusuyla yüksek çözünürlük',
  },
  'پردازش فوق‌العاده جزئیات و نورپردازی استودیویی': {
    'en': 'Ultra-detailed rendering with studio lighting',
    'ar': 'تفاصيل فائقة وإضاءة استوديو احترافية',
    'tr': 'Ultra detaylı işleme ve stüdyo aydınlatması',
  },
  'سلام سارا عزیز! امروز هوا ۱۸ درجه و آفتابی‌ست. با توجه به برنامه کاری امروز، این ست راحت و شیک شهری را از کمد خودتان پیشنهاد می‌کنم.': {
    'en':
        'Hi Sara! Today is 18°C and sunny. Based on your schedule, I recommend this chic urban casual outfit from your wardrobe.',
    'ar':
        'مرحباً سارة! الطقس اليوم ١٨ درجة ومشمس. بناءً على جدولك، أقترح هذه الإطلالة الأنيقة من خزانتك.',
    'tr':
        'Merhaba Sara! Bugün hava 18°C ve güneşli. Programına göre gardırobundan bu şık şehir kombinini öneriyorum.',
  },
  'یک گزینه رسمی‌تر هم برای جلسه عصر در نظر داری؟': {
    'en': 'Do you have a more formal option for the evening meeting?',
    'ar': 'هل لديك خيار أكثر رسمية لاجتماع المساء؟',
    'tr': 'Akşam toplantısı için daha resmi bir seçeneğin var mı?',
  },
  'بله حتماً! می‌توانیم کت سرمه‌ای را با کفش رسمی طوسی جایگزین کنیم تا کاملاً حالت کاری و فاخر به خود بگیرد.': {
    'en':
        'Absolutely! We can swap in a navy blazer and gray formal shoes for a sharp executive look.',
    'ar':
        'بالتأكيد! يمكننا استبدال السترة الكحلية مع حذاء رمادي رسمي لإطلالة عمل أنيقة.',
    'tr':
        'Elbette! Lacivert ceket ve gri klasik ayakkabı ile tam bir iş görünümü elde edebiliriz.',
  },

  // ── Atelier Templates & Statuses ────────────────────────────────────────
  'پرتره استودیویی کلاسیک': {
    'en': 'Classic Studio Portrait',
    'ar': 'بورتريه استوديو كلاسيكي',
    'tr': 'Klasik Stüdyo Portresi',
  },
  'پرتره ساده و تمیز با نور استودیو، مناسب عکس پروفایل.': {
    'en': 'Clean portrait with studio lighting, ideal for profile photos.',
    'ar': 'بورتريه نقي بإضاءة استوديو مثالي لصورة الملف الشخصي.',
    'tr': 'Profil fotoğrafları için ideal, stüdyo ışıklı sade portre.',
  },
  'هدشات رسمی و حرفه‌ای': {
    'en': 'Executive Formal Headshot',
    'ar': 'صورة شخصية رسمية ومهنية',
    'tr': 'Profesyonel İş Portresi',
  },
  'دو قاب رسمی مناسب رزومه کاری و شبکه‌های حرفه‌ای.': {
    'en': 'Two formal frames tailored for resumes and LinkedIn.',
    'ar': 'إطاران رسميان مناسبان للسيرة الذاتية والشبكات المهنية.',
    'tr': 'Özgeçmiş ve profesyonel ağlar için iki resmi kare.',
  },
  'مجموعه نوروزی بهار': {
    'en': 'Spring Blossom Collection',
    'ar': 'مجموعة أزهار الربيع',
    'tr': 'Bahar Çiçekleri Koleksiyonu',
  },
  'چهار قاب با سفره هفت‌سین، گل و رنگ‌های سرزنده بهاری.': {
    'en': 'Four vibrant spring frames with fresh florals and pastel tones.',
    'ar': 'أربعة إطارات ربيعية مبهجة بالزهور والألوان المشرقة.',
    'tr': 'Canlı bahar renkleri ve çiçeklerle dört özel kare.',
  },
  'ست مد خیابانی (Street Style)': {
    'en': 'Editorial Street Style',
    'ar': 'أزياء الشارع العصرية',
    'tr': 'Sokak Modası (Street Style)',
  },
  'سه قاب شهری با استایل روزمره و حال‌وهوای مجله فشن.': {
    'en': 'Three urban frames with fashion-magazine street aesthetics.',
    'ar': 'ثلاثة إطارات حضرية بأسلوب مجلات الموضة.',
    'tr': 'Moda dergisi estetiğinde üç günlük şehir karesi.',
  },
  'پرتره سینمایی موشن': {
    'en': 'Cinematic Motion Portrait',
    'ar': 'بورتريه حركي سينمائي',
    'tr': 'Sinematik Hareketli Portre',
  },
  'ویدیوی کوتاه با نور و حرکت دوربین ملایم سینمایی.': {
    'en': 'Short video reel with gentle cinema camera motion.',
    'ar': 'فيديو قصير بإضاءة وحركة كاميرا سينمائية ناعمة.',
    'tr': 'Yumuşak sinematik kamera hareketli kısa video.',
  },
  'چرخش ۳۶۰ درجه مد': {
    'en': '360° Fashion Showcase',
    'ar': 'عرض أزياء ٣٦٠ درجة',
    'tr': '360° Moda Dönüşü',
  },
  'ویدیوی چرخشی که استایل شما را از تمام زوایا به نمایش می‌گذارد.': {
    'en': 'Rotating video showcasing your outfit from every angle.',
    'ar': 'فيديو دائري يستعرض إطلالتك من جميع الزوايا.',
    'tr': 'Stilinizi her açıdan sergileyen 360 derece video.',
  },
  'سفر به پاریس': {
    'en': 'Trip to Paris',
    'ar': 'رحلة إلى باريس',
    'tr': 'Paris Seyahati',
  },
  'چهار قاب فوتورئال در خیابان‌ها و کافه‌های پاریس.': {
    'en': 'Four photorealistic frames in Parisian streets and cafés.',
    'ar': 'أربعة إطارات واقعية في شوارع ومقاهي باريس.',
    'tr': 'Paris sokaklarında ve kafelerinde dört fotogerçekçi kare.',
  },
  'شب یلدا و پاییز': {
    'en': 'Cozy Autumn Evening',
    'ar': 'أمسية خريف دافئة',
    'tr': 'Sıcak Sonbahar Akşamı',
  },
  'سه قاب گرم با نمادهای یلدایی، انار و نور شمع.': {
    'en': 'Three warm candlelight frames with autumn hues.',
    'ar': 'ثلاثة إطارات دافئة على ضوء الشموع وألوان الخريف.',
    'tr': 'Mum ışığı ve sonbahar tonlarıyla üç sıcak kare.',
  },
  'ورزشی و پرانرژی': {
    'en': 'Athletic & High-Energy',
    'ar': 'رياضي ومفعم بالحيوية',
    'tr': 'Sportif ve Enerjik',
  },
  'دو قاب پویا با لباس ورزشی و پس‌زمینه باشگاه مدرن.': {
    'en': 'Two dynamic athletic frames in a modern studio gym.',
    'ar': 'إطاران حيويان بملابس رياضية وخلفية نادي عصري.',
    'tr': 'Modern spor salonu arka planında iki dinamik kare.',
  },
  'ریلز کوتاه استایل': {
    'en': 'Style Transition Reel',
    'ar': 'ريلز تنسيق الأزياء القصير',
    'tr': 'Kısa Stil Geçiş Reels',
  },
  'ریلز عمودی با تغییر پیوسته ست‌ها و ریتم جذاب.': {
    'en': 'Vertical reel featuring seamless outfit transitions.',
    'ar': 'فيديو عمودي مع تبديل سلس للإطلالات.',
    'tr': 'Akıcı kombin geçişlerine sahip dikey video.',
  },
  '۱۰ دقیقه': {'en': '10 min', 'ar': '١٠ دقائق', 'tr': '10 dk'},
  '۲۵ دقیقه': {'en': '25 min', 'ar': '٢٥ دقيقة', 'tr': '25 dk'},
  '۱ عکس · کیفیت فوق‌العاده': {
    'en': '1 Photo · Ultra Quality',
    'ar': '١ صورة · جودة فائقة',
    'tr': '1 Fotoğraf · Ultra Kalite',
  },
  '۲ عکس · کیفیت بالا': {
    'en': '2 Photos · High Quality',
    'ar': '٢ صورة · جودة عالية',
    'tr': '2 Fotoğraf · Yüksek Kalite',
  },
  '۴ عکس · ادیتوریال لوکس': {
    'en': '4 Photos · Luxury Editorial',
    'ar': '٤ صور · تحريري فاخر',
    'tr': '4 Fotoğraf · Lüks Editoryal',
  },
  '۳ عکس · کیفیت بالا': {
    'en': '3 Photos · High Quality',
    'ar': '٣ صور · جودة عالية',
    'tr': '3 Fotoğraf · Yüksek Kalite',
  },
  '۸ ثانیه · ۱۰۸۰p Full HD': {
    'en': '8 sec · 1080p Full HD',
    'ar': '٨ ثوانٍ · 1080p Full HD',
    'tr': '8 sn · 1080p Full HD',
  },
  '۸ ثانیه · ۶۰ فریم ۱۰۸۰p': {
    'en': '8 sec · 60fps 1080p',
    'ar': '٨ ثوانٍ · ٦٠ إطار 1080p',
    'tr': '8 sn · 60fps 1080p',
  },
  '۴ عکس · وضوح بالا': {
    'en': '4 Photos · High Clarity',
    'ar': '٤ صور · وضوح عالٍ',
    'tr': '4 Fotoğraf · Yüksek Netlik',
  },
  '۳ عکس · کیفیت عالی': {
    'en': '3 Photos · Great Quality',
    'ar': '٣ صور · جودة ممتازة',
    'tr': '3 Fotoğraf · Mükemmel Kalite',
  },
  '۸ ثانیه · ۱۰۸۰p عمودی': {
    'en': '8 sec · 1080p Vertical',
    'ar': '٨ ثوانٍ · 1080p عمودي',
    'tr': '8 sn · 1080p Dikey',
  },
  'پس‌زمینه': {'en': 'Background', 'ar': 'الخلفية', 'tr': 'Arka Plan'},
  'نورپردازی': {'en': 'Lighting', 'ar': 'الإضاءة', 'tr': 'Aydınlatma'},
  'نسبت ابعاد': {
    'en': 'Aspect Ratio',
    'ar': 'نسبة العرض',
    'tr': 'En-Boy Oranı',
  },
  'نور': {'en': 'Light', 'ar': 'الإضاءة', 'tr': 'Işık'},
  'لباس': {'en': 'Outfit', 'ar': 'الملابس', 'tr': 'Kıyafet'},
  'نسبت تصویر': {'en': 'Ratio', 'ar': 'النسبة', 'tr': 'Oran'},
  'ژست': {'en': 'Pose', 'ar': 'الوضعية', 'tr': 'Poz'},
  'نسبت': {'en': 'Ratio', 'ar': 'النسبة', 'tr': 'Oran'},
  'محیط شهر': {'en': 'City Scene', 'ar': 'مشهد المدينة', 'tr': 'Şehir Ortamı'},
  'نور طلایی': {'en': 'Golden Hour', 'ar': 'الضوء الذهبي', 'tr': 'Altın Saat'},
  'لباس کمد': {'en': 'Wardrobe Fit', 'ar': 'من خزانتك', 'tr': 'Gardıroptan'},
  'کادر عمودی': {
    'en': 'Portrait Frame',
    'ar': 'إطار عمودي',
    'tr': 'Dikey Kadraj',
  },
  'کادر': {'en': 'Framing', 'ar': 'الإطار', 'tr': 'Kadraj'},
  'موقعیت کافه': {'en': 'Café Scene', 'ar': 'موقع المقهى', 'tr': 'Kafe Ortamı'},
  'نور عصر': {'en': 'Evening Light', 'ar': 'ضوء المساء', 'tr': 'Akşam Işığı'},
  'نور شمع': {'en': 'Candlelight', 'ar': 'ضوء الشموع', 'tr': 'Mum Işığı'},
  'لباس سنتی': {'en': 'Traditional', 'ar': 'لباس تقليدي', 'tr': 'Geleneksel'},
  'باشگاه': {'en': 'Gym', 'ar': 'النادي', 'tr': 'Spor Salonu'},
  'نور نئونی': {'en': 'Neon Light', 'ar': 'إضاءة نيون', 'tr': 'Neon Işık'},
  'اکسسوری': {'en': 'Accessories', 'ar': 'إكسسوارات', 'tr': 'Aksesuar'},
  'تغییر ست': {
    'en': 'Outfit Switch',
    'ar': 'تبديل الإطلالة',
    'tr': 'Kombin Geçişi',
  },
  'نسبت ۹:۱۶': {'en': '9:16 Ratio', 'ar': 'نسبة ٩:١٦', 'tr': '9:16 Oran'},
  'در صف': {'en': 'Queued', 'ar': 'في الانتظار', 'tr': 'Sırada'},
  'در حال ساخت': {'en': 'Rendering', 'ar': 'قيد الإنشاء', 'tr': 'İşleniyor'},
  'آماده': {'en': 'Ready', 'ar': 'جاهز', 'tr': 'Hazır'},
  'ناموفق': {'en': 'Failed', 'ar': 'فشل', 'tr': 'Başarısız'},
  '۲ روز پیش': {'en': '2 days ago', 'ar': 'منذ يومين', 'tr': '2 gün önce'},
  'امروز': {'en': 'Today', 'ar': 'اليوم', 'tr': 'Bugün'},
  'دیروز': {'en': 'Yesterday', 'ar': 'أمس', 'tr': 'Dün'},

  // ── Wellness Status & Tasks ─────────────────────────────────────────────
  'خوب': {'en': 'Good', 'ar': 'جيد', 'tr': 'İyi'},
  'تمرین کوتاه ۱۰ دقیقه‌ای کششی': {
    'en': '10-minute morning stretch routine',
    'ar': 'تمرين إطالة خفيف لمدة ١٠ دقائق',
    'tr': '10 dakikalık esneme egzersizi',
  },
  'استفاده از مرطوب‌کننده صبح و شب': {
    'en': 'Morning & night hydrating moisturizer',
    'ar': 'استخدام المرطب صباحاً ومساءً',
    'tr': 'Sabah ve akşam nemlendirici bakımı',
  },
  '۳ دقیقه تمرین تنفس آرام ذهن‌آگاهی': {
    'en': '3-minute calm mindfulness breathing',
    'ar': 'تمرين تنفس وهدوء لمدة ٣ دقائق',
    'tr': '3 dakikalık farkındalık nefes egzersizi',
  },

  // ── Stylist Dialogs & Modals Extra ──────────────────────────────────────
  'آیتم انتخابی از کمد': {
    'en': 'wardrobe items selected',
    'ar': 'قطع مختارة من الخزانة',
    'tr': 'gardırop öğesi seçildi',
  },
  'پیش‌نمایش پرو روی آناتومی شما': {
    'en': 'Try-on preview on your anatomy',
    'ar': 'معاينة القياس على قوامك',
    'tr': 'Vücut yapınızda deneme önizlemesi',
  },
  'تطابق بافت پارچه و چین‌خوردگی تأیید شد': {
    'en': 'Fabric texture & drape alignment verified',
    'ar': 'تم التحقق من نسيج القماش والطيات',
    'tr': 'Kumaş dokusu ve kıvrım uyumu doğrulandı',
  },
  'در حال نگه‌داشت امن سکه...': {
    'en': 'Reserving StyleCoins securely...',
    'ar': 'جاري حجز العملات بأمان...',
    'tr': 'Jetonlar güvenle ayrılıyor...',
  },
  'بررسی تطابق آناتومیک و اصلاح اسکلت...': {
    'en': 'Checking anatomical fit & posture alignment...',
    'ar': 'فحص التطابق التشريحي وتصحيح القوام...',
    'tr': 'Anatomik uyum ve duruş hizalaması kontrol ediliyor...',
  },
  'پردازش بافت و مدل‌سازی سه‌بعدی لباس...': {
    'en': 'Rendering fabric weave & 3D garment draping...',
    'ar': 'معالجة نسيج القماش والنمذجة ثلاثية الأبعاد...',
    'tr': 'Kumaş dokusu ve 3D kıyafet modellemesi işleniyor...',
  },
  'سیستم خودترمیمی آناتومی فعال است': {
    'en': 'Self-healing anatomical guardian active',
    'ar': 'نظام الحماية التشريحي الذكي نشط',
    'tr': 'Otomatik anatomik düzeltme sistemi aktif',
  },
  'هزینه کسر': {
    'en': 'Deduction',
    'ar': 'المبلغ المخصوم',
    'tr': 'Kesinti Tutarı',
  },
  'تأیید و اجرای پرو مجازی': {
    'en': 'Confirm & Run Virtual Try-On',
    'ar': 'تأكيد وتشغيل القياس الافتراضي',
    'tr': 'Onayla ve Sanal Denemeyi Başlat',
  },
  'شنبه': {'en': 'Saturday', 'ar': 'السبت', 'tr': 'Cumartesi'},
  'یکشنبه': {'en': 'Sunday', 'ar': 'الأحد', 'tr': 'Pazar'},
  'دوشنبه': {'en': 'Monday', 'ar': 'الاثنين', 'tr': 'Pazartesi'},
  'سه‌شنبه': {'en': 'Tuesday', 'ar': 'الثلاثاء', 'tr': 'Salı'},
  'چهارشنبه': {'en': 'Wednesday', 'ar': 'الأربعاء', 'tr': 'Çarşamba'},
  'پنجشنبه': {'en': 'Thursday', 'ar': 'الخميس', 'tr': 'Perşembe'},
  'جمعه': {'en': 'Friday', 'ar': 'الجمعة', 'tr': 'Cuma'},
  'هنوز انتخاب نشده': {
    'en': 'Not selected yet',
    'ar': 'لم يتم التحديد بعد',
    'tr': 'Henüz seçilmedi',
  },
  'مناسبت جدید با تقویم گوشی همگام‌سازی شد.': {
    'en': 'New event synced with your device calendar.',
    'ar': 'تمت مزامنة المناسبة الجديدة مع تقويم هاتفك.',
    'tr': 'Yeni etkinlik telefon takviminizle senkronize edildi.',
  },
  'پالت رنگ سازگار (زیرتن گرم)': {
    'en': 'Harmonized Palette (Warm Undertone)',
    'ar': 'لوحة الألوان المتناغمة (درجة دافئة)',
    'tr': 'Uyumlu Renk Paleti (Sıcak Alt Ton)',
  },
  'فرم لباس مناسب': {
    'en': 'Recommended Silhouettes',
    'ar': 'قصّات الملابس المناسبة',
    'tr': 'Uygun Kıyafet Kesimleri',
  },
  'بر اساس تیپ اندام و AI DNA': {
    'en': 'Based on your body shape & AI DNA',
    'ar': 'بناءً على شكل الجسم و AI DNA',
    'tr': 'Vücut tipinize ve AI DNA verilerine göre',
  },
  'عینک و اکسسوری': {
    'en': 'Eyewear & Accessories',
    'ar': 'النظارات والإكسسوارات',
    'tr': 'Gözlük ve Aksesuarlar',
  },
  'متناسب با فرم بیضی چهره': {
    'en': 'Tailored for your oval face shape',
    'ar': 'متناسق مع شكل الوجه البيضاوي',
    'tr': 'Oval yüz şeklinize uygun',
  },
  'مدل مو و ریش': {
    'en': 'Hair & Grooming Style',
    'ar': 'تسريحة الشعر والعناية',
    'tr': 'Saç ve Bakım Stili',
  },
  'هماهنگ با سبک کژوال و رسمی': {
    'en': 'Matches both casual and formal looks',
    'ar': 'متناغم مع الإطلالات الكاجوال والرسمية',
    'tr': 'Hem günlük hem resmi stile uyumlu',
  },
  'آیتم‌هایی که کمد شما را کامل‌تر می‌کنند (بر اساس ست‌های فعلی):': {
    'en': 'Pieces that complete your wardrobe (based on current outfits):',
    'ar': 'قطع تكمل خزانتك (بناءً على إطلالاتك الحالية):',
    'tr': 'Gardırobunuzu tamamlayacak parçalar (mevcut kombinlere göre):',
  },
  'کت خنثی طوسی': {
    'en': 'Neutral Gray Blazer',
    'ar': 'بليزر رمادي محايد',
    'tr': 'Nötr Gri Ceket',
  },
  'با ۶ لباس شما ست می‌شود': {
    'en': 'Pairs with 6 of your items',
    'ar': 'يتناسق مع ٦ قطع لديك',
    'tr': '6 parçanızla kolayca kombinlenir',
  },
  'کفش رسمی مشکی': {
    'en': 'Black Dress Shoes',
    'ar': 'حذاء رسمي أسود',
    'tr': 'Siyah Klasik Ayakkabı',
  },
  'برای ۴ ست رسمی کمد خالی است': {
    'en': 'Missing from 4 formal outfits',
    'ar': 'ناقص لـ ٤ إطلالات رسمية',
    'tr': '4 resmi kombininiz için eksik parça',
  },
  'شال سبز نخی': {
    'en': 'Green Cotton Scarf',
    'ar': 'وشاح قطني أخضر',
    'tr': 'Yeşil Pamuklu Şal',
  },
  'لایه تکمیلی پالت گرم شما': {
    'en': 'Finishing layer for your warm palette',
    'ar': 'طبقة مكملة للوحتك الدافئة',
    'tr': 'Sıcak paletiniz için tamamlayıcı katman',
  },
  'پرپوش‌ترین رنگ‌های کمد شما': {
    'en': 'Most Worn Colors in Your Wardrobe',
    'ar': 'أكثر الألوان ارتداءً في خزانتك',
    'tr': 'Gardırobunuzda En Çok Giyilen Renkler',
  },
  'آیتم‌های فراموش‌شده در کمد:': {
    'en': 'Forgotten items in your wardrobe:',
    'ar': 'قطع منسية في خزانتك:',
    'tr': 'Gardırobunuzda unutulan parçalar:',
  },
  'مانتو بژ کتان': {
    'en': 'Beige Linen Coat',
    'ar': 'معطف كتان بيج',
    'tr': 'Bej Keten Kaban',
  },
  '۶۵ روز بدون استفاده': {
    'en': '65 days unworn',
    'ar': '٦٥ يوماً دون استخدام',
    'tr': '65 gündür giyilmedi',
  },
  '۴۸ روز بدون استفاده': {
    'en': '48 days unworn',
    'ar': '٤٨ يوماً دون استخدام',
    'tr': '48 gündür kullanılmadı',
  },

  // ── Atelier Sheets & Extra Labels ───────────────────────────────────────
  'ظرفیت پلن عادی': {
    'en': 'Standard Plan Quota',
    'ar': 'سعة الخطة العادية',
    'tr': 'Standart Plan Kotası',
  },
  'آماده‌شده در تاریخ': {
    'en': 'Ready on',
    'ar': 'جاهز بتاريخ',
    'tr': 'Hazırlanma tarihi',
  },
  'فایل خروجی با بالاترین کیفیت در گالری ذخیره شد.': {
    'en': 'Output saved in highest quality to your gallery.',
    'ar': 'تم حفظ الملف بأعلى جودة في المعرض.',
    'tr': 'Çıktı en yüksek kalitede galeriye kaydedildi.',
  },
  'سفارش قالب': {
    'en': 'Template order',
    'ar': 'طلب القالب',
    'tr': 'Şablon siparişi',
  },
  'ثبت شد و به صف هوش مصنوعی رفت.': {
    'en': 'placed and queued for AI generation.',
    'ar': 'تم تسجيله وإرساله لطابور الذكاء الاصطناعي.',
    'tr': 'alındı ve yapay zekâ sırasına eklendi.',
  },
  'عکس‌های پایه آلبوم پروفایل شما تکمیل است.': {
    'en': 'Your base profile album photos are complete.',
    'ar': 'الصور الأساسية في ألبوم ملفك مكتملة.',
    'tr': 'Temel profil albümü fotoğraflarınız tamamlandı.',
  },
  'ابعاد و مشخصات AI DNA ثبت شده است.': {
    'en': 'Your AI DNA measurements and specs are saved.',
    'ar': 'تم حفظ قياسات ومواصفات AI DNA الخاصة بك.',
    'tr': 'AI DNA ölçü ve özellikleriniz kayıtlı.',
  },
  'چهره شما توسط سیستم احراز هویت اولیه تایید شد.': {
    'en': 'Your face verification check is approved.',
    'ar': 'تم التحقق المبدئي من ملامح وجهك بنجاح.',
    'tr': 'Yüz doğrulama kontrolünüz onaylandı.',
  },

  // ── Wellness Modals Extra Labels ────────────────────────────────────────
  'به‌روزرسانی تحلیل از عکس': {
    'en': 'Refresh Analysis from Photo',
    'ar': 'تحديث التحليل من الصورة',
    'tr': 'Fotoğraftan Analizi Güncelle',
  },
  'وضعیت خوب': {'en': 'Good Status', 'ar': 'حالة جيدة', 'tr': 'İyi Durum'},
  'بر اساس روتین مراقبت و عکس‌های پروفایل شما؛ قضاوتی درباره چهره نیست.': {
    'en':
        'Based on your skincare routine & profile photos; non-judgmental assessment.',
    'ar': 'بناءً على روتين العناية وصور ملفك؛ تقييم موضوعي بدون أحكام.',
    'tr':
        'Bakım rutininiz ve profil fotoğraflarınıza dayalı; yargılamayan analiz.',
  },
  'مراقبت منظم': {
    'en': 'Routine Consistency',
    'ar': 'انتظام العناية',
    'tr': 'Düzenli Bakım',
  },
  'وضعیت پوست': {'en': 'Skin Health', 'ar': 'حالة البشرة', 'tr': 'Cilt Durumu'},
  'وضعیت مو': {'en': 'Hair Health', 'ar': 'حالة الشعر', 'tr': 'Saç Durumu'},
  'روتین‌های امروز شما': {
    'en': 'Your Routines Today',
    'ar': 'روتينك اليوم',
    'tr': 'Bugünkü Rutinleriniz',
  },
  'صبح: شست‌وشو و آبرسان': {
    'en': 'AM: Cleanser & Moisturizer',
    'ar': 'صباحاً: غسول ومرطب',
    'tr': 'Sabah: Temizleyici & Nemlendirici',
  },
  'شب: پاک‌کننده ملایم و کرم شب': {
    'en': 'PM: Gentle Cleanser & Night Cream',
    'ar': 'مساءً: منظف لطيف وكريم ليلي',
    'tr': 'Akşam: Nazik Temizleyici & Gece Kremi',
  },
  'تحلیل عمیق پوست و مو': {
    'en': 'Deep Skin & Hair Analysis',
    'ar': 'تحليل عميق للبشرة والشعر',
    'tr': 'Derin Cilt ve Saç Analizi',
  },
  'نوع پوست، رطوبت و نیازهای فصلی': {
    'en': 'Skin type, hydration & seasonal needs',
    'ar': 'نوع البشرة والترطيب والاحتياجات الموسمية',
    'tr': 'Cilt tipi, nem ve mevsimsel ihtiyaçlar',
  },
  'مشاوره زیبایی هوشمند': {
    'en': 'Smart Beauty Consultation',
    'ar': 'استشارة الجمال الذكية',
    'tr': 'Akıllı Güzellik Danışmanlığı',
  },
  'راهکارهای مراقبت غیرتهاجمی': {
    'en': 'Non-invasive care recommendations',
    'ar': 'توصيات عناية غير تداخلية',
    'tr': 'Doğal ve zarif bakım önerileri',
  },
  'تقویم مراقبت و روتین‌ها': {
    'en': 'Care & Routine Calendar',
    'ar': 'تقويم العناية والروتين',
    'tr': 'Bakım ve Rutin Takvimi',
  },
  'یادآوری‌های هوشمند روزانه': {
    'en': 'Smart daily reminders',
    'ar': 'تذكيرات يومية ذكية',
    'tr': 'Akıllı günlük hatırlatıcılar',
  },
  'ثبت اطلاعات امروز': {
    'en': 'Log Today’s Metrics',
    'ar': 'تسجيل بيانات اليوم',
    'tr': 'Bugünkü Verileri Kaydet',
  },
  'وضعیت عالی': {'en': 'Excellent', 'ar': 'حالة ممتازة', 'tr': 'Mükemmel'},
  'بر اساس خواب، تغذیه و فعالیت‌های هفته اخیر شما.': {
    'en': 'Based on your sleep, nutrition & activity over the past week.',
    'ar': 'بناءً على نومك وتغذيتك ونشاطك خلال الأسبوع الماضي.',
    'tr': 'Son haftadaki uyku, beslenme ve aktivitenize göre.',
  },
  'کیفیت خواب': {
    'en': 'Sleep Quality',
    'ar': 'جودة النوم',
    'tr': 'Uyku Kalitesi',
  },
  'تغذیه': {'en': 'Nutrition', 'ar': 'التغذية', 'tr': 'Beslenme'},
  'فعالیت بدنی': {
    'en': 'Physical Activity',
    'ar': 'النشاط البدني',
    'tr': 'Fiziksel Aktivite',
  },
  'خواب': {'en': 'Sleep', 'ar': 'النوم', 'tr': 'Uyku'},
  'ورزش': {'en': 'Workout', 'ar': 'التمارين', 'tr': 'Egzersiz'},
  'پیشنهاد وعده غذایی سالم': {
    'en': 'Healthy Meal Suggestions',
    'ar': 'اقتراح وجبة صحية',
    'tr': 'Sağlıklı Öğün Önerisi',
  },
  'بر اساس هدف تناسب اندام و کالری مناسب': {
    'en': 'Matched to your fitness goal & calorie target',
    'ar': 'بناءً على هدف اللياقة والسعرات المناسبة',
    'tr': 'Fitness hedefinize ve kalori dengenize uygun',
  },
  'ثبت سریع وعده روزانه': {
    'en': 'Quick Daily Meal Log',
    'ar': 'تسجيل سريع للوجبة',
    'tr': 'Hızlı Öğün Kaydı',
  },
  'عکس یا متن برای بررسی خودکار هوش مصنوعی': {
    'en': 'Snap or type for automatic AI nutrition check',
    'ar': 'صورة أو نص للتحليل التلقائي بالذكاء الاصطناعي',
    'tr': 'Otomatik AI analiz için fotoğraf veya metin',
  },
  'مدت خواب دیشب': {
    'en': 'Last Night’s Sleep',
    'ar': 'مدة النوم الليلة الماضية',
    'tr': 'Dün Geceki Uyku',
  },
  '۷ ساعت': {'en': '7 Hours', 'ar': '٧ ساعات', 'tr': '7 Saat'},
  'ساعت پیشنهادی خواب': {
    'en': 'Recommended Bedtime',
    'ar': 'وقت النوم المقترح',
    'tr': 'Önerilen Uyku Saati',
  },
  '۲۳:۰۰ برای هماهنگی ریتم شبانه‌روزی': {
    'en': '23:00 to align with your circadian rhythm',
    'ar': '٢٣:٠٠ لضبط الإيقاع الحيوي',
    'tr': 'Sirkadiyen ritim için 23:00',
  },
  'ش': {'en': 'S', 'ar': 'س', 'tr': 'C'},
  'ی': {'en': 'S', 'ar': 'ح', 'tr': 'P'},
  'د': {'en': 'M', 'ar': 'ن', 'tr': 'P'},
  'س': {'en': 'T', 'ar': 'ث', 'tr': 'S'},
  'چ': {'en': 'W', 'ar': 'ر', 'tr': 'Ç'},
  'پ': {'en': 'T', 'ar': 'خ', 'tr': 'P'},
  'ج': {'en': 'F', 'ar': 'ج', 'tr': 'C'},
  'برنامه تمرین هفتگی': {
    'en': 'Weekly Workout Plan',
    'ar': 'خطة التمرين الأسبوعية',
    'tr': 'Haftalık Antrenman Planı',
  },
  '۴ روز در هفته تمرینات فانکشنال': {
    'en': '4 days/week functional training',
    'ar': '٤ أيام في الأسبوع تمارين وظيفية',
    'tr': 'Haftada 4 gün fonksiyonel antrenman',
  },
  'ثبت حال امروز': {
    'en': 'Log Today’s Mood',
    'ar': 'سجّل مزاجك اليوم',
    'tr': 'Bugünkü Ruh Halini Kaydet',
  },
  'وضعیت متعادل': {
    'en': 'Balanced',
    'ar': 'حالة متوازنة',
    'tr': 'Dengeli Durum',
  },
  'بر اساس ثبت خلق‌وخو، خواب و استرس روزانه؛ تشخیص پزشکی نیست.': {
    'en': 'Based on daily mood, sleep & stress logs; not a medical diagnosis.',
    'ar': 'بناءً على تسجيل المزاج والنوم والتوتر؛ ليس تشخيصاً طبياً.',
    'tr':
        'Günlük ruh hali, uyku ve stres verilerine göre; tıbbi tanı değildir.',
  },
  'خلق‌وخو': {'en': 'Mood', 'ar': 'المزاج', 'tr': 'Ruh Hali'},
  'کنترل استرس': {
    'en': 'Stress Control',
    'ar': 'إدارة التوتر',
    'tr': 'Stres Kontrolü',
  },
  'کیفیت استراحت': {
    'en': 'Rest Quality',
    'ar': 'جودة الراحة',
    'tr': 'Dinlenme Kalitesi',
  },
  'تمرین تنفس ۳ دقیقه‌ای': {
    'en': '3-Minute Breathing Exercise',
    'ar': 'تمرين تنفس لمدة ٣ دقائق',
    'tr': '3 Dakikalık Nefes Egzersizi',
  },
  'آرام‌سازی فوری ذهن با ضرباهنگ ۴-۴-۴': {
    'en': 'Instant calm with 4-4-4 box breathing rhythm',
    'ar': 'تهدئة فورية للذهن بإيقاع ٤-٤-٤',
    'tr': '4-4-4 ritmiyle zihni hızla sakinleştirin',
  },
  'تمرین تنفس آرام‌بخش شروع شد. ۴ ثانیه دم، ۴ ثانیه حبس، ۴ ثانیه بازدم.': {
    'en': 'Calming breathing started. Inhale 4s, hold 4s, exhale 4s.',
    'ar': 'بدأ تمرين التنفس: شهيق ٤ ثوانٍ، حبس ٤ ثوانٍ، زفير ٤ ثوانٍ.',
    'tr': 'Rahatlatıcı nefes başladı: 4 sn nefes al, 4 sn tut, 4 sn ver.',
  },
  'مدیتیشن و مایندفولنس': {
    'en': 'Meditation & Mindfulness',
    'ar': 'التأمل والوعي الذهني',
    'tr': 'Meditasyon ve Farkındalık',
  },
  'جلسات ۵ و ۱۰ دقیقه‌ای صوتی': {
    'en': '5 & 10-minute guided audio sessions',
    'ar': 'جلسات صوتية موجهة لمدة ٥ و ١٠ دقائق',
    'tr': '5 ve 10 dakikalık sesli seanslar',
  },
  'گفتگو با همراه هوش مصنوعی': {
    'en': 'Talk with AI Companion',
    'ar': 'تحدث مع المرافق الذكي',
    'tr': 'Yapay Zekâ Rehberiyle Sohbet',
  },
  'تخلیه ذهن در محیطی کاملاً خصوصی و امن': {
    'en': 'Express your thoughts in a private, safe space',
    'ar': 'عبّر عن أفكارك في مساحة خاصة وآمنة تماماً',
    'tr': 'Tamamen gizli ve güvenli bir alanda zihninizi rahatlatın',
  },
  'تأیید و اجرای شبیه‌ساز': {
    'en': 'Confirm & Run Simulator',
    'ar': 'تأكيد وتشغيل المحاكي',
    'tr': 'Onayla ve Simülatörü Başlat',
  },
  'اگر به اهداف ورزشی و روتین‌های مراقبتی خود متعهد بمانید، چهره و اندام شما چه تغییری می‌کند؟': {
    'en':
        'If you stay consistent with your workouts and care routines, how will your face and posture evolve?',
    'ar':
        'إذا التزمت بأهدافك الرياضية وروتين العناية، كيف سيتغير مظهرك وقوامك؟',
    'tr':
        'Egzersiz ve bakım rutinlerinize bağlı kalırsanız yüzünüz ve duruşunuz nasıl gelişir?',
  },
  '۳ ماه': {'en': '3 Months', 'ar': '٣ أشهر', 'tr': '3 Ay'},
  '۶ ماه': {'en': '6 Months', 'ar': '٦ أشهر', 'tr': '6 Ay'},
  '۱ سال': {'en': '1 Year', 'ar': 'سنة واحدة', 'tr': '1 Yıl'},
  'وضعیت فعلی': {
    'en': 'Current State',
    'ar': 'الحالة الحالية',
    'tr': 'Mevcut Durum',
  },
  'خودِ آینده': {
    'en': 'Future Self',
    'ar': 'ذاتك المستقبلية',
    'tr': 'Gelecekteki Ben',
  },
  'پیش‌نمایش آینده': {
    'en': 'Future Preview',
    'ar': 'معاينة المستقبل',
    'tr': 'Gelecek Önizlemesi',
  },
  'تغییرات پیش‌بینی‌شده کاملاً فیزیولوژیک و واقع‌بینانه هستند و هرگز چهره غیرواقعی تولید نمی‌کنند. این تحلیل جایگزین مشاوره پزشکی نیست.': {
    'en':
        'Projected changes are strictly physiological and realistic without artificial facial distortion. Not a substitute for medical advice.',
    'ar':
        'التغييرات المتوقعة فيزيولوجية وواقعية تماماً ولا تنتج ملامح غير طبيعية، ولا تغني عن الاستشارة الطبية.',
    'tr':
        'Öngörülen değişimler tamamen fizyolojik ve gerçekçidir; tıbbi tavsiye yerine geçmez.',
  },
  'می‌پذیرم که ۱۰ سکه کسر شود و نتیجه یک شبیه‌سازی آماری است.': {
    'en':
        'I agree to deduct 10 Coins and acknowledge this is a statistical simulation.',
    'ar': 'أوافق على خصم ١٠ عملات وأقرّ بأن النتيجة محاكاة إحصائية.',
    'tr':
        '10 Jeton düşülmesini ve sonucun istatistiksel bir simülasyon olduğunu kabul ediyorum.',
  },
  'ذخیره در پرونده سلامت': {
    'en': 'Save to Health Record',
    'ar': 'حفظ في السجل الصحي',
    'tr': 'Sağlık Kaydına Ekle',
  },
  'اطلاعات روزانه با موفقیت در داشبورد ثبت شد.': {
    'en': 'Daily check-in saved to your dashboard.',
    'ar': 'تم حفظ التقييم اليومي في لوحتك بنجاح.',
    'tr': 'Günlük durum kaydı panonuza eklendi.',
  },
  'امروز چه حالی دارید؟': {
    'en': 'How are you feeling today?',
    'ar': 'كيف تشعر اليوم؟',
    'tr': 'Bugün nasıl hissediyorsunuz?',
  },
  'سطح انرژی امروز': {
    'en': 'Today’s Energy Level',
    'ar': 'مستوى الطاقة اليوم',
    'tr': 'Bugünkü Enerji Seviyesi',
  },
  'کم': {'en': 'Low', 'ar': 'منخفض', 'tr': 'Düşük'},
  'زیاد': {'en': 'High', 'ar': 'عالي', 'tr': 'Yüksek'},
  'میزان خواب دیشب': {
    'en': 'Last Night’s Sleep Duration',
    'ar': 'ساعات النوم ليلة أمس',
    'tr': 'Dün Geceki Uyku Süresi',
  },
  'کمتر از ۶ ساعت': {
    'en': 'Under 6 hours',
    'ar': 'أقل من ٦ ساعات',
    'tr': '6 saatten az',
  },
  '۶ تا ۸ ساعت': {
    'en': '6 to 8 hours',
    'ar': '٦ إلى ٨ ساعات',
    'tr': '6 - 8 saat',
  },
  'بیشتر از ۸ ساعت': {
    'en': 'Over 8 hours',
    'ar': 'أكثر من ٨ ساعات',
    'tr': '8 saatten fazla',
  },
  'وزن امروز (کیلوگرم - اختیاری)': {
    'en': 'Today’s Weight (kg - optional)',
    'ar': 'الوزن اليوم (كجم - اختياري)',
    'tr': 'Bugünkü Kilo (kg - isteğe bağlı)',
  },
};
