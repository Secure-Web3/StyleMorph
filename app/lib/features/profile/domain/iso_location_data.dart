class IsoCity {
  final String nameEn;
  final String nameFa;
  final String nameAr;
  final String nameTr;

  const IsoCity({
    required this.nameEn,
    required this.nameFa,
    required this.nameAr,
    required this.nameTr,
  });

  String localizedName(String localeCode) {
    final lang = localeCode.toLowerCase().split(RegExp(r'[-_]')).first;
    switch (lang) {
      case 'fa':
        return nameFa;
      case 'ar':
        return nameAr;
      case 'tr':
        return nameTr;
      case 'en':
      default:
        return nameEn;
    }
  }
}

class IsoProvince {
  final String code;
  final String nameEn;
  final String nameFa;
  final String nameAr;
  final String nameTr;
  final List<IsoCity> cities;

  const IsoProvince({
    required this.code,
    required this.nameEn,
    required this.nameFa,
    required this.nameAr,
    required this.nameTr,
    this.cities = const [],
  });

  String localizedName(String localeCode) {
    final lang = localeCode.toLowerCase().split(RegExp(r'[-_]')).first;
    switch (lang) {
      case 'fa':
        return nameFa;
      case 'ar':
        return nameAr;
      case 'tr':
        return nameTr;
      case 'en':
      default:
        return nameEn;
    }
  }
}

class IsoCountry {
  final String code; // ISO-3166-1 alpha-2
  final String flag; // Emoji flag
  final String dialCode; // e.g. +98
  final int subscriberLength; // Typical mobile digits
  final String nameEn;
  final String nameFa;
  final String nameAr;
  final String nameTr;
  final List<IsoProvince> provinces;

  const IsoCountry({
    required this.code,
    required this.flag,
    required this.dialCode,
    required this.subscriberLength,
    required this.nameEn,
    required this.nameFa,
    required this.nameAr,
    required this.nameTr,
    this.provinces = const [],
  });

  String localizedName(String localeCode) {
    final lang = localeCode.toLowerCase().split(RegExp(r'[-_]')).first;
    switch (lang) {
      case 'fa':
        return nameFa;
      case 'ar':
        return nameAr;
      case 'tr':
        return nameTr;
      case 'en':
      default:
        return nameEn;
    }
  }
}

class IsoLocationData {
  static const List<IsoCountry> countries = [
    // ── Iran ────────────────────────────────────────────────────────────────
    IsoCountry(
      code: 'IR',
      flag: '🇮🇷',
      dialCode: '+98',
      subscriberLength: 10,
      nameEn: 'Iran',
      nameFa: 'ایران',
      nameAr: 'إيران',
      nameTr: 'İran',
      provinces: [
        IsoProvince(
          code: 'TEH',
          nameEn: 'Tehran',
          nameFa: 'تهران',
          nameAr: 'طهران',
          nameTr: 'Tahran',
          cities: [
            IsoCity(
              nameEn: 'Tehran',
              nameFa: 'تهران',
              nameAr: 'طهران',
              nameTr: 'Tahran',
            ),
            IsoCity(
              nameEn: 'Shemiranat',
              nameFa: 'شمیرانات',
              nameAr: 'شميرانات',
              nameTr: 'Şemiranat',
            ),
            IsoCity(nameEn: 'Rey', nameFa: 'ری', nameAr: 'الري', nameTr: 'Rey'),
            IsoCity(
              nameEn: 'Eslamshahr',
              nameFa: 'اسلامشهر',
              nameAr: 'إسلام شهر',
              nameTr: 'İslamşehr',
            ),
            IsoCity(
              nameEn: 'Shahriar',
              nameFa: 'شهریار',
              nameAr: 'شهريار',
              nameTr: 'Şehriyar',
            ),
            IsoCity(
              nameEn: 'Damavand',
              nameFa: 'دماوند',
              nameAr: 'دماوند',
              nameTr: 'Damavand',
            ),
            IsoCity(
              nameEn: 'Pardis',
              nameFa: 'پردیس',
              nameAr: 'برديس',
              nameTr: 'Pardis',
            ),
            IsoCity(
              nameEn: 'Varamin',
              nameFa: 'ورامین',
              nameAr: 'ورامين',
              nameTr: 'Varamin',
            ),
          ],
        ),
        IsoProvince(
          code: 'ISF',
          nameEn: 'Isfahan',
          nameFa: 'اصفهان',
          nameAr: 'أصفهان',
          nameTr: 'İsfahan',
          cities: [
            IsoCity(
              nameEn: 'Isfahan',
              nameFa: 'اصفهان',
              nameAr: 'أصفهان',
              nameTr: 'İsfahan',
            ),
            IsoCity(
              nameEn: 'Kashan',
              nameFa: 'کاشان',
              nameAr: 'كاشان',
              nameTr: 'Kaşan',
            ),
            IsoCity(
              nameEn: 'Najafabad',
              nameFa: 'نجف‌آباد',
              nameAr: 'نجف آباد',
              nameTr: 'Necefabad',
            ),
            IsoCity(
              nameEn: 'Shahin Shahr',
              nameFa: 'شاهین‌شهر',
              nameAr: 'شاهين شهر',
              nameTr: 'Şahinşehr',
            ),
          ],
        ),
        IsoProvince(
          code: 'FAR',
          nameEn: 'Fars',
          nameFa: 'فارس',
          nameAr: 'فارس',
          nameTr: 'Fars',
          cities: [
            IsoCity(
              nameEn: 'Shiraz',
              nameFa: 'شیراز',
              nameAr: 'شيراز',
              nameTr: 'Şiraz',
            ),
            IsoCity(
              nameEn: 'Marvdasht',
              nameFa: 'مرودشت',
              nameAr: 'مرودشت',
              nameTr: 'Mervdeşt',
            ),
            IsoCity(
              nameEn: 'Jahrom',
              nameFa: 'جهرم',
              nameAr: 'جهرم',
              nameTr: 'Cehrom',
            ),
            IsoCity(
              nameEn: 'Fasa',
              nameFa: 'فسا',
              nameAr: 'فسا',
              nameTr: 'Fasa',
            ),
          ],
        ),
        IsoProvince(
          code: 'KHR',
          nameEn: 'Khorasan Razavi',
          nameFa: 'خراسان رضوی',
          nameAr: 'خراسان الرضوية',
          nameTr: 'Razavi Horasan',
          cities: [
            IsoCity(
              nameEn: 'Mashhad',
              nameFa: 'مشهد',
              nameAr: 'مشهد',
              nameTr: 'Meşhed',
            ),
            IsoCity(
              nameEn: 'Neyshabur',
              nameFa: 'نیشابور',
              nameAr: 'نيسابور',
              nameTr: 'Nişabur',
            ),
            IsoCity(
              nameEn: 'Sabzevar',
              nameFa: 'سبزوار',
              nameAr: 'سبزوار',
              nameTr: 'Sebzevar',
            ),
            IsoCity(
              nameEn: 'Torbat-e Heydarieh',
              nameFa: 'تربت حیدریه',
              nameAr: 'تربت حيدرية',
              nameTr: 'Türbet Haydariye',
            ),
          ],
        ),
        IsoProvince(
          code: 'EAZ',
          nameEn: 'East Azerbaijan',
          nameFa: 'آذربایجان شرقی',
          nameAr: 'أذربيجان الشرقية',
          nameTr: 'Doğu Azerbaycan',
          cities: [
            IsoCity(
              nameEn: 'Tabriz',
              nameFa: 'تبریز',
              nameAr: 'تبريز',
              nameTr: 'Tebriz',
            ),
            IsoCity(
              nameEn: 'Maragheh',
              nameFa: 'مراغه',
              nameAr: 'مراغة',
              nameTr: 'Meraga',
            ),
            IsoCity(
              nameEn: 'Marand',
              nameFa: 'مرند',
              nameAr: 'مرند',
              nameTr: 'Merend',
            ),
            IsoCity(
              nameEn: 'Mianeh',
              nameFa: 'میانه',
              nameAr: 'ميانه',
              nameTr: 'Miyane',
            ),
          ],
        ),
        IsoProvince(
          code: 'ALB',
          nameEn: 'Alborz',
          nameFa: 'البرز',
          nameAr: 'ألبرز',
          nameTr: 'Elbruz',
          cities: [
            IsoCity(
              nameEn: 'Karaj',
              nameFa: 'کرج',
              nameAr: 'كرج',
              nameTr: 'Kerec',
            ),
            IsoCity(
              nameEn: 'Fardis',
              nameFa: 'فردیس',
              nameAr: 'فرديس',
              nameTr: 'Ferdis',
            ),
            IsoCity(
              nameEn: 'Hashtgerd',
              nameFa: 'هشتگرد',
              nameAr: 'هشتغرد',
              nameTr: 'Heştgerd',
            ),
          ],
        ),
        IsoProvince(
          code: 'MAZ',
          nameEn: 'Mazandaran',
          nameFa: 'مازندران',
          nameAr: 'مازندران',
          nameTr: 'Mazenderan',
          cities: [
            IsoCity(
              nameEn: 'Sari',
              nameFa: 'ساری',
              nameAr: 'ساري',
              nameTr: 'Sari',
            ),
            IsoCity(
              nameEn: 'Babol',
              nameFa: 'بابل',
              nameAr: 'بابل',
              nameTr: 'Babul',
            ),
            IsoCity(
              nameEn: 'Amol',
              nameFa: 'آمل',
              nameAr: 'آمل',
              nameTr: 'Amol',
            ),
            IsoCity(
              nameEn: 'Qaem Shahr',
              nameFa: 'قائم‌شهر',
              nameAr: 'قائم شهر',
              nameTr: 'Kaimşehr',
            ),
          ],
        ),
        IsoProvince(
          code: 'GIL',
          nameEn: 'Gilan',
          nameFa: 'گیلان',
          nameAr: 'غيلان',
          nameTr: 'Gilan',
          cities: [
            IsoCity(
              nameEn: 'Rasht',
              nameFa: 'رشت',
              nameAr: 'رشت',
              nameTr: 'Reşt',
            ),
            IsoCity(
              nameEn: 'Bandar-e Anzali',
              nameFa: 'بندر انزلی',
              nameAr: 'بندر أنزلي',
              nameTr: 'Enzeli Limanı',
            ),
            IsoCity(
              nameEn: 'Lahijan',
              nameFa: 'لاهیجان',
              nameAr: 'لاهيجان',
              nameTr: 'Lahican',
            ),
          ],
        ),
        IsoProvince(
          code: 'KHZ',
          nameEn: 'Khuzestan',
          nameFa: 'خوزستان',
          nameAr: 'خوزستان',
          nameTr: 'Huzistan',
          cities: [
            IsoCity(
              nameEn: 'Ahvaz',
              nameFa: 'اهواز',
              nameAr: 'الأهواز',
              nameTr: 'Ahvaz',
            ),
            IsoCity(
              nameEn: 'Abadan',
              nameFa: 'آبادان',
              nameAr: 'عبادان',
              nameTr: 'Abadan',
            ),
            IsoCity(
              nameEn: 'Dezful',
              nameFa: 'دزفول',
              nameAr: 'دزفول',
              nameTr: 'Dezful',
            ),
          ],
        ),
        IsoProvince(
          code: 'QOM',
          nameEn: 'Qom',
          nameFa: 'قم',
          nameAr: 'قم',
          nameTr: 'Kum',
          cities: [
            IsoCity(nameEn: 'Qom', nameFa: 'قم', nameAr: 'قم', nameTr: 'Kum'),
          ],
        ),
        IsoProvince(
          code: 'YZD',
          nameEn: 'Yazd',
          nameFa: 'یزد',
          nameAr: 'يزد',
          nameTr: 'Yezd',
          cities: [
            IsoCity(
              nameEn: 'Yazd',
              nameFa: 'یزد',
              nameAr: 'يزد',
              nameTr: 'Yezd',
            ),
            IsoCity(
              nameEn: 'Meybod',
              nameFa: 'میبد',
              nameAr: 'ميبد',
              nameTr: 'Meybod',
            ),
          ],
        ),
        IsoProvince(
          code: 'KRN',
          nameEn: 'Kerman',
          nameFa: 'کرمان',
          nameAr: 'كرمان',
          nameTr: 'Kirman',
          cities: [
            IsoCity(
              nameEn: 'Kerman',
              nameFa: 'کرمان',
              nameAr: 'كرمان',
              nameTr: 'Kirman',
            ),
            IsoCity(
              nameEn: 'Rafsanjan',
              nameFa: 'رفسنجان',
              nameAr: 'رفسنجان',
              nameTr: 'Refsecan',
            ),
            IsoCity(
              nameEn: 'Sirjan',
              nameFa: 'سیرجان',
              nameAr: 'سيرجان',
              nameTr: 'Sircan',
            ),
          ],
        ),
      ],
    ),

    // ── Turkey ──────────────────────────────────────────────────────────────
    IsoCountry(
      code: 'TR',
      flag: '🇹🇷',
      dialCode: '+90',
      subscriberLength: 10,
      nameEn: 'Turkey',
      nameFa: 'ترکیه',
      nameAr: 'تركيا',
      nameTr: 'Türkiye',
      provinces: [
        IsoProvince(
          code: '34',
          nameEn: 'Istanbul',
          nameFa: 'استانبول',
          nameAr: 'إسطنبول',
          nameTr: 'İstanbul',
          cities: [
            IsoCity(
              nameEn: 'Besiktas',
              nameFa: 'بشیکتاش',
              nameAr: 'بشكتاش',
              nameTr: 'Beşiktaş',
            ),
            IsoCity(
              nameEn: 'Kadikoy',
              nameFa: 'کادیکوی',
              nameAr: 'كاديكوي',
              nameTr: 'Kadıköy',
            ),
            IsoCity(
              nameEn: 'Sisli',
              nameFa: 'شیشلی',
              nameAr: 'شيشلي',
              nameTr: 'Şişli',
            ),
            IsoCity(
              nameEn: 'Uskudar',
              nameFa: 'اسکودار',
              nameAr: 'أسكودار',
              nameTr: 'Üsküdar',
            ),
            IsoCity(
              nameEn: 'Bakirkoy',
              nameFa: 'باکرکوی',
              nameAr: 'باكيركوي',
              nameTr: 'Bakırköy',
            ),
            IsoCity(
              nameEn: 'Sariyer',
              nameFa: 'ساری‌یر',
              nameAr: 'ساريير',
              nameTr: 'Sarıyer',
            ),
          ],
        ),
        IsoProvince(
          code: '06',
          nameEn: 'Ankara',
          nameFa: 'آنکارا',
          nameAr: 'أنقرة',
          nameTr: 'Ankara',
          cities: [
            IsoCity(
              nameEn: 'Cankaya',
              nameFa: 'چانکایا',
              nameAr: 'تشانكايا',
              nameTr: 'Çankaya',
            ),
            IsoCity(
              nameEn: 'Kecioren',
              nameFa: 'کچی‌اورن',
              nameAr: 'كيتشي أورن',
              nameTr: 'Keçiören',
            ),
            IsoCity(
              nameEn: 'Yenimahalle',
              nameFa: 'ینی‌محله',
              nameAr: 'يني محلة',
              nameTr: 'Yenimahalle',
            ),
          ],
        ),
        IsoProvince(
          code: '35',
          nameEn: 'Izmir',
          nameFa: 'ازمیر',
          nameAr: 'إزمير',
          nameTr: 'İzmir',
          cities: [
            IsoCity(
              nameEn: 'Konak',
              nameFa: 'کوناک',
              nameAr: 'كوناك',
              nameTr: 'Konak',
            ),
            IsoCity(
              nameEn: 'Karsiyaka',
              nameFa: 'کارشیاکا',
              nameAr: 'كارشيياكا',
              nameTr: 'Karşıyaka',
            ),
            IsoCity(
              nameEn: 'Bornova',
              nameFa: 'بورنووا',
              nameAr: 'بورنوفا',
              nameTr: 'Bornova',
            ),
            IsoCity(
              nameEn: 'Cesme',
              nameFa: 'چشمه',
              nameAr: 'تشيشمي',
              nameTr: 'Çeşme',
            ),
          ],
        ),
        IsoProvince(
          code: '07',
          nameEn: 'Antalya',
          nameFa: 'آنتالیا',
          nameAr: 'أنطاليا',
          nameTr: 'Antalya',
          cities: [
            IsoCity(
              nameEn: 'Muratpasa',
              nameFa: 'مرادپاشا',
              nameAr: 'مراد باشا',
              nameTr: 'Muratpaşa',
            ),
            IsoCity(
              nameEn: 'Alanya',
              nameFa: 'آلانیا',
              nameAr: 'ألانيا',
              nameTr: 'Alanya',
            ),
            IsoCity(
              nameEn: 'Kemer',
              nameFa: 'کمر',
              nameAr: 'كيمير',
              nameTr: 'Kemer',
            ),
          ],
        ),
        IsoProvince(
          code: '16',
          nameEn: 'Bursa',
          nameFa: 'بورسا',
          nameAr: 'بورصة',
          nameTr: 'Bursa',
          cities: [
            IsoCity(
              nameEn: 'Osmangazi',
              nameFa: 'عثمان‌غازی',
              nameAr: 'عثمان غازي',
              nameTr: 'Osmangazi',
            ),
            IsoCity(
              nameEn: 'Nilufer',
              nameFa: 'نیلوفر',
              nameAr: 'نيلوفر',
              nameTr: 'Nilüfer',
            ),
          ],
        ),
      ],
    ),

    // ── United Arab Emirates ────────────────────────────────────────────────
    IsoCountry(
      code: 'AE',
      flag: '🇦🇪',
      dialCode: '+971',
      subscriberLength: 9,
      nameEn: 'United Arab Emirates',
      nameFa: 'امارات متحده عربی',
      nameAr: 'الإمارات العربية المتحدة',
      nameTr: 'Birleşik Arap Emirlikleri',
      provinces: [
        IsoProvince(
          code: 'DXB',
          nameEn: 'Dubai',
          nameFa: 'دبی',
          nameAr: 'دبي',
          nameTr: 'Dubai',
          cities: [
            IsoCity(
              nameEn: 'Downtown Dubai',
              nameFa: 'مرکز شهر دبی',
              nameAr: 'وسط مدينة دبي',
              nameTr: 'Dubai Merkez',
            ),
            IsoCity(
              nameEn: 'Dubai Marina',
              nameFa: 'دبی مارینا',
              nameAr: 'دبي مارينا',
              nameTr: 'Dubai Marina',
            ),
            IsoCity(
              nameEn: 'Deira',
              nameFa: 'دیره',
              nameAr: 'ديرة',
              nameTr: 'Deyra',
            ),
            IsoCity(
              nameEn: 'Jumeirah',
              nameFa: 'جمیرا',
              nameAr: 'جميرا',
              nameTr: 'Jumeirah',
            ),
          ],
        ),
        IsoProvince(
          code: 'AUH',
          nameEn: 'Abu Dhabi',
          nameFa: 'ابوظبی',
          nameAr: 'أبوظبي',
          nameTr: 'Abu Dabi',
          cities: [
            IsoCity(
              nameEn: 'Abu Dhabi City',
              nameFa: 'شهر ابوظبی',
              nameAr: 'مدينة أبوظبي',
              nameTr: 'Abu Dabi Şehri',
            ),
            IsoCity(
              nameEn: 'Al Ain',
              nameFa: 'العین',
              nameAr: 'العين',
              nameTr: 'El Ayn',
            ),
          ],
        ),
        IsoProvince(
          code: 'SHJ',
          nameEn: 'Sharjah',
          nameFa: 'شارجه',
          nameAr: 'الشارقة',
          nameTr: 'Şarika',
          cities: [
            IsoCity(
              nameEn: 'Sharjah City',
              nameFa: 'شهر شارجه',
              nameAr: 'مدينة الشارقة',
              nameTr: 'Şarika Şehri',
            ),
          ],
        ),
      ],
    ),

    // ── United States ───────────────────────────────────────────────────────
    IsoCountry(
      code: 'US',
      flag: '🇺🇸',
      dialCode: '+1',
      subscriberLength: 10,
      nameEn: 'United States',
      nameFa: 'ایالات متحده آمریکا',
      nameAr: 'الولايات المتحدة',
      nameTr: 'Amerika Birleşik Devletleri',
      provinces: [
        IsoProvince(
          code: 'CA',
          nameEn: 'California',
          nameFa: 'کالیفرنیا',
          nameAr: 'كاليفورنيا',
          nameTr: 'Kaliforniya',
          cities: [
            IsoCity(
              nameEn: 'Los Angeles',
              nameFa: 'لس‌آنجلس',
              nameAr: 'لوس أنجلوس',
              nameTr: 'Los Angeles',
            ),
            IsoCity(
              nameEn: 'San Francisco',
              nameFa: 'سان‌فرانسیسکو',
              nameAr: 'سان فرانسيسكو',
              nameTr: 'San Francisco',
            ),
            IsoCity(
              nameEn: 'San Diego',
              nameFa: 'سن‌دیگو',
              nameAr: 'سان دييغو',
              nameTr: 'San Diego',
            ),
            IsoCity(
              nameEn: 'San Jose',
              nameFa: 'سن‌خوزه',
              nameAr: 'سان خوسيه',
              nameTr: 'San Jose',
            ),
          ],
        ),
        IsoProvince(
          code: 'NY',
          nameEn: 'New York',
          nameFa: 'نیویورک',
          nameAr: 'نيويورك',
          nameTr: 'New York',
          cities: [
            IsoCity(
              nameEn: 'New York City',
              nameFa: 'شهر نیویورک',
              nameAr: 'مدينة نيويورك',
              nameTr: 'New York Şehri',
            ),
            IsoCity(
              nameEn: 'Buffalo',
              nameFa: 'بوفالو',
              nameAr: 'بافالو',
              nameTr: 'Buffalo',
            ),
          ],
        ),
        IsoProvince(
          code: 'TX',
          nameEn: 'Texas',
          nameFa: 'تگزاس',
          nameAr: 'تكساس',
          nameTr: 'Teksas',
          cities: [
            IsoCity(
              nameEn: 'Houston',
              nameFa: 'هیوستون',
              nameAr: 'هيوستن',
              nameTr: 'Houston',
            ),
            IsoCity(
              nameEn: 'Austin',
              nameFa: 'آستین',
              nameAr: 'أوستن',
              nameTr: 'Austin',
            ),
            IsoCity(
              nameEn: 'Dallas',
              nameFa: 'دالاس',
              nameAr: 'دالاس',
              nameTr: 'Dallas',
            ),
          ],
        ),
        IsoProvince(
          code: 'FL',
          nameEn: 'Florida',
          nameFa: 'فلوریدا',
          nameAr: 'فلوريدا',
          nameTr: 'Florida',
          cities: [
            IsoCity(
              nameEn: 'Miami',
              nameFa: 'میامی',
              nameAr: 'ميامي',
              nameTr: 'Miami',
            ),
            IsoCity(
              nameEn: 'Orlando',
              nameFa: 'اورلاندو',
              nameAr: 'أورلاندو',
              nameTr: 'Orlando',
            ),
          ],
        ),
      ],
    ),

    // ── United Kingdom ──────────────────────────────────────────────────────
    IsoCountry(
      code: 'GB',
      flag: '🇬🇧',
      dialCode: '+44',
      subscriberLength: 10,
      nameEn: 'United Kingdom',
      nameFa: 'انگلستان (بریتانیا)',
      nameAr: 'المملكة المتحدة',
      nameTr: 'Birleşik Krallık',
      provinces: [
        IsoProvince(
          code: 'ENG',
          nameEn: 'England',
          nameFa: 'انگلستان',
          nameAr: 'إنجلترا',
          nameTr: 'İngiltere',
          cities: [
            IsoCity(
              nameEn: 'London',
              nameFa: 'لندن',
              nameAr: 'لندن',
              nameTr: 'Londra',
            ),
            IsoCity(
              nameEn: 'Manchester',
              nameFa: 'منچستر',
              nameAr: 'مانشستر',
              nameTr: 'Manchester',
            ),
            IsoCity(
              nameEn: 'Birmingham',
              nameFa: 'بیرمنگام',
              nameAr: 'برمنغهام',
              nameTr: 'Birmingham',
            ),
          ],
        ),
        IsoProvince(
          code: 'SCT',
          nameEn: 'Scotland',
          nameFa: 'اسکاتلند',
          nameAr: 'إسكتلندا',
          nameTr: 'İskoçya',
          cities: [
            IsoCity(
              nameEn: 'Edinburgh',
              nameFa: 'ادینبرو',
              nameAr: 'إدنبرة',
              nameTr: 'Edinburgh',
            ),
            IsoCity(
              nameEn: 'Glasgow',
              nameFa: 'گلاسگو',
              nameAr: 'غلاسكو',
              nameTr: 'Glasgow',
            ),
          ],
        ),
      ],
    ),

    // ── Germany ─────────────────────────────────────────────────────────────
    IsoCountry(
      code: 'DE',
      flag: '🇩🇪',
      dialCode: '+49',
      subscriberLength: 10,
      nameEn: 'Germany',
      nameFa: 'آلمان',
      nameAr: 'ألمانيا',
      nameTr: 'Almanya',
      provinces: [
        IsoProvince(
          code: 'BY',
          nameEn: 'Bavaria',
          nameFa: 'بایرن',
          nameAr: 'بافاريا',
          nameTr: 'Bavyera',
          cities: [
            IsoCity(
              nameEn: 'Munich',
              nameFa: 'مونیخ',
              nameAr: 'ميونخ',
              nameTr: 'Münih',
            ),
            IsoCity(
              nameEn: 'Nuremberg',
              nameFa: 'نورنبرگ',
              nameAr: 'نورنبرغ',
              nameTr: 'Nürnberg',
            ),
          ],
        ),
        IsoProvince(
          code: 'BE',
          nameEn: 'Berlin',
          nameFa: 'برلین',
          nameAr: 'برلين',
          nameTr: 'Berlin',
          cities: [
            IsoCity(
              nameEn: 'Berlin',
              nameFa: 'برلین',
              nameAr: 'برلين',
              nameTr: 'Berlin',
            ),
          ],
        ),
        IsoProvince(
          code: 'NW',
          nameEn: 'North Rhine-Westphalia',
          nameFa: 'نوردراین-وستفالن',
          nameAr: 'شمال الراين-وستفاليا',
          nameTr: 'Kuzey Ren-Vestfalya',
          cities: [
            IsoCity(
              nameEn: 'Cologne',
              nameFa: 'کلن',
              nameAr: 'كولونيا',
              nameTr: 'Köln',
            ),
            IsoCity(
              nameEn: 'Dusseldorf',
              nameFa: 'دوسلدورف',
              nameAr: 'دوسلدورف',
              nameTr: 'Düsseldorf',
            ),
          ],
        ),
      ],
    ),

    // ── Canada ──────────────────────────────────────────────────────────────
    IsoCountry(
      code: 'CA',
      flag: '🇨🇦',
      dialCode: '+1',
      subscriberLength: 10,
      nameEn: 'Canada',
      nameFa: 'کانادا',
      nameAr: 'كندا',
      nameTr: 'Kanada',
      provinces: [
        IsoProvince(
          code: 'ON',
          nameEn: 'Ontario',
          nameFa: 'انتاریو',
          nameAr: 'أونتاريو',
          nameTr: 'Ontario',
          cities: [
            IsoCity(
              nameEn: 'Toronto',
              nameFa: 'تورنتو',
              nameAr: 'تورونتو',
              nameTr: 'Toronto',
            ),
            IsoCity(
              nameEn: 'Ottawa',
              nameFa: 'اتاوا',
              nameAr: 'أوتاوا',
              nameTr: 'Ottawa',
            ),
          ],
        ),
        IsoProvince(
          code: 'BC',
          nameEn: 'British Columbia',
          nameFa: 'بریتیش کلمبیا',
          nameAr: 'كولومبيا البريطانية',
          nameTr: 'Britanya Kolumbiyası',
          cities: [
            IsoCity(
              nameEn: 'Vancouver',
              nameFa: 'ونکوور',
              nameAr: 'فانكوفر',
              nameTr: 'Vancouver',
            ),
            IsoCity(
              nameEn: 'Victoria',
              nameFa: 'ویکتوریا',
              nameAr: 'فيكتوريا',
              nameTr: 'Victoria',
            ),
          ],
        ),
        IsoProvince(
          code: 'QC',
          nameEn: 'Quebec',
          nameFa: 'کبک',
          nameAr: 'كيبيك',
          nameTr: 'Québec',
          cities: [
            IsoCity(
              nameEn: 'Montreal',
              nameFa: 'مونترال',
              nameAr: 'مونتريال',
              nameTr: 'Montreal',
            ),
          ],
        ),
      ],
    ),

    // ── France ──────────────────────────────────────────────────────────────
    IsoCountry(
      code: 'FR',
      flag: '🇫🇷',
      dialCode: '+33',
      subscriberLength: 9,
      nameEn: 'France',
      nameFa: 'فرانسه',
      nameAr: 'فرنسا',
      nameTr: 'Fransa',
      provinces: [
        IsoProvince(
          code: 'IDF',
          nameEn: 'Ile-de-France',
          nameFa: 'ایل-دو-فرانس',
          nameAr: 'إيل دو فرانس',
          nameTr: 'Île-de-France',
          cities: [
            IsoCity(
              nameEn: 'Paris',
              nameFa: 'پاریس',
              nameAr: 'باريس',
              nameTr: 'Paris',
            ),
          ],
        ),
        IsoProvince(
          code: 'PAC',
          nameEn: 'Provence-Alpes-Cote d\'Azur',
          nameFa: 'پروانس-آلپ-کوت دازور',
          nameAr: 'بروفنس ألب كوت دازور',
          nameTr: 'Provence-Alpes-Côte d\'Azur',
          cities: [
            IsoCity(
              nameEn: 'Marseille',
              nameFa: 'مارسی',
              nameAr: 'مارسيليا',
              nameTr: 'Marsilya',
            ),
            IsoCity(
              nameEn: 'Nice',
              nameFa: 'نیس',
              nameAr: 'نيس',
              nameTr: 'Nice',
            ),
          ],
        ),
      ],
    ),
  ];

  static IsoCountry get defaultCountry => countries.first; // IR

  static IsoCountry? findByCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final normalized = code.trim().toUpperCase();
    for (final c in countries) {
      if (c.code.toUpperCase() == normalized) return c;
    }
    return null;
  }

  static IsoCountry? findByName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final normalized = name.trim().toLowerCase();
    for (final c in countries) {
      if (c.nameEn.toLowerCase() == normalized ||
          c.nameFa.toLowerCase() == normalized ||
          c.nameAr.toLowerCase() == normalized ||
          c.nameTr.toLowerCase() == normalized ||
          c.code.toLowerCase() == normalized) {
        return c;
      }
    }
    return null;
  }

  static IsoCountry? findByDialCode(String? dialCode) {
    if (dialCode == null || dialCode.trim().isEmpty) return null;
    String clean = dialCode.trim();
    if (!clean.startsWith('+')) clean = '+$clean';
    for (final c in countries) {
      if (c.dialCode == clean) return c;
    }
    return null;
  }

  /// Resolves a province by [code] or localized/Latin [name] within [country].
  static IsoProvince? findProvince(
    IsoCountry country, {
    String? code,
    String? name,
  }) {
    final normCode = code?.trim().toLowerCase() ?? '';
    final normName = name?.trim().toLowerCase() ?? '';
    if (normCode.isEmpty && normName.isEmpty) return null;
    for (final p in country.provinces) {
      if ((normCode.isNotEmpty && p.code.toLowerCase() == normCode) ||
          (normName.isNotEmpty &&
              (p.nameEn.toLowerCase() == normName ||
                  p.nameFa.toLowerCase() == normName ||
                  p.nameAr.toLowerCase() == normName ||
                  p.nameTr.toLowerCase() == normName))) {
        return p;
      }
    }
    return null;
  }

  /// Normalizes a saved country name/code to its canonical Latin (English) name.
  static String normalizeCountryName(String? name, {String? code}) {
    final raw = name?.trim() ?? '';
    final matched = findByCode(code) ?? findByName(raw);
    if (matched != null) return matched.nameEn;
    return raw;
  }

  /// Normalizes a saved province name/code to its canonical Latin (English) name.
  static String normalizeProvinceName(
    IsoCountry country,
    String? name, {
    String? code,
  }) {
    final raw = name?.trim() ?? '';
    final matched = findProvince(country, code: code, name: raw);
    if (matched != null) return matched.nameEn;
    return raw;
  }

  /// Normalizes a saved city name to its canonical Latin (English) name.
  static String normalizeCityName(
    String? name, {
    IsoCountry? country,
    IsoProvince? province,
  }) {
    final raw = name?.trim() ?? '';
    if (raw.isEmpty) return '';
    final norm = raw.toLowerCase();

    bool matchesCity(IsoCity c) =>
        c.nameEn.toLowerCase() == norm ||
        c.nameFa.toLowerCase() == norm ||
        c.nameAr.toLowerCase() == norm ||
        c.nameTr.toLowerCase() == norm;

    if (province != null) {
      for (final c in province.cities) {
        if (matchesCity(c)) return c.nameEn;
      }
    }
    if (country != null) {
      for (final p in country.provinces) {
        for (final c in p.cities) {
          if (matchesCity(c)) return c.nameEn;
        }
      }
    }
    for (final co in countries) {
      for (final p in co.provinces) {
        for (final c in p.cities) {
          if (matchesCity(c)) return c.nameEn;
        }
      }
    }
    return raw;
  }
}
