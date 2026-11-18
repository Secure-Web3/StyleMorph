import 'package:flutter/material.dart';
import 'app_translations_data.dart';

class AppStrings {
  final String localeCode;

  const AppStrings(this.localeCode);

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return AppStrings(locale);
  }

  static const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  static const _arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  static String _normalizedLang(String localeCode) =>
      localeCode.toLowerCase().split(RegExp(r'[-_]')).first;

  /// Converts ASCII/Persian/Arabic digits according to the active locale.
  /// Returns Western digits (0-9) for `en` and `tr`, Persian digits for `fa`,
  /// and Eastern Arabic digits for `ar`.
  String formatNumber(Object input) {
    final raw = input.toString();
    final ascii = _toAsciiDigits(raw);
    final lang = _normalizedLang(localeCode);
    if (lang == 'fa') {
      return _replaceDigits(ascii, _faDigits).replaceAll('%', '٪');
    }
    if (lang == 'ar') {
      return _replaceDigits(ascii, _arDigits).replaceAll('%', '٪');
    }
    return ascii
        .replaceAll('٪', '%')
        .replaceAll('٬', ',')
        .replaceAll('،', ',')
        .replaceAll('٫', '.');
  }

  static String _toAsciiDigits(String s) {
    final buf = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      final faIdx = _faDigits.indexOf(ch);
      if (faIdx != -1) {
        buf.write(faIdx);
        continue;
      }
      final arIdx = _arDigits.indexOf(ch);
      if (arIdx != -1) {
        buf.write(arIdx);
        continue;
      }
      buf.write(ch);
    }
    return buf.toString();
  }

  static String _replaceDigits(String ascii, List<String> targets) {
    final buf = StringBuffer();
    for (final rune in ascii.runes) {
      final code = rune - 48;
      if (code >= 0 && code <= 9) {
        buf.write(targets[code]);
      } else {
        buf.writeCharCode(rune);
      }
    }
    return buf.toString();
  }

  String formatPercent(num pct) {
    final val = pct.round();
    final lang = _normalizedLang(localeCode);
    if (lang == 'fa' || lang == 'ar') {
      return '${formatNumber(val)}٪';
    }
    return '${formatNumber(val)}%';
  }

  String formatCurrency(int amount) {
    final sep = localeCode == 'fa' ? '،' : ',';
    final grouped = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}$sep',
        );
    return '${formatNumber(grouped)} $currencyUnit';
  }

  /// Translates canonical Persian domain labels / mock repository values cleanly
  /// into the active locale, without needing `if (locale == ...)` in UI code.
  String tr(String persianSource) {
    if (localeCode == 'fa') return persianSource;
    final entry = kDomainTranslations[persianSource];
    if (entry != null && entry[localeCode] != null) {
      return entry[localeCode]!;
    }
    return formatNumber(persianSource);
  }

  static const Map<String, Map<String, String>> _values = {
    'fa': {
      'appName': 'StyleMorph',
      'back': 'بازگشت',
      'sub': 'پرو مجازی و پیشنهاد استایل',
      'desc': 'قبل از خرید، لباس را روی تصویر خود امتحان کنید و ست‌های مناسب‌تان را پیدا کنید.',
      'pers': 'استفاده شخصی',
      'biz': 'ورود شرکتی (فروشگاه‌ها)',
      'pT': 'ورود کاربر شخصی',
      'pS': 'برای استفاده از پرو مجازی وارد شوید',
      'bT': 'ورود شرکتی و فروشگاهی',
      'bS': 'مدیریت ویترین و پرو مجازی محصولات',
      'acc': 'ایمیل یا شماره موبایل',
      'pw': 'رمز عبور',
      'bid': 'شناسه ثبت / کد کسب‌وکار',
      'go': 'ادامه و ورود',
      'orText': 'یا',
      'reg': 'ثبت‌نام حساب جدید',
      'forgot': 'فراموشی رمز؟',
      'nShop': 'فروشگاه',
      'nWard': 'کمد',
      'nSty': 'استایلیست',
      'nAtel': 'آتلیه',
      'nWell': 'تندرستی',
      'nProf': 'پروفایل',
      'coin': 'سکه',
      'currencyUnit': 'تومان',
      'verif': 'احراز هویت پایه',
      'supT': 'پشتیبانی آنلاین',
      'supHi': 'سلام! چطور می‌تونم کمکتون کنم؟',
      'supPh': 'پیام شما...',
      'search': 'جستجوی لباس، کفش، اکسسوری...',
      'filter': 'فیلتر',
      'allText': 'همه',
      'soon': 'به‌زودی',
      'mWal': 'مالی و پلن',
      'mFav': 'علاقه‌های من',
      'mRef': 'دعوت و پاداش',
      'mSet': 'تنظیمات',
      'mHist': 'تاریخچه پرو مجازی',
      'mSaved': 'ست‌های ذخیره‌شده',
      'mOrders': 'سفارش‌ها',
      'mAbout': 'درباره ما',
      'mHelp': 'راهنمایی و پشتیبانی',
      'mSupport': 'پشتیبانی و راهنما',
      'mOut': 'خروج از حساب',
      'pcT': 'تکمیل پروفایل',
      'tIdent': 'هویتی',
      'tGal': 'آلبوم رسانه',
      'tAi': 'آناتومی',
      'tWal': 'مالی & پلن',
      'tRef': 'پاداش & شبکه',
      'tComp': 'شخصیت همراه',
      'tSet': 'تنظیمات',
      'hPlan': 'عادی',
      'hFin': 'تکمیل مدارک',
      'sendText': 'ارسال',
      'err': 'خطا در بارگذاری. اتصال یا مسیر فایل را بررسی کنید.',
      'userSa': 'سارا احمدی',
      'usernameSa': '@sara_ahmadi',
      'lvl1': 'Lv1',
      'coinsCount': '۳۵۰',
      'profileCompletionPct': '۴۰٪',
      'wardrobeTitle': 'کمد مجازی',
      'shopTitle': 'فروشگاه مد و استایل',
      'uploadItem': 'آپلود آیتم',
      'planCapacity': 'ظرفیت پلن',
      'searchWardrobe': 'جستجو در کمد...',
      'clearFilters': 'پاک کردن فیلترها',
      'tryOnShortcut': 'امتحانش کن',
      'priceAlert': 'هشدار قیمت',
      'compare': 'مقایسه',
      'fitForMe': 'مناسب تو',
      'matchWardrobe': 'با کمدت ست است',
      'stylistTitle': 'استایلیست شخصی هوش مصنوعی',
      'atelierTitle': 'آتلیه پرتره و فشن هوش مصنوعی',
      'wellnessTitle': 'تندرستی، زیبایی و سلامت هوشمند',
      'virtualTryOn': 'پرو مجازی',
      'myCreations': 'ساخته‌های من',
      'aiWatermarkBadge': 'ساخته‌شده با هوش مصنوعی',
      'futureSelf': 'شبیه‌ساز خودِ آینده',
      'themeLight': 'حالت روز (روشن)',
      'themeDark': 'حالت شب (تاریک)',
      'themeSystem': 'خودکار (هماهنگ با سیستم)',
      'drawerThemeLightTip': '☀️ روشن',
      'drawerThemeDarkTip': '🌙 تاریک',
      'drawerThemeSystemTip': '🔄 خودکار (سیستم)',
      'saveChanges': 'ذخیره تغییرات',
      'noChangesYet': 'تغییراتی ثبت نشده',
      'profileSavedToast': 'تغییرات پروفایل با موفقیت ذخیره شد.',
      'notificationsTitle': 'مرکز اعلان‌ها',
      'markAllRead': 'خواندن همه ✓',
      'noNotifications': 'اعلانی در این دسته وجود ندارد.',
      'notifCatAi': 'هوش مصنوعی و آتلیه',
      'notifCatShop': 'تخفیف و فروشگاه',
      'notifCatFinance': 'مالی و سکه',
      'newWord': 'جدید',
      'idHeader': 'شناسنامه و اطلاعات هویتی',
      'idFirstName': 'نام',
      'idLastName': 'نام خانوادگی',
      'idNick': 'نام مستعار',
      'idNationalId': 'کد ملی',
      'idMobile': 'شماره موبایل',
      'idVerified': 'تایید شده',
      'idEmail': 'ایمیل',
      'idSendCode': 'ارسال کد',
      'idCodeSentToast': 'کد تایید به ایمیل شما ارسال شد.',
      'idCountry': 'کشور',
      'idProvince': 'استان',
      'idCity': 'شهر',
      'idAddress': 'آدرس پستی',
      'idZip': 'کد پستی ۱۰ رقمی',
      'galHeader': 'آلبوم و تصاویر مرجع',
      'galScan360': 'اسکن ۳۶۰ درجه بدن',
      'galUploaded': 'آپلود شده',
      'galPlayToast': 'پخش اسکن ویدیو ۳۶۰ درجه',
      'galBasePhotos': 'عکس‌های پایه چهره و اندام',
      'galUsedInAi': 'استفاده شده در هوش مصنوعی',
      'galApproved': 'تایید',
      'galFullFront': 'قدی روبرو',
      'galSideView': 'نیمرخ',
      'galSlotAdded': 'قاب ۳ با موفقیت انتخاب شد.',
      'galSlotRemoved': 'قاب ۳ حذف شد.',
      'galRecorded': 'ثبت شد',
      'galUploadSlot3': 'آپلود قاب ۳',
      'galTip': 'تصاویر مرجع برای افزایش دقت پرو مجازی لباس و تحلیل اندام استفاده می‌شوند.',
      'aiHeader': 'آناتومی و مشخصات DNA',
      'aiEditable': 'قابل ویرایش',
      'aiNote': 'مقادیر توسط هوش مصنوعی استخراج شده‌اند. با ویرایش هر فیلد، برچسب آن به USER تغییر می‌کند.',
      'aiGender': 'جنسیت',
      'aiFemale': 'زنانه (Female)',
      'aiMale': 'مردانه (Male)',
      'aiHeight': 'قد (cm)',
      'aiWeight': 'وزن (kg)',
      'aiSkinTone': 'رنگ پوست',
      'aiBodyShape': 'فرم بدن',
      'aiFaceShape': 'فرم چهره',
      'aiHair': 'مشخصات مو',
      'aiTailoringHeader': 'اندازه‌های دقیق خیاطی و پرو (Tailoring)',
      'aiShoulder': 'عرض شانه (cm)',
      'aiChest': 'دور سینه (cm)',
      'aiWaist': 'دور کمر',
      'aiBelly': 'دور شکم',
      'aiHips': 'دور باسن',
      'walHeader': 'مالی، کیف پول و پلن‌ها',
      'walActivePlan': 'پلن فعال شما',
      'walActive': 'فعال',
      'walMonthShort': 'ت / ماه',
      'walBuyCoins': 'خرید بسته‌های شارژ StyleCoin',
      'walPopular': 'محبوب‌ترین',
      'walPromoHint': 'کد هدیه یا تخفیف دارید؟ (مثلاً GIFT50)',
      'walApply': 'اعمال',
      'walRecentTx': 'تراکنش‌های اخیر',
      'walTxTopup': 'شارژ آنلاین کیف پول',
      'walTxTopupTime': 'امروز، ۱۲:۴۰',
      'walTxTryon': 'پرو مجازی هوشمند لباس',
      'walTxTryonTime': 'دیروز، ۱۸:۲۰',
      'walPkg200': '۲۰۰ + ۲۰ هدیه',
      'walPromoToast': 'کد هدیه {code} اعمال شد (+{coins} به موجودی افزوده شد!)',
      'walPlanToast': 'پلن شما با موفقیت به {plan} تغییر یافت.',
      'walCoinsAddedToast': '+{coins} به حساب شما واریز شد!',
      'refHeader': 'سیستم پاداش و شبکه دوستان',
      'refInvited': 'اعضای دعوت‌شده',
      'refBonus': 'پاداش دریافتی',
      'refTier': 'سطح شبکه',
      'refLinkLabel': 'لینک اختصاصی دعوت شما',
      'refCopy': 'کپی',
      'refCopiedToast': 'لینک اختصاصی دعوت در کلیپ‌بورد کپی شد!',
      'refJoinedTitle': 'آخرین اعضای ملحق‌شده به شبکه شما',
      'refRuleInfo': 'با دعوت از هر دوست، ۱۰۰ سکه به شما و ۵۰ سکه هدیه به دوست شما تعلق می‌گیرد.',
      'refMembersUnit': 'نفر',
      'perHeader': 'شخصیت همراه و دستیار هوشمند',
      'perSub': 'شخصیت، لحن گفتگو و سطح سختگیری دستیار هوش مصنوعی را مطابق سلیقه خود تنظیم کنید.',
      'perSelectTitle': 'انتخاب شخصیت همراه',
      'perDefaultVoice': 'صدای پیش‌فرض:',
      'perCustomName': 'نام دلخواه برای دستیار (اختیاری)',
      'perCustomNameHint': 'مثلاً: دستیار استایل من',
      'perToneSection': 'لحن گفتگو و میزان سختگیری',
      'perToneLabel': 'سبک و لحن پاسخ‌گویی',
      'perStrictness': 'میزان سختگیری در نقد استایل',
      'perRespLen': 'طول پاسخ‌ها',
      'perVoiceSection': 'تنظیمات صدا و نمایش',
      'perScopeLabel': 'دستیار کجاها فعال باشد؟',
      'perVoiceActive': 'فعال بودن صدای دستیار',
      'perSpeechSpeed': 'سرعت گفتار',
      'perSubtitle': 'نمایش متن همزمان با صدا',
      'perDailyTip': 'نکته روزانه استایل و تندرستی',
      'perSaveHistory': 'ذخیره تاریخچه گفتگو با دستیار',
      'perResetBtn': 'بازگشت به تنظیمات پیش‌فرض',
      'setHeader': 'تنظیمات و سفارشی‌سازی',
      'setPaletteLabel': 'قالب و پالت رنگی مد (Theme Palette)',
      'palWhite': 'سفید مینیمال (Minimal White)',
      'palBeige': 'بژ گرم لوکس (Warm Beige)',
      'palSlate': 'طوسی مدرن (Modern Slate)',
      'palObsidian': 'تیره آبسیدین (Obsidian Dark)',
      'palEditorial': 'ادیتوریال فشن لوکس (Editorial Luxury)',
      'setBrightnessLabel': 'حالت روشنایی (Light / Dark / System)',
      'setLangLabel': 'زبان برنامه (Language)',
      'setShowSupport': 'نمایش ویجت شناور پشتیبانی',
      'setShowHeaderCoins': 'نمایش موجودی سکه در هدر',
      'setBackupLabel': 'پشتیبان‌گیری خودکار داده‌ها',
      'setBackupWeekly': 'هفتگی (پیشنهادی)',
      'setBackupMonthly': 'ماهانه',
      'setBackupOff': 'خاموش',
      'setLogoutBtn': 'خروج از حساب کاربری',
      'wardCatCl': 'لباس',
      'wardCatSh': 'کفش',
      'wardCatBg': 'کیف',
      'wardCatJw': 'زیورآلات',
      'wardCatAc': 'اکسسوری',
      'wardItemUnit': 'آیتم',
      'wardCapacityWord': 'ظرفیت',
      'wardArchive': 'بایگانی',
      'wardArchiveEmpty': 'بایگانی خالی است',
      'wardNotFound': 'موردی پیدا نشد',
      'wardAddItem': 'افزودن آیتم',
      'wardAddSheetTitle': 'افزودن آیتم جدید به کمد',
      'wardImgLoaded': 'تصویر با موفقیت بارگذاری شد',
      'wardImgClick': 'برای آپلود تصویر کلیک کنید',
      'wardImgToast': 'تصویر انتخاب و هوش مصنوعی ویژگی‌های آن را استخراج کرد.',
      'wardItemName': 'نام آیتم',
      'wardItemNameHint': 'مثلاً کت تک سرمه‌ای یا شلوار لینن...',
      'wardCategory': 'دسته‌بندی',
      'wardSelectedColor': 'رنگ انتخابی',
      'wardSeason': 'فصل',
      'wardOccasion': 'مناسبت',
      'wardSaveInWardrobe': 'ذخیره در کمد مجازی',
      'wardFilterColor': 'رنگ',
      'wardSpecMainColor': 'رنگ اصلی',
      'wardSpecSeason': 'فصل مناسب',
      'wardSpecMaterial': 'جنس / پارچه',
      'wardSpecSize': 'سایز',
      'wardStyleInStylist': 'ست کردن در استایلیست',
      'wardUnarchive': 'خروج از بایگانی',
      'wardArchiveAction': 'بایگانی آیتم',
      'wardDeleteTitle': 'حذف آیتم',
      'wardDeleteFromWardrobe': 'حذف از کمد',
      'wardCancel': 'انصراف',
      'wardDelete': 'حذف',
      'wardSentStylistToast': '«{name}» به دستیار استایلیست جهت پیشنهاد ست ارسال شد.',
      'wardDeleteConfirmMsg': 'آیا از حذف «{name}» از کمد اطمینان دارید؟',
      'shopSub': 'قیمت‌ها را مقایسه کن؛ از اپ بخر یا به سایت فروشنده برو',
      'shopSearchHint': 'جستجوی کالا، برند، دسته‌بندی...',
      'shopCatCloth': 'پوشاک',
      'shopCatShoe': 'کفش',
      'shopCatBag': 'کیف',
      'shopCatAcc': 'اکسسوری',
      'shopCatBeauty': 'زیبایی',
      'shopCatFav': 'علاقه‌مندی‌ها',
      'shopSortTitle': 'مرتب‌سازی بر اساس',
      'shopSortRel': 'مرتبط‌ترین',
      'shopSortLo': 'ارزان‌ترین',
      'shopSortHi': 'گران‌ترین',
      'shopSortRt': 'پرامتیازترین',
      'shopSortDc': 'بیشترین تخفیف',
      'shopSortPrefix': 'مرتب‌سازی:',
      'shopFitMeBanner': 'فیلتر مناسب من (سایز M · کفش ۴۲)',
      'shopFitMeSub': 'بر اساس ابعاد ذخیره‌شده در شناسنامه هویتی',
      'shopProductUnit': 'کالا',
      'shopEmpty': 'کالایی با این فیلترها پیدا نشد',
      'shopClearAllFilters': 'حذف تمام فیلترها',
      'shopClear': 'پاک‌کردن',
      'shopDisclaimer': 'قیمت‌ها و موجودی کالاها نمایشی است. هر کالا فروشنده مشخصی دارد؛ محصولات اختصاصی StyleMorph و نمایندگان تأییدشده با ضمانت اپ تحویل می‌شوند و در خرید از وب‌سایت، مسئولیت با فروشنده است.',
      'shopAppBadge': 'اپ',
      'shopOutOfStock': 'ناموجود',
      'shopFromPrice': 'از',
      'shopStoreUnit': 'فروشگاه',
      'shopFilterTitle': 'فیلترهای پیشرفته فروشگاه',
      'shopSaleType': 'نوع خرید',
      'shopSaleApp': 'خرید درون‌برنامه‌ای',
      'shopSaleSite': 'هدایت به سایت فروشگاه',
      'shopGender': 'جنسیت',
      'shopGenderW': 'زنانه',
      'shopGenderM': 'مردانه',
      'shopGenderU': 'یونیسکس',
      'shopMaxPriceNoLimit': 'حداکثر قیمت: بدون سقف',
      'shopMaxPrice': 'حداکثر قیمت',
      'shopBrands': 'برندها',
      'shopToggleAvail': 'فقط کالاهای موجود',
      'shopToggleDisc': 'فقط کالاهای دارای تخفیف',
      'shopToggleVerified': 'فقط فروشندگان تأییدشده و کالای اپ',
      'shopRemoveFilters': 'حذف فیلترها',
      'shopApplyFilters': 'اعمال فیلترها',
      'shopSellerSiteBtn': 'سایت فروشنده',
      'shopCompareActive': 'در مقایسه',
      'shopAlertActive': 'هشدار فعال',
      'shopDiscountWord': 'تخفیف',
      'shopReviewUnit': 'نظر',
      'shopSellersTitle': 'فروشندگان و مقایسه قیمت',
      'shopCheapest': 'ارزان‌ترین',
      'shopDelivery': 'تحویل',
      'shopBuyInApp': 'خرید داخل اپ',
      'shopGoToSite': 'هدایت به سایت',
      'shopProductSpecs': 'مشخصات کالا',
      'shopBrand': 'برند',
      'shopMaterial': 'جنس',
      'shopColorsLabel': 'رنگ‌ها',
      'shopSizesLabel': 'سایزها',
      'shopViewOnSite': 'مشاهده و خرید در سایت فروشنده',
      'shopBuyFromApp': 'خرید از StyleMorph',
      'shopFitTitle': 'ارزیابی هوشمند تناسب (مناسب تو)',
      'shopFitSizeOk': 'سایز مطابق پروفایل شما موجود است.',
      'shopFitColorsOk': 'رنگ‌های سازگار با تناژ پوستی شما:',
      'shopWardrobeMatchTitle': 'پیشنهاد ست: با کمد لباس شما هماهنگ است',
      'shopTryOnDesc': 'این کالا به اتاق پرو هوش مصنوعی فرستاده می‌شود و روی مدل سه‌بعدی و عکس‌های پروفایل شما امتحان خواهد شد.',
      'shopTryOnCost5': 'هزینه پردازش: ۵ سکه',
      'shopSendToTryOn': 'فرستادن به اتاق پرو مجازی',
      'shopInsufficientCoins': 'موجودی سکه شما کافی نیست. از بخش کیف پول سکه تهیه کنید.',
      'shopOfficialAgent': 'نماینده رسمی و تأییدشده',
      'shopIndSeller': 'فروشگاه مستقل عضو شبکه',
      'shopRedirectBtn': 'ورود به سایت فروشنده',
      'shopNoticeOut': 'شما در حال خروج از StyleMorph و ورود به وبسایت اختصاصی فروشنده هستید.',
      'shopNoticePay': 'تمامی فرایندهای پرداخت و ثبت فاکتور روی درگاه پرداخت سایت مقصد انجام می‌شود.',
      'shopNoticeShield': 'ضمانت تحویل و رویه بازگشت کالا تابع قوانین و پشتیبانی همان فروشگاه است.',
      'shopCompareCountMsg': '{count} کالا برای مقایسه انتخاب شد',
      'shopCompareReadyMsg': 'جدول مقایسه {count} کالا آماده شد.',
      'shopTryOnSentToast': '«{name}» به اتاق پرو هوش مصنوعی فرستاده شد ({coins} کسر شد).',
      'shopLeavingToast': 'شما در حال خروج از StyleMorph و ورود به وبسایت اختصاصی «{store}» هستید.',
      'shopRedirectToast': 'هدایت به وب‌سایت فروشگاه {store}... (حالت آزمایشی)',
      'shopOrderPlacedToast': 'سفارش درون‌برنامه‌ای «{name}» ثبت شد.',
      'styWeather': '۱۸° آفتابی',
      'styEnergy': 'انرژی: متوسط',
      'styMyPalette': 'پالت من',
      'styChatTitle': 'رامین (استایلیست)',
      'styChatBannerSub': 'این ست برای امروز عالیه؛ بپرس اگر تغییری می‌خواهی.',
      'styPlanner': 'برنامه‌ریز',
      'styStyleColor': 'سبک و رنگ',
      'stySmartShop': 'خرید هوشمند',
      'styStats': 'آمار استایل',
      'styLocked': 'قفل شده',
      'styLock': 'قفل',
      'stySwap': 'جایگزین',
      'stySaved': 'ذخیره شد',
      'stySave': 'ذخیره',
      'styTryOn': 'پرو',
      'stySwapToast': 'ترکیب جایگزین بر اساس کمد شما محاسبه شد.',
      'styChatFullTitle': 'رامین (استایلیست شخصی هوش مصنوعی)',
      'styAskHint': 'از استایلیست بپرسید...',
      'styDailyQuota': 'سهمیه پیام رایگان امروز',
      'styTryOnDialogTitle': 'اتاق پرو مجازی هوش مصنوعی',
      'styQualityTierTitle': 'انتخاب سطح کیفیت پرو (Quality Tier)',
      'stySaveInAlbum': 'ذخیره در آلبوم من',
      'styTryOnTerms': 'می‌پذیرم که نتیجه تخمینی است و تصویر اختصاصی با رعایت حریم خصوصی مدل‌سازی می‌شود.',
      'styWeeklyPlanner': 'برنامه‌ریز هفتگی استایل',
      'styAddCalEvent': 'افزودن مناسبت تقویم',
      'styStylePaletteTitle': 'سبک و پالت رنگ من',
      'styUpdatePhotoBtn': 'به‌روزرسانی از روی عکس جدید',
      'stySmartShoppingTitle': 'خرید هوشمند (تکمیل‌کننده کمد)',
      'styViewInShop': 'مشاهده این آیتم‌ها در فروشگاه',
      'styStatsTitle': 'آمار و بینش استایل',
      'styGetReport': 'دریافت گزارش کامل ماهانه',
      'atelSub': 'تولید پرتره و ویدیوهای استودیویی از خود شما',
      'atelShowcase': 'ویترین',
      'atelCatPortrait': 'پرتره',
      'atelCatFashion': 'مد',
      'atelCatSeasonal': 'فصلی',
      'atelCatTravel': 'سفر',
      'atelMediaAll': 'همه رسانه‌ها',
      'atelMediaPhoto': 'عکس و پرتره',
      'atelMediaVideo': 'ویدیوی کوتاه',
      'atelVideoBadge': 'ویدیو',
      'atelPhotosUnit': 'عکس',
      'atelSatisfaction': 'رضایت',
      'atelStatusReady': 'آماده',
      'atelStatusProcessing': 'در جریان',
      'atelStatusFailed': 'ناموفق',
      'atelEmptyCreations': 'اثری در این دسته‌بندی یافت نشد.',
      'atelCoinsRefunded': 'سکه بازگردانده شد',
      'atelRetryFree': 'تلاش دوباره',
      'atelPopularity': 'محبوبیت',
      'atelUsage': 'استفاده',
      'atelBuildTime': 'زمان ساخت',
      'atelOutputType': 'نوع خروجی:',
      'atelProOptions': 'شخصی‌سازی‌های هوش مصنوعی (Pro Options)',
      'atelGuarantee': 'ضمانت رضایت: اگر ساخت ناموفق باشد، سکه بازگردانده شده و یک‌بار بازسازی رایگان خواهید داشت.',
      'atelConfirmTerms': 'می‌پذیرم که تصویر با چهره خودم ساخته می‌شود و نتیجه نهایی دارای برچسب رسمی «ساخته‌شده با هوش مصنوعی» خواهد بود.',
      'atelConfirmStart': 'تأیید و شروع ساخت',
      'atelDownload': 'دانلود',
      'atelRebuild': 'ساخت مجدد',
      'atelFreeRebuild': 'بازسازی رایگان',
      'atelPrivateLink': 'لینک خصوصی',
      'atelPublicLink': 'لینک عمومی فعال',
      'atelDeleteWork': 'حذف اثر',
      'atelRateQuality': 'کیفیت خروجی چطور بود؟',
      'wellPrivacyTooltip': 'حالت حریم خصوصی',
      'wellBeauty': 'زیبایی',
      'wellHealth': 'تندرستی',
      'wellMind': 'روان',
      'wellFutureYou': 'آینده شما',
      'wellInsightTitle': 'بینش امروز هوش مصنوعی',
      'wellInsightBody': 'بر اساس تحلیل چهره و داده‌های اخیر، رطوبت پوست شما مقداری کاهش یافته است. امروز مصرف آب و استفاده از آبرسان را در اولویت بگذارید.',
      'wellViewSkinRoutine': 'مشاهده روتین پوستی',
      'wellTodayActions': 'اقدام‌های امروز برای سلامتی',
      'wellTrend7Days': 'روند پیشرفت ۷ روز اخیر',
      'wellAutoUpdate': 'بروزرسانی خودکار',
      'wellMetricWeight': 'وزن',
      'wellMetricSleep': 'خواب',
      'wellMetricActivity': 'فعالیت',
      'wellMetricMood': 'خلق‌وخو',
      'wellMetricHeart': 'ضربان',
      'wellDailyCheckinBtn': 'ثبت اطلاعات و ارزیابی امروز',
      'wellChartHiddenPrivacy': 'داده‌ها در حالت حریم خصوصی پنهان هستند',
      'wellBeautySheetTitle': 'زیبایی، پوست و مو',
      'wellHealthSheetTitle': 'سلامت و تندرستی',
      'wellMindSheetTitle': 'ذهن و آرامش روان',
      'wellFutureSheetTitle': 'شبیه‌ساز خودِ آینده (Future Self)',
      'wellCheckinSheetTitle': 'ثبت اطلاعات روزانه سلامت',
      'wellClose': 'بستن',
      'wearableCardTitle': 'اتصال ساعت هوشمند و سلامت',
      'wearableStatusConnected': 'متصل',
      'wearableStatusDisconnected': 'قطع ارتباط',
      'wearableLastSynced': 'آخرین همگام‌سازی:',
      'wearableSyncNow': 'همگام‌سازی فوری',
      'wearableManagePermissions': 'مدیریت مجوزها',
      'wearableConsentTitle': 'تنظیمات حریم خصوصی و اتصال گجت',
      'wearableSourceDevice': 'گجت یا پلتفرم منبع',
      'wearablePermissionsSubtitle': 'کنترل تفکیک‌شده حریم خصوصی داده‌های بیومتریک ارسالی به هوش مصنوعی',
      'wearablePermSteps': 'گام‌ها و مسافت پیاده‌روی',
      'wearablePermSleep': 'خواب شبانه و کیفیت خواب عمیق',
      'wearablePermHeart': 'ضربان قلب لحظه‌ای و استراحت',
      'wearablePermWeight': 'ثبت وزن ترازوی هوشمند',
      'wearablePermCalories': 'کالری فعال روزانه',
      'wearableReadinessLabel': 'شاخص آمادگی انرژی:',
      'stylistBiometricBannerTitle': 'پیشنهاد هوشمند بر اساس سلامت شما',
      'stylistBiometricComfortHint': 'دیشب خواب کمتری ثبت شده؛ برای امروز استایل راحت و خنک با الیاف نرم پیشنهاد شده است.',
      'stylistBiometricActiveHint': 'تحرک امروز شما بالا بوده است؛ استایل لایه‌بندی تنفس‌پذیر با کفش ارگونومیک تنظیم شد.',
      // Auth strings
      'authGetStarted': 'شروع کنید',
      'authWelcomeTagline': 'پرو مجازی لباس • استایل شخصی با هوش مصنوعی',
      'authWelcomeDesc': 'قبل از خرید، لباس را روی تصویر خود امتحان کنید.\nست‌های مناسب پیدا کنید و سبک خود را بسازید.',
      'authLoginTitle': 'ورود به حساب کاربری',
      'authLoginSubtitle': 'برای استفاده از پرو مجازی وارد شوید',
      'authLoginBtn': 'ورود',
      'authSignupTitle': 'ثبت‌نام در StyleMorph',
      'authSignupSubtitle': 'یک حساب کاربری رایگان بسازید',
      'authSignupBtn': 'ثبت‌نام',
      'authEmailLabel': 'ایمیل',
      'authEmailHint': 'example@email.com',
      'authPasswordLabel': 'رمز عبور',
      'authPasswordHint': '••••••••',
      'authConfirmPasswordLabel': 'تکرار رمز عبور',
      'authConfirmPasswordHint': 'رمز عبور را مجدداً وارد کنید',
      'authOrWith': 'یا ورود با',
      'authSwitchToSignup': 'ثبت‌نام جدید',
      'authSwitchToLogin': 'از قبل حساب دارید؟  ورود',
      'authForgotPassword': 'فراموشی رمز عبور؟',
      'authForgotTitle': 'بازیابی رمز عبور',
      'authForgotSubtitle': 'ایمیل خود را وارد کنید تا لینک بازیابی برایتان ارسال شود',
      'authForgotBtn': 'ارسال لینک بازیابی',
      'authBackToLogin': 'بازگشت به ورود',
      'authPwStrengthLabel': 'قدرت رمز عبور',
      'authPwRuleLen': 'حداقل ۸ کاراکتر',
      'authPwRuleUpper': 'حداقل یک حرف بزرگ',
      'authPwRuleLower': 'حداقل یک حرف کوچک',
      'authPwRuleDigit': 'حداقل یک عدد',
      'authPwRuleSpecial': 'حداقل یک کاراکتر ویژه (!@#\$...)',
      'authPwMismatch': 'رمز عبور و تکرار آن یکسان نیستند',
      'authCopyrightYear': 'StyleMorph 2026 ©',
      // Auth Error & Feedback strings
      'authErrEmailAlreadyInUse': 'این ایمیل قبلاً در سیستم ثبت شده است.',
      'authErrWrongPassword': 'رمز عبور وارد شده نادرست است.',
      'authErrUserNotFound': 'حساب کاربری با این ایمیل یافت نشد.',
      'authErrInvalidEmail': 'فرمت آدرس ایمیل معتبر نیست.',
      'authErrUserDisabled': 'این حساب کاربری غیرفعال شده است.',
      'authErrWeakPassword': 'رمز عبور انتخابی بسیار ضعیف است.',
      'authErrNetwork': 'خطا در برقراری ارتباط با سرور. لطفاً اتصال اینترنت را بررسی کنید.',
      'authErrTooManyRequests': 'تعداد تلاش‌های ناموفق بیش از حد مجاز است. لطفاً کمی بعد تلاش کنید.',
      'authErrInvalidCredential': 'ایمیل یا رمز عبور نامعتبر است.',
      'authErrGoogleCancelled': 'ورود با حساب گوگل لغو شد.',
      'authErrAppleCancelled': 'ورود با حساب اپل لغو شد.',
      'authErrGeneric': 'خطایی در احراز هویت رخ داد. لطفاً مجدداً تلاش کنید.',
      'authResetEmailSent': 'لینک بازیابی رمز عبور به ایمیل شما ارسال شد.',
      // Sessions sub-tab
      'tSess': 'نشست‌ها',
      'sessHeader': 'نشست‌های فعال و دستگاه‌ها',
      'sessSubtitle': 'تمام دستگاه‌هایی که با حساب شما وارد شده‌اند را مشاهده و مدیریت کنید. برای امنیت بیشتر می‌توانید دسترسی دستگاه‌های غیرفعال را لغو کنید.',
      'sessTerminateAll': 'خروج از سایر دستگاه‌ها',
      'sessCurrentDevice': 'این دستگاه',
      'sessEmpty': 'هیچ نشست فعالی یافت نشد.',
      'sessPlatform': 'پلتفرم',
      'sessOs': 'سیستم‌عامل',
      'sessUserAgent': 'مرورگر / اپ',
      'sessLoginTime': 'زمان ورود',
      'sessLastActive': 'آخرین فعالیت',
      'sessDelete': 'حذف',
      'timeJustNow': 'همین الان',
      'timeMinutesAgo': '{n} دقیقه پیش',
      'timeHoursAgo': '{n} ساعت پیش',
      'timeDaysAgo': '{n} روز پیش',
      'sessPrimaryBadge': 'دستگاه اصلی (Master)',
      'sessBlockedBadge': 'مسدود شده',
      'sessBlockBtn': 'مسدودسازی',
      'sessUnblockBtn': 'رفع مسدودیت',
      'sessConfirmBlockTitle': 'مسدودسازی موقت دستگاه',
      'sessConfirmBlockMsg': 'آیا از مسدودسازی موقت دسترسی این دستگاه اطمینان دارید؟ نشست‌های فعال آن بلافاصله خارج خواهند شد.',
      'sessConfirmUnblockTitle': 'رفع مسدودیت دستگاه',
      'sessConfirmUnblockMsg': 'آیا مایل به رفع مسدودیت این دستگاه هستید؟ این دستگاه مجدداً امکان ورود خواهد داشت.',
      'sessConfirmDeleteTitle': 'حذف و لغو نشست',
      'sessConfirmDeleteMsg': 'آیا از خاتمه دادن و حذف این نشست اطمینان دارید؟',
      'sessConfirmTerminateAllTitle': 'خروج از سایر دستگاه‌ها',
      'sessConfirmTerminateAllMsg': 'آیا از خروج همزمان از تمامی دستگاه‌های دیگر اطمینان دارید؟ (دستگاه اصلی خارج نخواهد شد)',
      'sessDeviceBlockedNotice': 'دسترسی این دستگاه توسط دستگاه اصلی (Primary) موقتاً مسدود شده است.',
      'sessPrimaryOnlyNotice': 'فقط دستگاه اصلی مجاز به مدیریت یا مسدودسازی نشست‌ها می‌باشد.',
      'sessCopiedToast': 'شناسه نشست در کلیپ‌بورد کپی شد',
      'sessErrLoad': 'خطا در بارگذاری نشست‌ها',
      'dialogCancel': 'انصراف',
      'dialogConfirm': 'تأیید',
    },
    'en': {
      'appName': 'StyleMorph',
      'back': 'Back',
      'sub': 'Virtual try-on & style advice',
      'desc': 'Try clothes on your photo before you buy and find outfits that suit you.',
      'pers': 'Personal use',
      'biz': 'Business / Stores',
      'pT': 'Personal sign in',
      'pS': 'Sign in to use virtual try-on',
      'bT': 'Business sign in',
      'bS': 'Manage your storefront and try-on',
      'acc': 'Email or mobile',
      'pw': 'Password',
      'bid': 'Business registration ID',
      'go': 'Continue',
      'orText': 'or',
      'reg': 'Create new account',
      'forgot': 'Forgot password?',
      'nShop': 'Shop',
      'nWard': 'Wardrobe',
      'nSty': 'Stylist',
      'nAtel': 'Atelier',
      'nWell': 'Wellness',
      'nProf': 'Profile',
      'coin': 'Coins',
      'currencyUnit': 'Toman',
      'verif': 'Basic verification',
      'supT': 'Online Support',
      'supHi': 'Hello! How can I help you?',
      'supPh': 'Your message...',
      'search': 'Search clothes, shoes, accessories...',
      'filter': 'Filter',
      'allText': 'All',
      'soon': 'Soon',
      'mWal': 'Wallet & Plan',
      'mFav': 'Favorites',
      'mRef': 'Referral & Rewards',
      'mSet': 'Settings',
      'mHist': 'Try-on history',
      'mSaved': 'Saved outfits',
      'mOrders': 'Orders',
      'mAbout': 'About us',
      'mHelp': 'Help & support',
      'mSupport': 'Support & Help',
      'mOut': 'Sign out',
      'pcT': 'Profile completion',
      'tIdent': 'Identity',
      'tGal': 'Media',
      'tAi': 'Anatomy',
      'tWal': 'Wallet & Plan',
      'tRef': 'Rewards & Net',
      'tComp': 'Companion',
      'tSet': 'Settings',
      'hPlan': 'Basic',
      'hFin': 'Complete',
      'sendText': 'Send',
      'err': 'Failed to load. Check your connection or file path.',
      'userSa': 'Sara Ahmadi',
      'usernameSa': '@sara_ahmadi',
      'lvl1': 'Lv1',
      'coinsCount': '350',
      'profileCompletionPct': '40%',
      'wardrobeTitle': 'Virtual Wardrobe',
      'shopTitle': 'Fashion & Style Shop',
      'uploadItem': 'Upload Item',
      'planCapacity': 'Plan Capacity',
      'searchWardrobe': 'Search in wardrobe...',
      'clearFilters': 'Clear Filters',
      'tryOnShortcut': 'Try-On',
      'priceAlert': 'Price Alert',
      'compare': 'Compare',
      'fitForMe': 'Fit for Me',
      'matchWardrobe': 'Matches your wardrobe',
      'stylistTitle': 'Personal AI Stylist',
      'atelierTitle': 'AI Portrait & Fashion Studio',
      'wellnessTitle': 'Smart Wellness & Beauty',
      'virtualTryOn': 'Virtual Try-On',
      'myCreations': 'My Creations',
      'aiWatermarkBadge': 'Created with AI',
      'futureSelf': 'Future Self Simulator',
      'themeLight': 'Light Mode',
      'themeDark': 'Dark Mode',
      'themeSystem': 'Auto (Sync with System)',
      'drawerThemeLightTip': '☀️ Light',
      'drawerThemeDarkTip': '🌙 Dark',
      'drawerThemeSystemTip': '🔄 Auto (System)',
      'saveChanges': 'Save Changes',
      'noChangesYet': 'No changes made',
      'profileSavedToast': 'Profile changes saved successfully.',
      'notificationsTitle': 'Notification Center',
      'markAllRead': 'Mark all read ✓',
      'noNotifications': 'No notifications in this category.',
      'notifCatAi': 'AI & Atelier',
      'notifCatShop': 'Deals & Shop',
      'notifCatFinance': 'Wallet & Coins',
      'newWord': 'new',
      'idHeader': 'Identity & Personal Information',
      'idFirstName': 'First Name',
      'idLastName': 'Last Name',
      'idNick': 'Handle / Nickname',
      'idNationalId': 'National ID',
      'idMobile': 'Mobile Number',
      'idVerified': 'Verified',
      'idEmail': 'Email',
      'idSendCode': 'Send Code',
      'idCodeSentToast': 'Verification code sent to your email.',
      'idCountry': 'Country',
      'idProvince': 'Province',
      'idCity': 'City',
      'idAddress': 'Postal Address',
      'idZip': '10-Digit Postal Code',
      'galHeader': 'Media Album & Reference Photos',
      'galScan360': '360° Body Scan',
      'galUploaded': 'Uploaded',
      'galPlayToast': 'Playing 360° body scan video',
      'galBasePhotos': 'Base Face & Body Photos',
      'galUsedInAi': 'Used by AI engine',
      'galApproved': 'Verified',
      'galFullFront': 'Full Front',
      'galSideView': 'Side View',
      'galSlotAdded': 'Frame 3 selected successfully.',
      'galSlotRemoved': 'Frame 3 removed.',
      'galRecorded': 'Added',
      'galUploadSlot3': 'Upload Frame 3',
      'galTip': 'Reference photos are used to improve virtual try-on accuracy and body modeling.',
      'aiHeader': 'Anatomy & DNA Specs',
      'aiEditable': 'Editable',
      'aiNote': 'Values were extracted by AI. Editing any field switches its badge to USER.',
      'aiGender': 'Gender',
      'aiFemale': 'Female',
      'aiMale': 'Male',
      'aiHeight': 'Height (cm)',
      'aiWeight': 'Weight (kg)',
      'aiSkinTone': 'Skin Tone',
      'aiBodyShape': 'Body Shape',
      'aiFaceShape': 'Face Shape',
      'aiHair': 'Hair Profile',
      'aiTailoringHeader': 'Tailoring & Try-On Measurements',
      'aiShoulder': 'Shoulder Width (cm)',
      'aiChest': 'Chest (cm)',
      'aiWaist': 'Waist',
      'aiBelly': 'Abdomen',
      'aiHips': 'Hips',
      'walHeader': 'Wallet, Plans & Billing',
      'walActivePlan': 'Your Active Plan',
      'walActive': 'Active',
      'walMonthShort': 'T / mo',
      'walBuyCoins': 'Buy StyleCoin Top-Up Packs',
      'walPopular': 'Most Popular',
      'walPromoHint': 'Have a gift or promo code? (e.g. GIFT50)',
      'walApply': 'Apply',
      'walRecentTx': 'Recent Transactions',
      'walTxTopup': 'Online Wallet Top-Up',
      'walTxTopupTime': 'Today, 12:40',
      'walTxTryon': 'Smart AI Virtual Try-On',
      'walTxTryonTime': 'Yesterday, 18:20',
      'walPkg200': '200 + 20 Bonus',
      'walPromoToast': 'Promo code {code} applied (+{coins} added to balance!)',
      'walPlanToast': 'Your plan was successfully changed to {plan}.',
      'walCoinsAddedToast': '+{coins} added to your balance!',
      'refHeader': 'Referral Rewards & Network',
      'refInvited': 'Invited Friends',
      'refBonus': 'Earned Rewards',
      'refTier': 'Network Tier',
      'refLinkLabel': 'Your Personal Invite Link',
      'refCopy': 'Copy',
      'refCopiedToast': 'Invite link copied to clipboard!',
      'refJoinedTitle': 'Recently Joined Friends',
      'refRuleInfo': 'Earn 100 coins and gift 50 bonus coins for every friend who signs up.',
      'refMembersUnit': 'friends',
      'perHeader': 'AI Companion & Persona Settings',
      'perSub': 'Customize your AI companion character, conversation tone, and critique strictness.',
      'perSelectTitle': 'Select Companion Character',
      'perDefaultVoice': 'Default Voice:',
      'perCustomName': 'Custom Companion Name (Optional)',
      'perCustomNameHint': 'e.g. My Style Coach',
      'perToneSection': 'Conversation Style & Strictness',
      'perToneLabel': 'Response Tone & Personality',
      'perStrictness': 'Style Critique Strictness',
      'perRespLen': 'Response Length',
      'perVoiceSection': 'Voice & Visibility Preferences',
      'perScopeLabel': 'Where should Companion appear?',
      'perVoiceActive': 'Enable Companion Voice',
      'perSpeechSpeed': 'Speech Speed',
      'perSubtitle': 'Show Subtitles with Voice',
      'perDailyTip': 'Daily Style & Wellness Tip',
      'perSaveHistory': 'Save Companion Chat History',
      'perResetBtn': 'Reset to Default Settings',
      'setHeader': 'Settings & Customization',
      'setPaletteLabel': 'Fashion Theme Palette',
      'palWhite': 'Minimal White',
      'palBeige': 'Luxury Warm Beige',
      'palSlate': 'Modern Slate',
      'palObsidian': 'Obsidian Dark',
      'palEditorial': 'Luxury Editorial',
      'setBrightnessLabel': 'Brightness Mode (Light / Dark / System)',
      'setLangLabel': 'App Language',
      'setShowSupport': 'Show Floating Support Widget',
      'setShowHeaderCoins': 'Show Coin Balance in Header',
      'setBackupLabel': 'Auto Data Backup',
      'setBackupWeekly': 'Weekly (Recommended)',
      'setBackupMonthly': 'Monthly',
      'setBackupOff': 'Off',
      'setLogoutBtn': 'Sign Out of Account',
      'wardCatCl': 'Clothing',
      'wardCatSh': 'Shoes',
      'wardCatBg': 'Bags',
      'wardCatJw': 'Jewelry',
      'wardCatAc': 'Accessories',
      'wardItemUnit': 'items',
      'wardCapacityWord': 'capacity',
      'wardArchive': 'Archive',
      'wardArchiveEmpty': 'Archive is empty',
      'wardNotFound': 'No items found',
      'wardAddItem': 'Add Item',
      'wardAddSheetTitle': 'Add New Item to Wardrobe',
      'wardImgLoaded': 'Image uploaded successfully',
      'wardImgClick': 'Tap to upload garment photo',
      'wardImgToast': 'Image selected and AI extracted its attributes.',
      'wardItemName': 'Item Name',
      'wardItemNameHint': 'e.g. Navy blazer or linen trousers...',
      'wardCategory': 'Category',
      'wardSelectedColor': 'Selected Color',
      'wardSeason': 'Season',
      'wardOccasion': 'Occasion',
      'wardSaveInWardrobe': 'Save to Wardrobe',
      'wardFilterColor': 'Color',
      'wardSpecMainColor': 'Main Color',
      'wardSpecSeason': 'Season',
      'wardSpecMaterial': 'Material',
      'wardSpecSize': 'Size',
      'wardStyleInStylist': 'Style with AI Stylist',
      'wardUnarchive': 'Unarchive',
      'wardArchiveAction': 'Archive Item',
      'wardDeleteTitle': 'Delete Item',
      'wardDeleteFromWardrobe': 'Remove Item',
      'wardCancel': 'Cancel',
      'wardDelete': 'Delete',
      'wardSentStylistToast': '"{name}" sent to AI Stylist for outfit matching.',
      'wardDeleteConfirmMsg': 'Are you sure you want to delete "{name}" from your wardrobe?',
      'shopSub': 'Compare prices; buy in-app or visit the seller site',
      'shopSearchHint': 'Search products, brands, categories...',
      'shopCatCloth': 'Apparel',
      'shopCatShoe': 'Shoes',
      'shopCatBag': 'Bags',
      'shopCatAcc': 'Accessories',
      'shopCatBeauty': 'Beauty',
      'shopCatFav': 'Wishlist',
      'shopSortTitle': 'Sort By',
      'shopSortRel': 'Most Relevant',
      'shopSortLo': 'Lowest Price',
      'shopSortHi': 'Highest Price',
      'shopSortRt': 'Top Rated',
      'shopSortDc': 'Biggest Discount',
      'shopSortPrefix': 'Sort:',
      'shopFitMeBanner': 'Fit For Me Filter (Size M · Shoe 42)',
      'shopFitMeSub': 'Based on measurements saved in your AI DNA',
      'shopProductUnit': 'items',
      'shopEmpty': 'No products match these filters',
      'shopClearAllFilters': 'Clear All Filters',
      'shopClear': 'Clear',
      'shopDisclaimer': 'Prices and stock are illustrative. Exclusive StyleMorph and official dealer items ship with in-app guarantee; external purchases follow the seller’s policies.',
      'shopAppBadge': 'App',
      'shopOutOfStock': 'Out of Stock',
      'shopFromPrice': 'From',
      'shopStoreUnit': 'stores',
      'shopFilterTitle': 'Advanced Shop Filters',
      'shopSaleType': 'Purchase Method',
      'shopSaleApp': 'In-App Checkout',
      'shopSaleSite': 'Seller Website',
      'shopGender': 'Gender',
      'shopGenderW': 'Women',
      'shopGenderM': 'Men',
      'shopGenderU': 'Unisex',
      'shopMaxPriceNoLimit': 'Max Price: Unlimited',
      'shopMaxPrice': 'Max Price',
      'shopBrands': 'Brands',
      'shopToggleAvail': 'In-Stock Items Only',
      'shopToggleDisc': 'Discounted Items Only',
      'shopToggleVerified': 'Verified Sellers & App Only',
      'shopRemoveFilters': 'Reset',
      'shopApplyFilters': 'Apply Filters',
      'shopSellerSiteBtn': 'Seller Site',
      'shopCompareActive': 'Compared',
      'shopAlertActive': 'Alert On',
      'shopDiscountWord': 'OFF',
      'shopReviewUnit': 'reviews',
      'shopSellersTitle': 'Sellers & Price Comparison',
      'shopCheapest': 'Lowest',
      'shopDelivery': 'Delivery',
      'shopBuyInApp': 'In-App Purchase',
      'shopGoToSite': 'Visit Website',
      'shopProductSpecs': 'Product Specifications',
      'shopBrand': 'Brand',
      'shopMaterial': 'Material',
      'shopColorsLabel': 'Colors',
      'shopSizesLabel': 'Sizes',
      'shopViewOnSite': 'View & Buy on Seller Site',
      'shopBuyFromApp': 'Buy on StyleMorph',
      'shopFitTitle': 'Smart Fit Assessment (Fit for Me)',
      'shopFitSizeOk': 'Your profile size is in stock.',
      'shopFitColorsOk': 'Colors compatible with your skin undertone:',
      'shopWardrobeMatchTitle': 'Outfit Match: Pairs with your wardrobe',
      'shopTryOnDesc': 'This item will be sent to the AI fitting room to render onto your profile model.',
      'shopTryOnCost5': 'Processing Cost: 5 Coins',
      'shopSendToTryOn': 'Send to Virtual Fitting Room',
      'shopInsufficientCoins': 'Insufficient coins. Top up in Wallet & Plan.',
      'shopOfficialAgent': 'Verified Official Dealer',
      'shopIndSeller': 'Partner Independent Store',
      'shopRedirectBtn': 'Continue to Seller Website',
      'shopNoticeOut': 'You are leaving StyleMorph for the seller’s external website.',
      'shopNoticePay': 'All checkout and invoicing occur on the destination website.',
      'shopNoticeShield': 'Delivery and return policies follow the destination store rules.',
      'shopCompareCountMsg': '{count} items selected for comparison',
      'shopCompareReadyMsg': 'Comparison table ready for {count} items.',
      'shopTryOnSentToast': '"{name}" sent to AI Virtual Try-On ({coins} deducted).',
      'shopLeavingToast': 'You are leaving StyleMorph for "{store}" external website.',
      'shopRedirectToast': 'Redirecting to {store} website... (Demo mode)',
      'shopOrderPlacedToast': 'In-app order placed for "{name}".',
      'styWeather': '18°C Sunny',
      'styEnergy': 'Energy: Medium',
      'styMyPalette': 'My Palette',
      'styChatTitle': 'Ramin (Stylist)',
      'styChatBannerSub': 'This outfit fits today well; ask if you want changes.',
      'styPlanner': 'Planner',
      'styStyleColor': 'Style & Color',
      'stySmartShop': 'Smart Shop',
      'styStats': 'Style Stats',
      'styLocked': 'Locked',
      'styLock': 'Lock',
      'stySwap': 'Swap',
      'stySaved': 'Saved',
      'stySave': 'Save',
      'styTryOn': 'Try On',
      'stySwapToast': 'Alternative outfit calculated from your wardrobe.',
      'styChatFullTitle': 'Ramin (Personal AI Stylist)',
      'styAskHint': 'Ask your AI stylist...',
      'styDailyQuota': 'Free messages left today',
      'styTryOnDialogTitle': 'AI Virtual Fitting Room',
      'styQualityTierTitle': 'Select Try-On Quality Tier',
      'stySaveInAlbum': 'Save to My Album',
      'styTryOnTerms': 'I understand results are AI-estimated and rendered privately.',
      'styWeeklyPlanner': 'Weekly Style Planner',
      'styAddCalEvent': 'Add Calendar Event',
      'styStylePaletteTitle': 'My Style & Color Palette',
      'styUpdatePhotoBtn': 'Update from New Photo',
      'stySmartShoppingTitle': 'Smart Shopping (Wardrobe Gaps)',
      'styViewInShop': 'View These Items in Shop',
      'styStatsTitle': 'Style Analytics & Insights',
      'styGetReport': 'Download Full Monthly Report',
      'atelSub': 'Generate studio-grade portraits and fashion reels',
      'atelShowcase': 'Showcase',
      'atelCatPortrait': 'Portrait',
      'atelCatFashion': 'Fashion',
      'atelCatSeasonal': 'Seasonal',
      'atelCatTravel': 'Travel',
      'atelMediaAll': 'All Media',
      'atelMediaPhoto': 'Photos',
      'atelMediaVideo': 'Short Videos',
      'atelVideoBadge': 'Video',
      'atelPhotosUnit': 'photos',
      'atelSatisfaction': 'liked',
      'atelStatusReady': 'Ready',
      'atelStatusProcessing': 'In Progress',
      'atelStatusFailed': 'Failed',
      'atelEmptyCreations': 'No creations found in this filter.',
      'atelCoinsRefunded': 'Coins refunded',
      'atelRetryFree': 'Retry Free',
      'atelPopularity': 'Popularity',
      'atelUsage': 'Usage',
      'atelBuildTime': 'Render Time',
      'atelOutputType': 'Output Format:',
      'atelProOptions': 'AI Customization (Pro Options)',
      'atelGuarantee': 'Satisfaction Guarantee: Failed renders automatically refund coins and include one free retry.',
      'atelConfirmTerms': 'I agree the media uses my likeness and includes the official "Created with AI" badge.',
      'atelConfirmStart': 'Confirm & Start Generation',
      'atelDownload': 'Download',
      'atelRebuild': 'Regenerate',
      'atelFreeRebuild': 'Free Retry',
      'atelPrivateLink': 'Private Link',
      'atelPublicLink': 'Public Link Active',
      'atelDeleteWork': 'Delete Creation',
      'atelRateQuality': 'How was the output quality?',
      'wellPrivacyTooltip': 'Privacy Mode',
      'wellBeauty': 'Beauty',
      'wellHealth': 'Health',
      'wellMind': 'Mind',
      'wellFutureYou': 'Future You',
      'wellInsightTitle': "Today's AI Insight",
      'wellInsightBody': 'Based on recent skin & hydration tracking, prioritize water intake and morning moisturizer today.',
      'wellViewSkinRoutine': 'View Skincare Routine',
      'wellTodayActions': "Today's Wellness Checklist",
      'wellTrend7Days': '7-Day Progress Trend',
      'wellAutoUpdate': 'Auto-Synced',
      'wellMetricWeight': 'Weight',
      'wellMetricSleep': 'Sleep',
      'wellMetricActivity': 'Activity',
      'wellMetricMood': 'Mood',
      'wellMetricHeart': 'Heart Rate',
      'wellDailyCheckinBtn': 'Log Daily Health Check-In',
      'wellChartHiddenPrivacy': 'Data hidden in Privacy Mode',
      'wellBeautySheetTitle': 'Beauty, Skin & Hair',
      'wellHealthSheetTitle': 'Health & Fitness',
      'wellMindSheetTitle': 'Mindfulness & Calm',
      'wellFutureSheetTitle': 'Future Self Simulator',
      'wellCheckinSheetTitle': 'Daily Health Check-In',
      'wellClose': 'Close',
      'wearableCardTitle': 'Wearable & Health App Sync',
      'wearableStatusConnected': 'Connected',
      'wearableStatusDisconnected': 'Disconnected',
      'wearableLastSynced': 'Last synced:',
      'wearableSyncNow': 'Sync Now',
      'wearableManagePermissions': 'Permissions',
      'wearableConsentTitle': 'Health Data Permissions & Wearable',
      'wearableSourceDevice': 'Source Wearable / Platform',
      'wearablePermissionsSubtitle': 'Granular privacy control over biometric telemetry shared with AI',
      'wearablePermSteps': 'Steps & Walking Distance',
      'wearablePermSleep': 'Night Sleep & Deep Sleep Quality',
      'wearablePermHeart': 'Resting & Live Heart Rate',
      'wearablePermWeight': 'Smart Scale Body Weight',
      'wearablePermCalories': 'Active Burned Calories',
      'wearableReadinessLabel': 'Energy Readiness:',
      'stylistBiometricBannerTitle': 'Biometric-Aware Stylist Insight',
      'stylistBiometricComfortHint': 'Lower sleep detected last night; casual, soft, and breathable comfort fit recommended today.',
      'stylistBiometricActiveHint': 'High activity logged today; breathable layer styling with ergonomic footwear prioritized.',
      // Auth strings
      'authGetStarted': 'Get Started',
      'authWelcomeTagline': 'Virtual Try-On • AI Personal Stylist',
      'authWelcomeDesc': 'Try clothes on your photo before buying.\nFind your perfect outfits and define your style.',
      'authLoginTitle': 'Sign In',
      'authLoginSubtitle': 'Sign in to access virtual try-on',
      'authLoginBtn': 'Sign In',
      'authSignupTitle': 'Create an Account',
      'authSignupSubtitle': 'Create your free StyleMorph account',
      'authSignupBtn': 'Sign Up',
      'authEmailLabel': 'Email',
      'authEmailHint': 'example@email.com',
      'authPasswordLabel': 'Password',
      'authPasswordHint': '••••••••',
      'authConfirmPasswordLabel': 'Confirm Password',
      'authConfirmPasswordHint': 'Re-enter your password',
      'authOrWith': 'or continue with',
      'authSwitchToSignup': 'Create New Account',
      'authSwitchToLogin': 'Already have an account? Sign In',
      'authForgotPassword': 'Forgot Password?',
      'authForgotTitle': 'Reset Password',
      'authForgotSubtitle': 'Enter your email to receive a password reset link',
      'authForgotBtn': 'Send Reset Link',
      'authBackToLogin': 'Back to Sign In',
      'authPwStrengthLabel': 'Password Strength',
      'authPwRuleLen': 'At least 8 characters',
      'authPwRuleUpper': 'At least 1 uppercase letter',
      'authPwRuleLower': 'At least 1 lowercase letter',
      'authPwRuleDigit': 'At least 1 number',
      'authPwRuleSpecial': 'At least 1 special character (!@#\$...)',
      'authPwMismatch': 'Passwords do not match',
      'authCopyrightYear': 'StyleMorph 2026 ©',
      // Auth Error & Feedback strings
      'authErrEmailAlreadyInUse': 'This email address is already in use.',
      'authErrWrongPassword': 'The password entered is incorrect.',
      'authErrUserNotFound': 'No user account found for this email address.',
      'authErrInvalidEmail': 'The email address format is not valid.',
      'authErrUserDisabled': 'This user account has been disabled.',
      'authErrWeakPassword': 'The chosen password is too weak.',
      'authErrNetwork': 'Network error. Please check your internet connection.',
      'authErrTooManyRequests': 'Too many failed attempts. Please try again later.',
      'authErrInvalidCredential': 'Invalid email or password credential.',
      'authErrGoogleCancelled': 'Google sign in was cancelled.',
      'authErrAppleCancelled': 'Apple sign in was cancelled.',
      'authErrGeneric': 'Authentication failed. Please try again.',
      'authResetEmailSent': 'Password reset link has been sent to your email.',
      // Sessions sub-tab
      'tSess': 'Sessions',
      'sessHeader': 'Active Sessions & Devices',
      'sessSubtitle': 'View and manage all devices signed in to your account. Revoke access to inactive devices for better security.',
      'sessTerminateAll': 'Sign Out Other Devices',
      'sessCurrentDevice': 'This Device',
      'sessEmpty': 'No active sessions found.',
      'sessPlatform': 'Platform',
      'sessOs': 'OS',
      'sessUserAgent': 'Browser / App',
      'sessLoginTime': 'Login Time',
      'sessLastActive': 'Last Active',
      'sessDelete': 'Delete',
      'timeJustNow': 'Just now',
      'timeMinutesAgo': '{n}m ago',
      'timeHoursAgo': '{n}h ago',
      'timeDaysAgo': '{n}d ago',
      'sessPrimaryBadge': 'Primary Device',
      'sessBlockedBadge': 'Blocked',
      'sessBlockBtn': 'Block',
      'sessUnblockBtn': 'Unblock',
      'sessConfirmBlockTitle': 'Block Device Access',
      'sessConfirmBlockMsg': 'Are you sure you want to temporarily block this device? Its active sessions will be signed out immediately.',
      'sessConfirmUnblockTitle': 'Unblock Device Access',
      'sessConfirmUnblockMsg': 'Do you want to unblock this device? It will be allowed to sign in again.',
      'sessConfirmDeleteTitle': 'Revoke Session',
      'sessConfirmDeleteMsg': 'Are you sure you want to sign out and delete this session?',
      'sessConfirmTerminateAllTitle': 'Sign Out Other Devices',
      'sessConfirmTerminateAllMsg': 'Are you sure you want to sign out from all other devices? (Primary device will remain active)',
      'sessDeviceBlockedNotice': 'Access from this device has been temporarily blocked by the primary device.',
      'sessPrimaryOnlyNotice': 'Only the primary device is authorized to block or delete sessions.',
      'sessCopiedToast': 'Session ID copied to clipboard',
      'sessErrLoad': 'Failed to load sessions',
      'dialogCancel': 'Cancel',
      'dialogConfirm': 'Confirm',
    },
    'ar': {
      'appName': 'StyleMorph',
      'back': 'رجوع',
      'sub': 'القياس الافتراضي واقتراحات الأسلوب',
      'desc': 'جرّب الملابس على صورتك قبل الشراء واعثر على الإطلالات المناسبة لك.',
      'pers': 'استخدام شخصي',
      'biz': 'دخول الشركات / المتاجر',
      'pT': 'دخول المستخدم',
      'pS': 'سجّل الدخول لاستخدام القياس الافتراضي',
      'bT': 'دخول الشركات',
      'bS': 'إدارة واجهة المتجر والقياس الافتراضي',
      'acc': 'البريد أو رقم الجوال',
      'pw': 'كلمة المرور',
      'bid': 'رقم تسجيل النشاط',
      'go': 'متابعة',
      'orText': 'أو',
      'reg': 'إنشاء حساب جديد',
      'forgot': 'نسيت كلمة المرور؟',
      'nShop': 'المتجر',
      'nWard': 'الخزانة',
      'nSty': 'المنسّق',
      'nAtel': 'الأتيليه',
      'nWell': 'الصحة',
      'nProf': 'الملف',
      'coin': 'عملة',
      'currencyUnit': 'تومان',
      'verif': 'توثيق أساسي',
      'supT': 'الدعم المباشر',
      'supHi': 'مرحباً! كيف أساعدك؟',
      'supPh': 'رسالتك...',
      'search': 'ابحث عن ملابس، أحذية، إكسسوارات...',
      'filter': 'تصفية',
      'allText': 'الكل',
      'soon': 'قريباً',
      'mWal': 'المحفظة والخطة',
      'mFav': 'المفضلة',
      'mRef': 'المكافآت والدعوات',
      'mSet': 'الإعدادات',
      'mHist': 'سجل القياس',
      'mSaved': 'الإطلالات المحفوظة',
      'mOrders': 'الطلبات',
      'mAbout': 'معلومات عنا',
      'mHelp': 'المساعدة والدعم',
      'mSupport': 'الدعم والمساعدة',
      'mOut': 'تسجيل الخروج',
      'pcT': 'اكتمال الملف',
      'tIdent': 'الهوية',
      'tGal': 'الوسائط',
      'tAi': 'التشريح',
      'tWal': 'المحفظة والخطة',
      'tRef': 'المكافآت',
      'tComp': 'المرافق الذكي',
      'tSet': 'الإعدادات',
      'hPlan': 'عادي',
      'hFin': 'إكمال',
      'sendText': 'إرسال',
      'err': 'تعذّر التحميل. تحقق من الاتصال أو مسار الملف.',
      'userSa': 'سارة أحمدي',
      'usernameSa': '@sara_ahmadi',
      'lvl1': 'Lv1',
      'coinsCount': '٣٥٠',
      'profileCompletionPct': '٤٠٪',
      'wardrobeTitle': 'الخزانة الافتراضية',
      'shopTitle': 'متجر الأزياء والأناقة',
      'uploadItem': 'تحميل عنصر',
      'planCapacity': 'سعة الخطة',
      'searchWardrobe': 'البحث في الخزانة...',
      'clearFilters': 'مسح الفلاتر',
      'tryOnShortcut': 'جرّبها',
      'priceAlert': 'تنبيه السعر',
      'compare': 'مقارنة',
      'fitForMe': 'مناسب لك',
      'matchWardrobe': 'يتناسق مع خزانتك',
      'stylistTitle': 'منسق الأزياء الذكي',
      'atelierTitle': 'استوديو البورتريه والأزياء الذكي',
      'wellnessTitle': 'العافية والجمال الذكي',
      'virtualTryOn': 'القياس الافتراضي',
      'myCreations': 'إبداعاتي',
      'aiWatermarkBadge': 'صُنع بواسطة الذكاء الاصطناعي',
      'futureSelf': 'محاكي ذاتك المستقبلية',
      'themeLight': 'الوضع النهاري',
      'themeDark': 'الوضع الليلي',
      'themeSystem': 'تلقائي (متوافق مع النظام)',
      'drawerThemeLightTip': '☀️ نهاري',
      'drawerThemeDarkTip': '🌙 ليلي',
      'drawerThemeSystemTip': '🔄 تلقائي (النظام)',
      'saveChanges': 'حفظ التغييرات',
      'noChangesYet': 'لا توجد تغييرات',
      'profileSavedToast': 'تم حفظ تغييرات الملف بنجاح.',
      'notificationsTitle': 'مركز الإشعارات',
      'markAllRead': 'قراءة الكل ✓',
      'noNotifications': 'لا توجد إشعارات في هذه الفئة.',
      'notifCatAi': 'الذكاء الاصطناعي والأتيليه',
      'notifCatShop': 'العروض والمتجر',
      'notifCatFinance': 'المحفظة والعملات',
      'newWord': 'جديد',
      'idHeader': 'الهوية والمعلومات الشخصية',
      'idFirstName': 'الاسم الأول',
      'idLastName': 'اسم العائلة',
      'idNick': 'الاسم المستعار',
      'idNationalId': 'الرقم القومي',
      'idMobile': 'رقم الجوال',
      'idVerified': 'موثّق',
      'idEmail': 'البريد الإلكتروني',
      'idSendCode': 'إرسال الرمز',
      'idCodeSentToast': 'تم إرسال رمز التحقق إلى بريدك.',
      'idCountry': 'الدولة',
      'idProvince': 'المحافظة',
      'idCity': 'المدينة',
      'idAddress': 'العنوان البريدي',
      'idZip': 'الرمز البريدي (١٠ أرقام)',
      'galHeader': 'ألبوم الوسائط والصور المرجعية',
      'galScan360': 'مسح ٣٦٠ درجة للجسم',
      'galUploaded': 'تم التحميل',
      'galPlayToast': 'تشغيل فيديو المسح ٣٦٠ درجة',
      'galBasePhotos': 'صور الوجه والقوام الأساسية',
      'galUsedInAi': 'تُستخدم في الذكاء الاصطناعي',
      'galApproved': 'معتمد',
      'galFullFront': 'أمامي كامل',
      'galSideView': 'جانبي',
      'galSlotAdded': 'تم اختيار الإطار ٣ بنجاح.',
      'galSlotRemoved': 'تم حذف الإطار ٣.',
      'galRecorded': 'تم الحفظ',
      'galUploadSlot3': 'تحميل الإطار ٣',
      'galTip': 'تُستخدم الصور المرجعية لرفع دقة القياس الافتراضي وتحليل القوام.',
      'aiHeader': 'التشريح ومواصفات DNA',
      'aiEditable': 'قابل للتعديل',
      'aiNote': 'تم استخراج القيم بالذكاء الاصطناعي. تعديل أي حقل يغيّر وسْمه إلى USER.',
      'aiGender': 'الجنس',
      'aiFemale': 'نسائي (Female)',
      'aiMale': 'رجالي (Male)',
      'aiHeight': 'الطول (cm)',
      'aiWeight': 'الوزن (kg)',
      'aiSkinTone': 'لون البشرة',
      'aiBodyShape': 'شكل الجسم',
      'aiFaceShape': 'شكل الوجه',
      'aiHair': 'مواصفات الشعر',
      'aiTailoringHeader': 'مقاسات الخياطة والقياس الدقيق',
      'aiShoulder': 'عرض الكتف (cm)',
      'aiChest': 'محيط الصدر (cm)',
      'aiWaist': 'محيط الخصر',
      'aiBelly': 'محيط البطن',
      'aiHips': 'محيط الورك',
      'walHeader': 'المحفظة والخطط والفوترة',
      'walActivePlan': 'خطتك الحالية',
      'walActive': 'نشط',
      'walMonthShort': 'ت / شهر',
      'walBuyCoins': 'شراء باقات شحن StyleCoin',
      'walPopular': 'الأكثر شعبية',
      'walPromoHint': 'هل لديك كود خصم أو هدية؟ (مثل GIFT50)',
      'walApply': 'تطبيق',
      'walRecentTx': 'أحدث المعاملات',
      'walTxTopup': 'شحن المحفظة عبر الإنترنت',
      'walTxTopupTime': 'اليوم، ١٢:٤٠',
      'walTxTryon': 'القياس الافتراضي الذكي',
      'walTxTryonTime': 'أمس، ١٨:٢٠',
      'walPkg200': '٢٠٠ + ٢٠ هدية',
      'walPromoToast': 'تم تطبيق رمز الهدية {code} (+{coins} أضيفت إلى رصيدك!)',
      'walPlanToast': 'تم تغيير خطتك بنجاح إلى {plan}.',
      'walCoinsAddedToast': '+{coins} أضيفت إلى حسابك!',
      'refHeader': 'نظام المكافآت وشبكة الأصدقاء',
      'refInvited': 'الأصدقاء المدعوون',
      'refBonus': 'المكافآت المكتسبة',
      'refTier': 'مستوى الشبكة',
      'refLinkLabel': 'رابط الدعوة الخاص بك',
      'refCopy': 'نسخ',
      'refCopiedToast': 'تم نسخ رابط الدعوة!',
      'refJoinedTitle': 'أحدث الأصدقاء المنضمين لشبكتك',
      'refRuleInfo': 'احصل على ١٠٠ عملة و٥٠ عملة هدية لصديقك عند كل دعوة.',
      'refMembersUnit': 'أصدقاء',
      'perHeader': 'شخصية المرافق الذكي',
      'perSub': 'خصّص شخصية المساعد ونبرة الحديث ومستوى الصرامة في تقييم الأسلوب.',
      'perSelectTitle': 'اختيار شخصية المرافق',
      'perDefaultVoice': 'الصوت الافتراضي:',
      'perCustomName': 'اسم مخصص للمساعد (اختياري)',
      'perCustomNameHint': 'مثال: مستشار أناقتي',
      'perToneSection': 'أسلوب الحوار ومستوى الصرامة',
      'perToneLabel': 'نبرة الرد والأسلوب',
      'perStrictness': 'مستوى الصرامة في نقد الإطلالة',
      'perRespLen': 'طول الإجابات',
      'perVoiceSection': 'إعدادات الصوت والعرض',
      'perScopeLabel': 'أين يظهر المرافق الذكي؟',
      'perVoiceActive': 'تفعيل صوت المساعد',
      'perSpeechSpeed': 'سرعة الكلام',
      'perSubtitle': 'عرض النص متزامناً مع الصوت',
      'perDailyTip': 'نصيحة يومية للأناقة والعافية',
      'perSaveHistory': 'حفظ سجل المحادثات مع المساعد',
      'perResetBtn': 'استعادة الإعدادات الافتراضية',
      'setHeader': 'الإعدادات والتخصيص',
      'setPaletteLabel': 'لوحة الألوان والمظهر (Theme Palette)',
      'palWhite': 'أبيض بسيط (Minimal White)',
      'palBeige': 'بيج دافئ فاخر (Warm Beige)',
      'palSlate': 'رمادي عصري (Modern Slate)',
      'palObsidian': 'داكن أوبسيديان (Obsidian Dark)',
      'palEditorial': 'تحريري فاخر (Editorial Luxury)',
      'setBrightnessLabel': 'وضع الإضاءة (نهاري / ليلي / تلقائي)',
      'setLangLabel': 'لغة التطبيق',
      'setShowSupport': 'إظهار زر الدعم العائم',
      'setShowHeaderCoins': 'إظهار رصيد العملات في الرأس',
      'setBackupLabel': 'النسخ الاحتياطي التلقائي',
      'setBackupWeekly': 'أسبوعي (موصى به)',
      'setBackupMonthly': 'شهري',
      'setBackupOff': 'إيقاف',
      'setLogoutBtn': 'تسجيل الخروج من الحساب',
      'wardCatCl': 'ملابس',
      'wardCatSh': 'أحذية',
      'wardCatBg': 'حقائب',
      'wardCatJw': 'مجوهرات',
      'wardCatAc': 'إكسسوارات',
      'wardItemUnit': 'قطعة',
      'wardCapacityWord': 'السعة',
      'wardArchive': 'الأرشيف',
      'wardArchiveEmpty': 'الأرشيف فارغ',
      'wardNotFound': 'لم يتم العثور على عناصر',
      'wardAddItem': 'إضافة قطعة',
      'wardAddSheetTitle': 'إضافة قطعة جديدة للخزانة',
      'wardImgLoaded': 'تم تحميل الصورة بنجاح',
      'wardImgClick': 'اضغط لتحميل صورة القطعة',
      'wardImgToast': 'تم اختيار الصورة واستخرج الذكاء الاصطناعي خصائصها.',
      'wardItemName': 'اسم القطعة',
      'wardItemNameHint': 'مثال: بليزر كحلي أو بنطال كتان...',
      'wardCategory': 'الفئة',
      'wardSelectedColor': 'اللون المختار',
      'wardSeason': 'الموسم',
      'wardOccasion': 'المناسبة',
      'wardSaveInWardrobe': 'حفظ في الخزانة',
      'wardFilterColor': 'اللون',
      'wardSpecMainColor': 'اللون الأساسي',
      'wardSpecSeason': 'الموسم المناسب',
      'wardSpecMaterial': 'الخامة / القماش',
      'wardSpecSize': 'المقاس',
      'wardStyleInStylist': 'تنسيق مع المنسّق الذكي',
      'wardUnarchive': 'إخراج من الأرشيف',
      'wardArchiveAction': 'أرشفة القطعة',
      'wardDeleteTitle': 'حذف القطعة',
      'wardDeleteFromWardrobe': 'حذف من الخزانة',
      'wardCancel': 'إلغاء',
      'wardDelete': 'حذف',
      'wardSentStylistToast': 'تم إرسال «{name}» إلى منسق الأزياء لاقتراح إطلالات.',
      'wardDeleteConfirmMsg': 'هل أنت متأكد من حذف «{name}» من الخزانة؟',
      'shopSub': 'قارن الأسعار؛ اشترِ من التطبيق أو انتقل لموقع البائع',
      'shopSearchHint': 'ابحث عن منتج، ماركة، فئة...',
      'shopCatCloth': 'أزياء',
      'shopCatShoe': 'أحذية',
      'shopCatBag': 'حقائب',
      'shopCatAcc': 'إكسسوارات',
      'shopCatBeauty': 'جمال',
      'shopCatFav': 'المفضلة',
      'shopSortTitle': 'الترتيب حسب',
      'shopSortRel': 'الأكثر صلة',
      'shopSortLo': 'الأقل سعراً',
      'shopSortHi': 'الأعلى سعراً',
      'shopSortRt': 'الأعلى تقييماً',
      'shopSortDc': 'أكبر خصم',
      'shopSortPrefix': 'الترتيب:',
      'shopFitMeBanner': 'فلتر مناسب لي (مقاس M · حذاء ٤٢)',
      'shopFitMeSub': 'بناءً على مقاساتك المحفوظة في الهوية',
      'shopProductUnit': 'منتج',
      'shopEmpty': 'لا توجد منتجات مطابقة لهذه الفلاتر',
      'shopClearAllFilters': 'مسح جميع الفلاتر',
      'shopClear': 'مسح',
      'shopDisclaimer': 'الأسعار والمخزون للعرض التوضيحي. تشمل مشتريات StyleMorph ضمان التطبيق، بينما تتبع المشتريات الخارجية سياسة المتجر.',
      'shopAppBadge': 'التطبيق',
      'shopOutOfStock': 'غير متوفر',
      'shopFromPrice': 'من',
      'shopStoreUnit': 'متاجر',
      'shopFilterTitle': 'فلاتر المتجر المتقدمة',
      'shopSaleType': 'طريقة الشراء',
      'shopSaleApp': 'شراء داخل التطبيق',
      'shopSaleSite': 'موقع البائع',
      'shopGender': 'الجنس',
      'shopGenderW': 'نسائي',
      'shopGenderM': 'رجالي',
      'shopGenderU': 'للجنسين',
      'shopMaxPriceNoLimit': 'أقصى سعر: غير محدود',
      'shopMaxPrice': 'أقصى سعر',
      'shopBrands': 'العلامات التجارية',
      'shopToggleAvail': 'المتوفر فقط',
      'shopToggleDisc': 'العروض والخصومات فقط',
      'shopToggleVerified': 'البائعون الموثقون فقط',
      'shopRemoveFilters': 'إعادة ضبط',
      'shopApplyFilters': 'تطبيق الفلاتر',
      'shopSellerSiteBtn': 'موقع البائع',
      'shopCompareActive': 'في المقارنة',
      'shopAlertActive': 'التنبيه مفعل',
      'shopDiscountWord': 'خصم',
      'shopReviewUnit': 'تقييم',
      'shopSellersTitle': 'البائعون ومقارنة الأسعار',
      'shopCheapest': 'الأرخص',
      'shopDelivery': 'التوصيل',
      'shopBuyInApp': 'شراء داخل التطبيق',
      'shopGoToSite': 'الذهاب للموقع',
      'shopProductSpecs': 'مواصفات المنتج',
      'shopBrand': 'الماركة',
      'shopMaterial': 'الخامة',
      'shopColorsLabel': 'الألوان',
      'shopSizesLabel': 'المقاسات',
      'shopViewOnSite': 'عرض وشراء في موقع البائع',
      'shopBuyFromApp': 'شراء من StyleMorph',
      'shopFitTitle': 'تقييم التناسب الذكي (مناسب لك)',
      'shopFitSizeOk': 'المقاس المطابق لملفك متوفر.',
      'shopFitColorsOk': 'ألوان متوافقة مع لون بشرتك:',
      'shopWardrobeMatchTitle': 'اقتراح تنسيق: يتناغم مع خزانتك',
      'shopTryOnDesc': 'سيتم إرسال هذا المنتج إلى غرفة القياس الذكية لعرضه على صورتك.',
      'shopTryOnCost5': 'تكلفة المعالجة: ٥ عملات',
      'shopSendToTryOn': 'إرسال لغرفة القياس الافتراضي',
      'shopInsufficientCoins': 'رصيدك غير كافٍ. اشحن من المحفظة.',
      'shopOfficialAgent': 'وكيل رسمي معتمد',
      'shopIndSeller': 'متجر شريك مستقل',
      'shopRedirectBtn': 'الدخول لموقع البائع',
      'shopNoticeOut': 'أنت على وشك مغادرة StyleMorph إلى موقع البائع.',
      'shopNoticePay': 'تتم جميع عمليات الدفع والفوترة في الموقع الوجهة.',
      'shopNoticeShield': 'تخضع سياسات التوصيل والاسترجاع لقوانين المتجر.',
      'shopCompareCountMsg': 'تم تحديد {count} منتجات للمقارنة',
      'shopCompareReadyMsg': 'تم تجهيز جدول المقارنة لـ {count} منتجات.',
      'shopTryOnSentToast': 'تم إرسال «{name}» لغرفة القياس بالذكاء الاصطناعي (خُصم {coins}).',
      'shopLeavingToast': 'أنت على وشك مغادرة StyleMorph إلى موقع «{store}».',
      'shopRedirectToast': 'جاري التوجيه لموقع متجر {store}... (وضع تجريبي)',
      'shopOrderPlacedToast': 'تم تسجيل الطلب داخل التطبيق لـ «{name}».',
      'styWeather': '١٨° مشمس',
      'styEnergy': 'الطاقة: متوسطة',
      'styMyPalette': 'لوحتي',
      'styChatTitle': 'رامين (المنسّق)',
      'styChatBannerSub': 'هذه الإطلالة مثالية لليوم؛ اسألني لو أردت تعديلاً.',
      'styPlanner': 'المخطط',
      'styStyleColor': 'الأسلوب واللون',
      'stySmartShop': 'تسوق ذكي',
      'styStats': 'إحصاءات الأناقة',
      'styLocked': 'مقفل',
      'styLock': 'قفل',
      'stySwap': 'بديل',
      'stySaved': 'محفوظ',
      'stySave': 'حفظ',
      'styTryOn': 'قياس',
      'stySwapToast': 'تم حساب تنسيق بديل من خزانتك.',
      'styChatFullTitle': 'رامين (منسق الأزياء الشخصي الذكي)',
      'styAskHint': 'اسأل منسق الأزياء...',
      'styDailyQuota': 'الرسائل المجانية المتبقية اليوم',
      'styTryOnDialogTitle': 'غرفة القياس الافتراضي الذكية',
      'styQualityTierTitle': 'اختر مستوى جودة القياس',
      'stySaveInAlbum': 'حفظ في ألبومي',
      'styTryOnTerms': 'أقرّ بأن النتائج تقديرية وتتم معالجتها بخصوصية تامة.',
      'styWeeklyPlanner': 'مخطط الأناقة الأسبوعي',
      'styAddCalEvent': 'إضافة حدث تقويم',
      'styStylePaletteTitle': 'أسلوبي ولوحة الألوان',
      'styUpdatePhotoBtn': 'تحديث من صورة جديدة',
      'stySmartShoppingTitle': 'التسوق الذكي (نواقص الخزانة)',
      'styViewInShop': 'عرض هذه القطع في المتجر',
      'styStatsTitle': 'إحصاءات ورؤى الأناقة',
      'styGetReport': 'تنزيل التقرير الشهري الكامل',
      'atelSub': 'أنشئ صوراً ومقاطع أزياء احترافية بجودة الاستوديو',
      'atelShowcase': 'المعرض',
      'atelCatPortrait': 'بورتريه',
      'atelCatFashion': 'موضة',
      'atelCatSeasonal': 'موسمي',
      'atelCatTravel': 'سفر',
      'atelMediaAll': 'كل الوسائط',
      'atelMediaPhoto': 'صور وبورتريه',
      'atelMediaVideo': 'فيديو قصير',
      'atelVideoBadge': 'فيديو',
      'atelPhotosUnit': 'صور',
      'atelSatisfaction': 'إعجاب',
      'atelStatusReady': 'جاهز',
      'atelStatusProcessing': 'قيد الإنشاء',
      'atelStatusFailed': 'فشل',
      'atelEmptyCreations': 'لا توجد أعمال في هذه الفئة.',
      'atelCoinsRefunded': 'تم رد العملات',
      'atelRetryFree': 'إعادة مجانية',
      'atelPopularity': 'الشعبية',
      'atelUsage': 'الاستخدام',
      'atelBuildTime': 'وقت الإنشاء',
      'atelOutputType': 'نوع المخرج:',
      'atelProOptions': 'تخصيصات الذكاء الاصطناعي',
      'atelGuarantee': 'ضمان الرضا: يتم رد العملات تلقائياً عند الفشل مع محاولة إعادة مجانية.',
      'atelConfirmTerms': 'أوافق على إنشاء المحتوى بملامحي مع شارة «صُنع بواسطة الذكاء الاصطناعي».',
      'atelConfirmStart': 'تأكيد وبدء الإنشاء',
      'atelDownload': 'تحميل',
      'atelRebuild': 'إعادة إنشاء',
      'atelFreeRebuild': 'إعادة مجانية',
      'atelPrivateLink': 'رابط خاص',
      'atelPublicLink': 'رابط عام مفعل',
      'atelDeleteWork': 'حذف العمل',
      'atelRateQuality': 'ما تقييمك لجودة المخرج؟',
      'wellPrivacyTooltip': 'وضع الخصوصية',
      'wellBeauty': 'الجمال',
      'wellHealth': 'العافية',
      'wellMind': 'النفسية',
      'wellFutureYou': 'ذاتك المستقبلية',
      'wellInsightTitle': 'رؤية الذكاء الاصطناعي اليوم',
      'wellInsightBody': 'بناءً على متابعة البشرة والترطيب، احرص اليوم على شرب الماء واستخدام المرطب الصباحي.',
      'wellViewSkinRoutine': 'عرض روتين العناية بالبشرة',
      'wellTodayActions': 'مهام الصحة اليوم',
      'wellTrend7Days': 'مؤشر التقدم لآخر ٧ أيام',
      'wellAutoUpdate': 'تحديث تلقائي',
      'wellMetricWeight': 'الوزن',
      'wellMetricSleep': 'النوم',
      'wellMetricActivity': 'النشاط',
      'wellMetricMood': 'المزاج',
      'wellMetricHeart': 'النبض',
      'wellDailyCheckinBtn': 'تسجيل الحالة الصحية اليوم',
      'wellChartHiddenPrivacy': 'البيانات مخفية في وضع الخصوصية',
      'wellBeautySheetTitle': 'الجمال والبشرة والشعر',
      'wellHealthSheetTitle': 'الصحة واللياقة',
      'wellMindSheetTitle': 'الذهن والهدوء النفسي',
      'wellFutureSheetTitle': 'محاكي ذاتك المستقبلية',
      'wellCheckinSheetTitle': 'تسجيل الحالة اليومية',
      'wellClose': 'إغلاق',
      'wearableCardTitle': 'مزامنة السوار الذكي وتطبيق الصحة',
      'wearableStatusConnected': 'متصل',
      'wearableStatusDisconnected': 'غير متصل',
      'wearableLastSynced': 'آخر مزامنة:',
      'wearableSyncNow': 'مزامنة فورية',
      'wearableManagePermissions': 'إدارة الأذونات',
      'wearableConsentTitle': 'أذونات البيانات الصحية والسوار الذكي',
      'wearableSourceDevice': 'الجهاز أو المنصة المصدر',
      'wearablePermissionsSubtitle': 'تحكم دقيق في خصوصية القياسات الحيوية المشتركة مع الذكاء الاصطناعي',
      'wearablePermSteps': 'الخطوات والمسافة المقطوعة',
      'wearablePermSleep': 'النوم الليلي وجودة النوم العميق',
      'wearablePermHeart': 'معدل نبضات القلب والراحة',
      'wearablePermWeight': 'وزن الميزان الذكي',
      'wearablePermCalories': 'السعرات الحرارية النشطة',
      'wearableReadinessLabel': 'مؤشر جاهزية الطاقة:',
      'stylistBiometricBannerTitle': 'اقتراح مخصص حسب بياناتك الصحية',
      'stylistBiometricComfortHint': 'تم تسجيل ساعات نوم أقل الليلة الماضية؛ نقترح زياً مريحاً وخفيفاً بأقمشة ناعمة اليوم.',
      'stylistBiometricActiveHint': 'نشاطك الحركي اليوم مرتفع؛ تم إعطاء الأولوية للأقمشة القابلة للتنفس والأحذية المريحة.',
      // Auth strings
      'authGetStarted': 'ابدأ الآن',
      'authWelcomeTagline': 'القياس الافتراضي • منسق المظهر الذكي',
      'authWelcomeDesc': 'جرّب الملابس على صورتك قبل الشراء.\nاكتشف الإطلالات المثالية وصمّم أسلوبك الخاص.',
      'authLoginTitle': 'تسجيل الدخول',
      'authLoginSubtitle': 'سجّل الدخول لاستخدام القياس الافتراضي',
      'authLoginBtn': 'دخول',
      'authSignupTitle': 'إنشاء حساب جديد',
      'authSignupSubtitle': 'أنشئ حسابك المجاني في StyleMorph',
      'authSignupBtn': 'تسجيل جديد',
      'authEmailLabel': 'البريد الإلكتروني',
      'authEmailHint': 'example@email.com',
      'authPasswordLabel': 'كلمة المرور',
      'authPasswordHint': '••••••••',
      'authConfirmPasswordLabel': 'تأكيد كلمة المرور',
      'authConfirmPasswordHint': 'أعد إدخال كلمة المرور',
      'authOrWith': 'أو المتابعة عبر',
      'authSwitchToSignup': 'تسجيل حساب جديد',
      'authSwitchToLogin': 'لديك حساب بالفعل؟ تسجيل الدخول',
      'authForgotPassword': 'نسيت كلمة المرور؟',
      'authForgotTitle': 'استعادة كلمة المرور',
      'authForgotSubtitle': 'أدخل بريدك الإلكتروني لتلقي رابط إعادة التعيين',
      'authForgotBtn': 'إرسال رابط الاستعادة',
      'authBackToLogin': 'العودة لتسجيل الدخول',
      'authPwStrengthLabel': 'قوة كلمة المرور',
      'authPwRuleLen': '٨ أحرف على الأقل',
      'authPwRuleUpper': 'حرف كبير واحد على الأقل',
      'authPwRuleLower': 'حرف صغير واحد على الأقل',
      'authPwRuleDigit': 'رقم واحد على الأقل',
      'authPwRuleSpecial': 'رمز خاص واحد على الأقل (!@#\$...)',
      'authPwMismatch': 'كلمتا المرور غير متطابقتين',
      'authCopyrightYear': 'StyleMorph 2026 ©',
      // Auth Error & Feedback strings
      'authErrEmailAlreadyInUse': 'عنوان البريد الإلكتروني هذا مستخدم بالفعل.',
      'authErrWrongPassword': 'كلمة المرور المدخلة غير صحيحة.',
      'authErrUserNotFound': 'لم يتم العثور على حساب بهذا البريد الإلكتروني.',
      'authErrInvalidEmail': 'صيغة البريد الإلكتروني غير صالحة.',
      'authErrUserDisabled': 'تم تعطيل هذا الحساب.',
      'authErrWeakPassword': 'كلمة المرور ضعيفة جداً.',
      'authErrNetwork': 'خطأ في الشبكة. يرجى التحقق من اتصالك بالإنترنت.',
      'authErrTooManyRequests': 'محاولات كثيرة غير ناجحة. يرجى المحاولة لاحقاً.',
      'authErrInvalidCredential': 'بيانات الاعتماد غير صالحة.',
      'authErrGoogleCancelled': 'تم إلغاء تسجيل الدخول عبر Google.',
      'authErrAppleCancelled': 'تم إلغاء تسجيل الدخول عبر Apple.',
      'authErrGeneric': 'حدث خطأ في المصادقة. يرجى إعادة المحاولة.',
      'authResetEmailSent': 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.',
      // Sessions sub-tab
      'tSess': 'الجلسات',
      'sessHeader': 'الجلسات والأجهزة النشطة',
      'sessSubtitle': 'عرض وإدارة جميع الأجهزة المسجّل دخولها إلى حسابك. يمكنك إلغاء وصول الأجهزة غير النشطة لمزيد من الأمان.',
      'sessTerminateAll': 'تسجيل الخروج من الأجهزة الأخرى',
      'sessCurrentDevice': 'هذا الجهاز',
      'sessEmpty': 'لا توجد جلسات نشطة.',
      'sessPlatform': 'المنصة',
      'sessOs': 'نظام التشغيل',
      'sessUserAgent': 'المتصفح / التطبيق',
      'sessLoginTime': 'وقت الدخول',
      'sessLastActive': 'آخر نشاط',
      'sessDelete': 'حذف',
      'timeJustNow': 'الآن',
      'timeMinutesAgo': 'منذ {n} دقيقة',
      'timeHoursAgo': 'منذ {n} ساعة',
      'timeDaysAgo': 'منذ {n} يوم',
      'sessPrimaryBadge': 'الجهاز الرئيسي',
      'sessBlockedBadge': 'محظور',
      'sessBlockBtn': 'حظر',
      'sessUnblockBtn': 'إلغاء الحظر',
      'sessConfirmBlockTitle': 'حظر وصول الجهاز',
      'sessConfirmBlockMsg': 'هل أنت متأكد من حظر وصول هذا الجهاز مؤقتاً؟ سيتم تسجيل خروج جلساته فوراً.',
      'sessConfirmUnblockTitle': 'إلغاء حظر الجهاز',
      'sessConfirmUnblockMsg': 'هل تريد إلغاء حظر هذا الجهاز؟ سيتمكن من تسجيل الدخول مجدداً.',
      'sessConfirmDeleteTitle': 'إلغاء الجلسة',
      'sessConfirmDeleteMsg': 'هل أنت متأكد من تسجيل الخروج وحذف هذه الجلسة؟',
      'sessConfirmTerminateAllTitle': 'تسجيل الخروج من الأجهزة الأخرى',
      'sessConfirmTerminateAllMsg': 'هل أنت متأكد من تسجيل الخروج من جميع الأجهزة الأخرى؟ (لن يتأثر الجهاز الرئيسي)',
      'sessDeviceBlockedNotice': 'تم حظر وصول هذا الجهاز مؤقتاً بواسطة الجهاز الرئيسي.',
      'sessPrimaryOnlyNotice': 'فقط الجهاز الرئيسي مصرح له بحظر أو حذف الجلسات.',
      'sessCopiedToast': 'تم نسخ معرّف الجلسة إلى الحافظة',
      'sessErrLoad': 'فشل في تحميل الجلسات',
      'dialogCancel': 'إلغاء',
      'dialogConfirm': 'تأكيد',
    },
    'tr': {
      'appName': 'StyleMorph',
      'back': 'Geri',
      'sub': 'Sanal deneme ve stil önerileri',
      'desc': 'Satın almadan önce kıyafetleri fotoğrafınızda deneyin, size uygun kombinleri bulun.',
      'pers': 'Kişisel kullanım',
      'biz': 'Kurumsal / Mağazalar',
      'pT': 'Kullanıcı girişi',
      'pS': 'Sanal deneme için giriş yapın',
      'bT': 'Kurumsal giriş',
      'bS': 'Vitrin ve sanal denemeyi yönetin',
      'acc': 'E-posta veya telefon',
      'pw': 'Şifre',
      'bid': 'İşletme kayıt no',
      'go': 'Devam',
      'orText': 'veya',
      'reg': 'Yeni hesap oluştur',
      'forgot': 'Şifreni mi unuttun?',
      'nShop': 'Mağaza',
      'nWard': 'Gardırop',
      'nSty': 'Stilist',
      'nAtel': 'Stüdyo',
      'nWell': 'Sağlık',
      'nProf': 'Profil',
      'coin': 'Jeton',
      'currencyUnit': 'Toman',
      'verif': 'Temel doğrulama',
      'supT': 'Canlı Destek',
      'supHi': 'Merhaba! Nasıl yardımcı olabilirim?',
      'supPh': 'Mesajınız...',
      'search': 'Kıyafet, ayakkabı, aksesuar ara...',
      'filter': 'Filtrele',
      'allText': 'Tümü',
      'soon': 'Yakında',
      'mWal': 'Cüzdan & Plan',
      'mFav': 'Favorilerim',
      'mRef': 'Davet ve Ödüller',
      'mSet': 'Ayarlar',
      'mHist': 'Deneme geçmişi',
      'mSaved': 'Kayıtlı kombinler',
      'mOrders': 'Siparişler',
      'mAbout': 'Hakkımızda',
      'mHelp': 'Yardım ve Destek',
      'mSupport': 'Destek ve Yardım',
      'mOut': 'Çıkış yap',
      'pcT': 'Profil doluluğu',
      'tIdent': 'Kimlik',
      'tGal': 'Medya',
      'tAi': 'Anatomi',
      'tWal': 'Cüzdan & Plan',
      'tRef': 'Ödüller & Ağ',
      'tComp': 'Asistan',
      'tSet': 'Ayarlar',
      'hPlan': 'Temel',
      'hFin': 'Tamamla',
      'sendText': 'Gönder',
      'err': 'Yüklenemedi. Bağlantıyı veya dosya yolunu kontrol edin.',
      'userSa': 'Sara Ahmadi',
      'usernameSa': '@sara_ahmadi',
      'lvl1': 'Lv1',
      'coinsCount': '350',
      'profileCompletionPct': '40%',
      'wardrobeTitle': 'Sanal Gardırop',
      'shopTitle': 'Moda ve Stil Mağazası',
      'uploadItem': 'Öğe Yükle',
      'planCapacity': 'Plan Kapasitesi',
      'searchWardrobe': 'Gardıropta ara...',
      'clearFilters': 'Filtreleri Temizle',
      'tryOnShortcut': 'Dene',
      'priceAlert': 'Fiyat Uyarısı',
      'compare': 'Karşılaştır',
      'fitForMe': 'Bana Uygun',
      'matchWardrobe': 'Gardırobunla uyumlu',
      'stylistTitle': 'Kişisel Yapay Zeka Stilisti',
      'atelierTitle': 'Yapay Zeka Portre ve Moda Stüdyosu',
      'wellnessTitle': 'Akıllı Zindelik ve Güzellik',
      'virtualTryOn': 'Sanal Deneme',
      'myCreations': 'Tasarımlarım',
      'aiWatermarkBadge': 'Yapay Zeka ile Üretildi',
      'futureSelf': 'Gelecekteki Ben Simülatörü',
      'themeLight': 'Açık Tema',
      'themeDark': 'Koyu Tema',
      'themeSystem': 'Otomatik (Sistem)',
      'drawerThemeLightTip': '☀️ Açık',
      'drawerThemeDarkTip': '🌙 Koyu',
      'drawerThemeSystemTip': '🔄 Otomatik (Sistem)',
      'saveChanges': 'Değişiklikleri Kaydet',
      'noChangesYet': 'Değişiklik yok',
      'profileSavedToast': 'Profil değişiklikleri kaydedildi.',
      'notificationsTitle': 'Bildirim Merkezi',
      'markAllRead': 'Tümünü oku ✓',
      'noNotifications': 'Bu kategoride bildirim yok.',
      'notifCatAi': 'Yapay Zeka & Stüdyo',
      'notifCatShop': 'Fırsatlar & Mağaza',
      'notifCatFinance': 'Cüzdan & Jeton',
      'newWord': 'yeni',
      'idHeader': 'Kimlik ve Kişisel Bilgiler',
      'idFirstName': 'Ad',
      'idLastName': 'Soyad',
      'idNick': 'Kullanıcı Adı',
      'idNationalId': 'Kimlik No',
      'idMobile': 'Cep Telefonu',
      'idVerified': 'Doğrulandı',
      'idEmail': 'E-posta',
      'idSendCode': 'Kod Gönder',
      'idCodeSentToast': 'Doğrulama kodu e-postanıza gönderildi.',
      'idCountry': 'Ülke',
      'idProvince': 'İl',
      'idCity': 'Şehir',
      'idAddress': 'Açık Adres',
      'idZip': '10 Haneli Posta Kodu',
      'galHeader': 'Medya Albümü ve Referanslar',
      'galScan360': '360° Vücut Taraması',
      'galUploaded': 'Yüklendi',
      'galPlayToast': '360° vücut tarama videosu oynatılıyor',
      'galBasePhotos': 'Temel Yüz ve Vücut Fotoğrafları',
      'galUsedInAi': 'Yapay Zeka tarafından kullanılır',
      'galApproved': 'Onaylı',
      'galFullFront': 'Tam Ön',
      'galSideView': 'Yan Profil',
      'galSlotAdded': '3. kare başarıyla seçildi.',
      'galSlotRemoved': '3. kare kaldırıldı.',
      'galRecorded': 'Eklendi',
      'galUploadSlot3': 'Kare 3 Yükle',
      'galTip': 'Referans fotoğraflar sanal deneme ve vücut analizi doğruluğunu artırır.',
      'aiHeader': 'Anatomi ve DNA Ölçüleri',
      'aiEditable': 'Düzenlenebilir',
      'aiNote': 'Değerler Yapay Zeka ile çıkarıldı. Düzenlenen alan USER olarak işaretlenir.',
      'aiGender': 'Cinsiyet',
      'aiFemale': 'Kadın (Female)',
      'aiMale': 'Erkek (Male)',
      'aiHeight': 'Boy (cm)',
      'aiWeight': 'Kilo (kg)',
      'aiSkinTone': 'Cilt Tonu',
      'aiBodyShape': 'Vücut Tipi',
      'aiFaceShape': 'Yüz Şekli',
      'aiHair': 'Saç Özellikleri',
      'aiTailoringHeader': 'Detaylı Terzilik ve Deneme Ölçüleri',
      'aiShoulder': 'Omuz Genişliği (cm)',
      'aiChest': 'Göğüs (cm)',
      'aiWaist': 'Bel',
      'aiBelly': 'Karın',
      'aiHips': 'Basen',
      'walHeader': 'Cüzdan, Planlar ve Ödemeler',
      'walActivePlan': 'Aktif Planınız',
      'walActive': 'Aktif',
      'walMonthShort': 'T / ay',
      'walBuyCoins': 'StyleCoin Paketleri Satın Al',
      'walPopular': 'En Popüler',
      'walPromoHint': 'İndirim veya hediye kodunuz var mı? (ör. GIFT50)',
      'walApply': 'Uygula',
      'walRecentTx': 'Son İşlemler',
      'walTxTopup': 'Çevrimiçi Cüzdan Yüklemesi',
      'walTxTopupTime': 'Bugün, 12:40',
      'walTxTryon': 'Akıllı Sanal Deneme',
      'walTxTryonTime': 'Dün, 18:20',
      'walPkg200': '200 + 20 Hediye',
      'walPromoToast': '{code} hediye kodu uygulandı (bakiyenize +{coins} eklendi!)',
      'walPlanToast': 'Planınız başarıyla {plan} olarak değiştirildi.',
      'walCoinsAddedToast': 'Hesabınıza +{coins} yatırıldı!',
      'refHeader': 'Ödül Sistemi ve Arkadaş Ağı',
      'refInvited': 'Davet Edilen',
      'refBonus': 'Kazanılan Ödül',
      'refTier': 'Ağ Seviyesi',
      'refLinkLabel': 'Kişisel Davet Bağlantınız',
      'refCopy': 'Kopyala',
      'refCopiedToast': 'Davet bağlantısı panoya kopyalandı!',
      'refJoinedTitle': 'Ağınıza Son Katılanlar',
      'refRuleInfo': 'Her arkadaş davetinizde size 100 jeton, arkadaşınıza 50 hediye jeton verilir.',
      'refMembersUnit': 'kişi',
      'perHeader': 'Yapay Zeka Asistanı Kişiliği',
      'perSub': 'Asistan karakterini, konuşma üslubunu ve stil eleştiri sertliğini ayarlayın.',
      'perSelectTitle': 'Asistan Karakterini Seçin',
      'perDefaultVoice': 'Varsayılan Ses:',
      'perCustomName': 'Asistan İçin Özel İsim (İsteğe Bağlı)',
      'perCustomNameHint': 'Örn: Stil Koçum',
      'perToneSection': 'Konuşma Tarzı ve Eleştiri Sertliği',
      'perToneLabel': 'Yanıt Tonu',
      'perStrictness': 'Stil Eleştirisi Sertliği',
      'perRespLen': 'Yanıt Uzunluğu',
      'perVoiceSection': 'Ses ve Görünüm Ayarları',
      'perScopeLabel': 'Asistan nerelerde aktif olsun?',
      'perVoiceActive': 'Asistan Sesini Etkinleştir',
      'perSpeechSpeed': 'Konuşma Hızı',
      'perSubtitle': 'Sesle Birlikte Altyazı Göster',
      'perDailyTip': 'Günlük Stil ve Sağlık İpucu',
      'perSaveHistory': 'Asistan Sohbet Geçmişini Kaydet',
      'perResetBtn': 'Varsayılan Ayarlara Sıfırla',
      'setHeader': 'Ayarlar ve Özelleştirme',
      'setPaletteLabel': 'Moda Renk Paleti (Theme Palette)',
      'palWhite': 'Minimal Beyaz (Minimal White)',
      'palBeige': 'Lüks Sıcak Bej (Warm Beige)',
      'palSlate': 'Modern Gri (Modern Slate)',
      'palObsidian': 'Koyu Obsidiyen (Obsidian Dark)',
      'palEditorial': 'Lüks Editoryal (Editorial Luxury)',
      'setBrightnessLabel': 'Tema Parlaklığı (Açık / Koyu / Sistem)',
      'setLangLabel': 'Uygulama Dili (Language)',
      'setShowSupport': 'Yüzen Destek Butonunu Göster',
      'setShowHeaderCoins': 'Üst Kısımda Jeton Bakiyesini Göster',
      'setBackupLabel': 'Otomatik Veri Yedekleme',
      'setBackupWeekly': 'Haftalık (Önerilen)',
      'setBackupMonthly': 'Aylık',
      'setBackupOff': 'Kapalı',
      'setLogoutBtn': 'Hesaptan Çıkış Yap',
      'wardCatCl': 'Kıyafet',
      'wardCatSh': 'Ayakkabı',
      'wardCatBg': 'Çanta',
      'wardCatJw': 'Takı',
      'wardCatAc': 'Aksesuar',
      'wardItemUnit': 'parça',
      'wardCapacityWord': 'kapasite',
      'wardArchive': 'Arşiv',
      'wardArchiveEmpty': 'Arşiv boş',
      'wardNotFound': 'Öğe bulunamadı',
      'wardAddItem': 'Öğe Ekle',
      'wardAddSheetTitle': 'Gardıroba Yeni Öğe Ekle',
      'wardImgLoaded': 'Görsel başarıyla yüklendi',
      'wardImgClick': 'Fotoğraf yüklemek için dokunun',
      'wardImgToast': 'Görsel seçildi ve yapay zeka özelliklerini çıkardı.',
      'wardItemName': 'Öğe Adı',
      'wardItemNameHint': 'Örn: Lacivert ceket veya keten pantolon...',
      'wardCategory': 'Kategori',
      'wardSelectedColor': 'Seçilen Renk',
      'wardSeason': 'Mevsim',
      'wardOccasion': 'Durum',
      'wardSaveInWardrobe': 'Gardıroba Kaydet',
      'wardFilterColor': 'Renk',
      'wardSpecMainColor': 'Ana Renk',
      'wardSpecSeason': 'Uygun Mevsim',
      'wardSpecMaterial': 'Kumaş / Materyal',
      'wardSpecSize': 'Beden',
      'wardStyleInStylist': 'Stilist ile Kombinle',
      'wardUnarchive': 'Arşivden Çıkar',
      'wardArchiveAction': 'Arşivle',
      'wardDeleteTitle': 'Öğeyi Sil',
      'wardDeleteFromWardrobe': 'Gardıroptan Sil',
      'wardCancel': 'İptal',
      'wardDelete': 'Sil',
      'wardSentStylistToast': '"{name}" kombin önerisi için AI Stiliste gönderildi.',
      'wardDeleteConfirmMsg': '"{name}" öğesini gardırobunuzdan silmek istediğinizden emin misiniz?',
      'shopSub': 'Fiyatları karşılaştır; uygulamadan al veya siteye git',
      'shopSearchHint': 'Ürün, marka, kategori ara...',
      'shopCatCloth': 'Giyim',
      'shopCatShoe': 'Ayakkabı',
      'shopCatBag': 'Çanta',
      'shopCatAcc': 'Aksesuar',
      'shopCatBeauty': 'Güzellik',
      'shopCatFav': 'Favoriler',
      'shopSortTitle': 'Sıralama Ölçütü',
      'shopSortRel': 'En İlgili',
      'shopSortLo': 'En Düşük Fiyat',
      'shopSortHi': 'En Yüksek Fiyat',
      'shopSortRt': 'En Yüksek Puan',
      'shopSortDc': 'En Yüksek İndirim',
      'shopSortPrefix': 'Sırala:',
      'shopFitMeBanner': 'Bana Uygun Filtresi (Beden M · 42 Numara)',
      'shopFitMeSub': 'AI DNA profilinizdeki ölçülere göre',
      'shopProductUnit': 'ürün',
      'shopEmpty': 'Bu filtrelere uygun ürün bulunamadı',
      'shopClearAllFilters': 'Tüm Filtreleri Temizle',
      'shopClear': 'Temizle',
      'shopDisclaimer': 'Fiyatlar ve stoklar örnek amaçlıdır. StyleMorph ürünleri uygulama garantili, dış site alımları satıcı politikasına tabidir.',
      'shopAppBadge': 'Uygulama',
      'shopOutOfStock': 'Tükendi',
      'shopFromPrice': 'Başlangıç',
      'shopStoreUnit': 'mağaza',
      'shopFilterTitle': 'Gelişmiş Mağaza Filtreleri',
      'shopSaleType': 'Satın Alma Yöntemi',
      'shopSaleApp': 'Uygulama İçi',
      'shopSaleSite': 'Satıcı Sitesi',
      'shopGender': 'Cinsiyet',
      'shopGenderW': 'Kadın',
      'shopGenderM': 'Erkek',
      'shopGenderU': 'Unisex',
      'shopMaxPriceNoLimit': 'Maks. Fiyat: Sınırsız',
      'shopMaxPrice': 'Maks. Fiyat',
      'shopBrands': 'Markalar',
      'shopToggleAvail': 'Sadece Stoktakiler',
      'shopToggleDisc': 'Sadece İndirimli Ürünler',
      'shopToggleVerified': 'Onaylı Satıcılar & Uygulama',
      'shopRemoveFilters': 'Sıfırla',
      'shopApplyFilters': 'Filtreleri Uygula',
      'shopSellerSiteBtn': 'Satıcı Sitesi',
      'shopCompareActive': 'Karşılaştırmada',
      'shopAlertActive': 'Alarm Açık',
      'shopDiscountWord': 'İndirim',
      'shopReviewUnit': 'yorum',
      'shopSellersTitle': 'Satıcılar ve Fiyat Karşılaştırması',
      'shopCheapest': 'En Ucuz',
      'shopDelivery': 'Teslimat',
      'shopBuyInApp': 'Uygulamadan Al',
      'shopGoToSite': 'Siteye Git',
      'shopProductSpecs': 'Ürün Özellikleri',
      'shopBrand': 'Marka',
      'shopMaterial': 'Materyal',
      'shopColorsLabel': 'Renkler',
      'shopSizesLabel': 'Bedenler',
      'shopViewOnSite': 'Satıcı Sitesinde İncele',
      'shopBuyFromApp': 'StyleMorph ile Satın Al',
      'shopFitTitle': 'Akıllı Uyum Analizi (Bana Uygun)',
      'shopFitSizeOk': 'Profilinize uygun beden stokta var.',
      'shopFitColorsOk': 'Cilt alt tonunuza uygun renkler:',
      'shopWardrobeMatchTitle': 'Kombin Önerisi: Gardırobunuzla Uyumlu',
      'shopTryOnDesc': 'Bu ürün profil modelinizde denenmek üzere sanal deneme odasına gönderilir.',
      'shopTryOnCost5': 'İşlem Ücreti: 5 Jeton',
      'shopSendToTryOn': 'Sanal Deneme Odasına Gönder',
      'shopInsufficientCoins': 'Yetersiz jeton. Cüzdan bölümünden yükleyin.',
      'shopOfficialAgent': 'Resmi Onaylı Satıcı',
      'shopIndSeller': 'Bağımsız İş Ortağı Mağaza',
      'shopRedirectBtn': 'Satıcı Web Sitesine Git',
      'shopNoticeOut': 'StyleMorph’tan ayrılıp satıcının web sitesine yönlendiriliyorsunuz.',
      'shopNoticePay': 'Ödeme ve faturalandırma işlemleri hedef sitede tamamlanır.',
      'shopNoticeShield': 'Teslimat ve iade koşulları ilgili mağaza kurallarına tabidir.',
      'shopCompareCountMsg': 'Karşılaştırma için {count} ürün seçildi',
      'shopCompareReadyMsg': '{count} ürün için karşılaştırma tablosu hazırlandı.',
      'shopTryOnSentToast': '"{name}" AI Sanal Deneme odasına gönderildi ({coins} düşüldü).',
      'shopLeavingToast': 'StyleMorph’tan ayrılıp "{store}" web sitesine geçiyorsunuz.',
      'shopRedirectToast': '{store} web sitesine yönlendiriliyor... (Deneme modu)',
      'shopOrderPlacedToast': '"{name}" için uygulama içi sipariş oluşturuldu.',
      'styWeather': '18°C Güneşli',
      'styEnergy': 'Enerji: Orta',
      'styMyPalette': 'Paletim',
      'styChatTitle': 'Ramin (Stilist)',
      'styChatBannerSub': 'Bu kombin bugün için harika; değişiklik istersen sor.',
      'styPlanner': 'Planlayıcı',
      'styStyleColor': 'Stil & Renk',
      'stySmartShop': 'Akıllı Alışveriş',
      'styStats': 'Stil İstatistikleri',
      'styLocked': 'Kilitli',
      'styLock': 'Kilitle',
      'stySwap': 'Değiştir',
      'stySaved': 'Kaydedildi',
      'stySave': 'Kaydet',
      'styTryOn': 'Dene',
      'stySwapToast': 'Gardırobunuzdan alternatif kombin hesaplandı.',
      'styChatFullTitle': 'Ramin (Kişisel Yapay Zeka Stilisti)',
      'styAskHint': 'Stilistinizden öneri isteyin...',
      'styDailyQuota': 'Bugünkü ücretsiz mesaj hakkı',
      'styTryOnDialogTitle': 'Yapay Zeka Sanal Deneme Odası',
      'styQualityTierTitle': 'Deneme Kalite Seviyesini Seçin',
      'stySaveInAlbum': 'Albümüme Kaydet',
      'styTryOnTerms': 'Sonuçların tahmini olduğunu ve gizlilikle işlendiğini kabul ediyorum.',
      'styWeeklyPlanner': 'Haftalık Stil Planlayıcı',
      'styAddCalEvent': 'Takvime Etkinlik Ekle',
      'styStylePaletteTitle': 'Stilim ve Renk Paletim',
      'styUpdatePhotoBtn': 'Yeni Fotoğraftan Güncelle',
      'stySmartShoppingTitle': 'Akıllı Alışveriş (Gardırop Eksikleri)',
      'styViewInShop': 'Mağazada Görüntüle',
      'styStatsTitle': 'Stil Analizi ve İçgörüler',
      'styGetReport': 'Aylık Raporu İndir',
      'atelSub': 'Kendinizden stüdyo kalitesinde portre ve videolar üretin',
      'atelShowcase': 'Vitrin',
      'atelCatPortrait': 'Portre',
      'atelCatFashion': 'Moda',
      'atelCatSeasonal': 'Mevsimlik',
      'atelCatTravel': 'Seyahat',
      'atelMediaAll': 'Tüm Medya',
      'atelMediaPhoto': 'Fotoğraf',
      'atelMediaVideo': 'Kısa Video',
      'atelVideoBadge': 'Video',
      'atelPhotosUnit': 'fotoğraf',
      'atelSatisfaction': 'beğeni',
      'atelStatusReady': 'Hazır',
      'atelStatusProcessing': 'İşleniyor',
      'atelStatusFailed': 'Başarısız',
      'atelEmptyCreations': 'Bu filtrede çalışma bulunamadı.',
      'atelCoinsRefunded': 'Jeton iade edildi',
      'atelRetryFree': 'Ücretsiz Dene',
      'atelPopularity': 'Popülerlik',
      'atelUsage': 'Kullanım',
      'atelBuildTime': 'Üretim Süresi',
      'atelOutputType': 'Çıktı Türü:',
      'atelProOptions': 'Yapay Zeka Özelleştirmeleri',
      'atelGuarantee': 'Memnuniyet Garantisi: Başarısız işlemlerde jeton iade edilir ve 1 ücretsiz yeniden üretim hakkı verilir.',
      'atelConfirmTerms': 'Yüzümle üretileceğini ve "Yapay Zeka ile Üretildi" rozeti ekleneceğini onaylıyorum.',
      'atelConfirmStart': 'Onayla ve Başlat',
      'atelDownload': 'İndir',
      'atelRebuild': 'Yeniden Üret',
      'atelFreeRebuild': 'Ücretsiz Tekrar',
      'atelPrivateLink': 'Özel Bağlantı',
      'atelPublicLink': 'Herkese Açık Bağlantı',
      'atelDeleteWork': 'Çalışmayı Sil',
      'atelRateQuality': 'Çıktı kalitesi nasıldı?',
      'wellPrivacyTooltip': 'Gizlilik Modu',
      'wellBeauty': 'Güzellik',
      'wellHealth': 'Sağlık',
      'wellMind': 'Zihin',
      'wellFutureYou': 'Geleceğin',
      'wellInsightTitle': 'Günün Yapay Zeka İçgörüsü',
      'wellInsightBody': 'Son cilt analizinize göre bugün su tüketimi ve nemlendirici bakımına öncelik verin.',
      'wellViewSkinRoutine': 'Cilt Bakım Rutinini Gör',
      'wellTodayActions': 'Bugünkü Sağlık Görevleri',
      'wellTrend7Days': 'Son 7 Günlük İlerleme',
      'wellAutoUpdate': 'Otomatik Güncellendi',
      'wellMetricWeight': 'Kilo',
      'wellMetricSleep': 'Uyku',
      'wellMetricActivity': 'Aktivite',
      'wellMetricMood': 'Ruh Hali',
      'wellMetricHeart': 'Nabız',
      'wellDailyCheckinBtn': 'Günlük Sağlık Durumunu Kaydet',
      'wellChartHiddenPrivacy': 'Veriler Gizlilik Modunda gizlendi',
      'wellBeautySheetTitle': 'Güzellik, Cilt ve Saç',
      'wellHealthSheetTitle': 'Sağlık ve Zindelik',
      'wellMindSheetTitle': 'Zihin ve Huzur',
      'wellFutureSheetTitle': 'Gelecekteki Ben Simülatörü',
      'wellCheckinSheetTitle': 'Günlük Sağlık Kaydı',
      'wellClose': 'Kapat',
      'wearableCardTitle': 'Akıllı Saat ve Sağlık Eşitlemesi',
      'wearableStatusConnected': 'Bağlı',
      'wearableStatusDisconnected': 'Bağlantı Kesildi',
      'wearableLastSynced': 'Son eşitleme:',
      'wearableSyncNow': 'Şimdi Eşitle',
      'wearableManagePermissions': 'İzinleri Yönet',
      'wearableConsentTitle': 'Sağlık İzinleri ve Akıllı Saat',
      'wearableSourceDevice': 'Kaynak Cihaz / Platform',
      'wearablePermissionsSubtitle': 'Yapay zeka ile paylaşılan biyometrik veriler için ayrıntılı gizlilik denetimi',
      'wearablePermSteps': 'Adımlar ve Yürüme Mesafesi',
      'wearablePermSleep': 'Gece Uykusu ve Derin Uyku Kalitesi',
      'wearablePermHeart': 'Dinlenme ve Anlık Kalp Atış Hızı',
      'wearablePermWeight': 'Akıllı Tartı Vücut Ağırlığı',
      'wearablePermCalories': 'Aktif Yakılan Kaloriler',
      'wearableReadinessLabel': 'Enerji Hazırlığı:',
      'stylistBiometricBannerTitle': 'Biyometrik Sağlık Tabanlı Stil Önerisi',
      'stylistBiometricComfortHint': 'Dün gece daha az uyku kaydedildi; bugün rahat, yumuşak ve nefes alabilen kumaşlar önerilir.',
      'stylistBiometricActiveHint': 'Bugün yüksek aktivite kaydedildi; nefes alan katmanlar ve ergonomik ayakkabılar önceliklendirildi.',
      // Auth strings
      'authGetStarted': 'Başlayın',
      'authWelcomeTagline': 'Sanal Deneme • Yapay Zeka Kişisel Stilist',
      'authWelcomeDesc': 'Satın almadan önce kıyafetleri fotoğrafınızda deneyin.\nSize en uygun kombinleri keşfedin ve tarzınızı yaratın.',
      'authLoginTitle': 'Giriş Yap',
      'authLoginSubtitle': 'Sanal deneme odasına erişmek için giriş yapın',
      'authLoginBtn': 'Giriş Yap',
      'authSignupTitle': 'Hesap Oluştur',
      'authSignupSubtitle': 'Ücretsiz StyleMorph hesabınızı oluşturun',
      'authSignupBtn': 'Kayıt Ol',
      'authEmailLabel': 'E-posta',
      'authEmailHint': 'ornek@email.com',
      'authPasswordLabel': 'Şifre',
      'authPasswordHint': '••••••••',
      'authConfirmPasswordLabel': 'Şifreyi Onayla',
      'authConfirmPasswordHint': 'Şifrenizi tekrar girin',
      'authOrWith': 'veya şununla devam et',
      'authSwitchToSignup': 'Yeni Hesap Oluştur',
      'authSwitchToLogin': 'Zaten hesabınız var mı? Giriş Yap',
      'authForgotPassword': 'Şifrenizi mi unuttunuz?',
      'authForgotTitle': 'Şifre Sıfırlama',
      'authForgotSubtitle': 'Şifre sıfırlama bağlantısı almak için e-postanızı girin',
      'authForgotBtn': 'Sıfırlama Bağlantısı Gönder',
      'authBackToLogin': 'Girişe Dön',
      'authPwStrengthLabel': 'Şifre Gücü',
      'authPwRuleLen': 'En az 8 karakter',
      'authPwRuleUpper': 'En az 1 büyük harf',
      'authPwRuleLower': 'En az 1 küçük harf',
      'authPwRuleDigit': 'En az 1 rakam',
      'authPwRuleSpecial': 'En az 1 özel karakter (!@#\$...)',
      'authPwMismatch': 'Şifreler eşleşmiyor',
      'authCopyrightYear': 'StyleMorph 2026 ©',
      // Auth Error & Feedback strings
      'authErrEmailAlreadyInUse': 'Bu e-posta adresi zaten kullanımda.',
      'authErrWrongPassword': 'Girdiğiniz şifre hatalı.',
      'authErrUserNotFound': 'Bu e-posta ile kayıtlı bir hesap bulunamadı.',
      'authErrInvalidEmail': 'E-posta adresi biçimi geçersiz.',
      'authErrUserDisabled': 'Bu kullanıcı hesabı devre dışı bırakılmış.',
      'authErrWeakPassword': 'Seçilen şifre çok zayıf.',
      'authErrNetwork': 'Ağ hatası. Lütfen internet bağlantınızı kontrol edin.',
      'authErrTooManyRequests': 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.',
      'authErrInvalidCredential': 'Geçersiz e-posta veya şifre.',
      'authErrGoogleCancelled': 'Google ile giriş iptal edildi.',
      'authErrAppleCancelled': 'Apple ile giriş iptal edildi.',
      'authErrGeneric': 'Kimlik doğrulama başarısız oldu. Lütfen tekrar deneyin.',
      'authResetEmailSent': 'Şifre sıfırlama bağlantısı e-postanıza gönderildi.',
      // Sessions sub-tab
      'tSess': 'Oturumlar',
      'sessHeader': 'Aktif Oturumlar ve Cihazlar',
      'sessSubtitle': 'Hesabınıza giriş yapmış tüm cihazları görüntüleyin ve yönetin. Daha iyi güvenlik için etkin olmayan cihazların erişimini iptal edebilirsiniz.',
      'sessTerminateAll': 'Diğer Cihazlardan Çıkış Yap',
      'sessCurrentDevice': 'Bu Cihaz',
      'sessEmpty': 'Aktif oturum bulunamadı.',
      'sessPlatform': 'Platform',
      'sessOs': 'İşletim Sistemi',
      'sessUserAgent': 'Tarayıcı / Uygulama',
      'sessLoginTime': 'Giriş Zamanı',
      'sessLastActive': 'Son Aktif',
      'sessDelete': 'Sil',
      'timeJustNow': 'Az önce',
      'timeMinutesAgo': '{n} dk önce',
      'timeHoursAgo': '{n} sa önce',
      'timeDaysAgo': '{n} gün önce',
      'sessPrimaryBadge': 'Ana Cihaz',
      'sessBlockedBadge': 'Engellendi',
      'sessBlockBtn': 'Engelle',
      'sessUnblockBtn': 'Engeli Kaldır',
      'sessConfirmBlockTitle': 'Cihaz Erişimini Engelle',
      'sessConfirmBlockMsg': 'Bu cihazın erişimini geçici olarak engellemek istediğinizden emin misiniz? Aktif oturumu hemen kapatılacaktır.',
      'sessConfirmUnblockTitle': 'Cihaz Engelini Kaldır',
      'sessConfirmUnblockMsg': 'Bu cihazın engelini kaldırmak istiyor musunuz? Tekrar giriş yapmasına izin verilecektir.',
      'sessConfirmDeleteTitle': 'Oturumu Sil',
      'sessConfirmDeleteMsg': 'Bu oturumu kapatıp silmek istediğinizden emin misiniz?',
      'sessConfirmTerminateAllTitle': 'Diğer Cihazlardan Çıkış Yap',
      'sessConfirmTerminateAllMsg': 'Diğer tüm cihazlardan çıkış yapmak istediğinizden emin misiniz? (Ana cihaz etkilenmeyecektir)',
      'sessDeviceBlockedNotice': 'Bu cihazın erişimi ana cihaz tarafından geçici olarak engellendi.',
      'sessPrimaryOnlyNotice': 'Yalnızca ana cihaz oturumları engelleme veya silme yetkisine sahiptir.',
      'sessCopiedToast': 'Oturum kimliği panoya kopyalandı',
      'sessErrLoad': 'Oturumlar yüklenemedi',
      'dialogCancel': 'İptal',
      'dialogConfirm': 'Onayla',
    },
  };

  String get(String key) {
    return _values[localeCode]?[key] ?? _values['en']?[key] ?? key;
  }

  // Dynamic formatted helpers
  String countWithUnit(int count, String unit) => '${formatNumber(count)} $unit';
  String coinsText(int n) => '${formatNumber(n)} $coin';
  String capacityRatioText(int active, int total) =>
      '${formatNumber(active)}/${formatNumber(total)} $wardCapacityWord';
  String unreadNewCount(int n) => '${formatNumber(n)} $newWord';
  String tasksProgress(int done, int total) {
    if (localeCode == 'en' || localeCode == 'tr') {
      return '${formatNumber(done)} / ${formatNumber(total)}';
    }
    if (localeCode == 'ar') {
      return '${formatNumber(done)} من ${formatNumber(total)}';
    }
    return '${formatNumber(done)} از ${formatNumber(total)}';
  }

  String freeQuotaText(int left, int total) =>
      '$styDailyQuota: ${tasksProgress(left, total)}';
  String balanceText(int coins) {
    if (localeCode == 'en') return 'Your balance: ${coinsText(coins)}';
    if (localeCode == 'tr') return 'Bakiyeniz: ${coinsText(coins)}';
    if (localeCode == 'ar') return 'رصيدك: ${coinsText(coins)}';
    return 'موجودی شما: ${coinsText(coins)}';
  }

  String buildCostText(int coins) {
    if (localeCode == 'en') return 'Cost: ${coinsText(coins)}';
    if (localeCode == 'tr') return 'Ücret: ${coinsText(coins)}';
    if (localeCode == 'ar') return 'التكلفة: ${coinsText(coins)}';
    return 'بهای ساخت: ${coinsText(coins)}';
  }

  String walPromoApplied(String code) => get('walPromoToast')
      .replaceAll('{code}', code)
      .replaceAll('{coins}', coinsText(50));

  String walPlanChanged(String plan) =>
      get('walPlanToast').replaceAll('{plan}', plan);

  String walCoinsAdded(int coins) =>
      get('walCoinsAddedToast').replaceAll('{coins}', coinsText(coins));

  String get appName => get('appName');
  String get back => get('back');
  String get sub => get('sub');
  String get desc => get('desc');
  String get pers => get('pers');
  String get biz => get('biz');
  String get pT => get('pT');
  String get pS => get('pS');
  String get bT => get('bT');
  String get bS => get('bS');
  String get acc => get('acc');
  String get pw => get('pw');
  String get bid => get('bid');
  String get go => get('go');
  String get orText => get('orText');
  String get reg => get('reg');
  String get forgot => get('forgot');
  String get nShop => get('nShop');
  String get nWard => get('nWard');
  String get nSty => get('nSty');
  String get nAtel => get('nAtel');
  String get nWell => get('nWell');
  String get nProf => get('nProf');
  String get coin => get('coin');
  String get currencyUnit => get('currencyUnit');
  String get verif => get('verif');
  String get supT => get('supT');
  String get supHi => get('supHi');
  String get supPh => get('supPh');
  String get search => get('search');
  String get filter => get('filter');
  String get allText => get('allText');
  String get soon => get('soon');
  String get mWal => get('mWal');
  String get mFav => get('mFav');
  String get mRef => get('mRef');
  String get mSet => get('mSet');
  String get mHist => get('mHist');
  String get mSaved => get('mSaved');
  String get mOrders => get('mOrders');
  String get mAbout => get('mAbout');
  String get mHelp => get('mHelp');
  String get mSupport => get('mSupport');
  String get mOut => get('mOut');
  String get pcT => get('pcT');
  String get tIdent => get('tIdent');
  String get tGal => get('tGal');
  String get tAi => get('tAi');
  String get tWal => get('tWal');
  String get tRef => get('tRef');
  String get tComp => get('tComp');
  String get tSet => get('tSet');
  String get hPlan => get('hPlan');
  String get hFin => get('hFin');
  String get sendText => get('sendText');
  String get err => get('err');
  String get userSa => get('userSa');
  String get usernameSa => get('usernameSa');
  String get lvl1 => formatNumber(get('lvl1'));
  String get coinsCount => formatNumber(get('coinsCount'));
  String get profileCompletionPct => formatNumber(get('profileCompletionPct'));
  String get wardrobeTitle => get('wardrobeTitle');
  String get shopTitle => get('shopTitle');
  String get uploadItem => get('uploadItem');
  String get planCapacity => get('planCapacity');
  String get searchWardrobe => get('searchWardrobe');
  String get clearFilters => get('clearFilters');
  String get tryOnShortcut => get('tryOnShortcut');
  String get priceAlert => get('priceAlert');
  String get compare => get('compare');
  String get fitForMe => get('fitForMe');
  String get matchWardrobe => get('matchWardrobe');
  String get stylistTitle => get('stylistTitle');
  String get atelierTitle => get('atelierTitle');
  String get wellnessTitle => get('wellnessTitle');
  String get virtualTryOn => get('virtualTryOn');
  String get myCreations => get('myCreations');
  String get aiWatermarkBadge => get('aiWatermarkBadge');
  String get futureSelf => get('futureSelf');
  String get themeLight => get('themeLight');
  String get themeDark => get('themeDark');
  String get themeSystem => get('themeSystem');
  String get drawerThemeLightTip => get('drawerThemeLightTip');
  String get drawerThemeDarkTip => get('drawerThemeDarkTip');
  String get drawerThemeSystemTip => get('drawerThemeSystemTip');
  String get saveChanges => get('saveChanges');
  String get noChangesYet => get('noChangesYet');
  String get profileSavedToast => get('profileSavedToast');
  String get notificationsTitle => get('notificationsTitle');
  String get markAllRead => get('markAllRead');
  String get noNotifications => get('noNotifications');
  String get notifCatAi => get('notifCatAi');
  String get notifCatShop => get('notifCatShop');
  String get notifCatFinance => get('notifCatFinance');
  String get newWord => get('newWord');

  // Identity
  String get idHeader => get('idHeader');
  String get idFirstName => get('idFirstName');
  String get idLastName => get('idLastName');
  String get idNick => get('idNick');
  String get idNationalId => get('idNationalId');
  String get idMobile => get('idMobile');
  String get idVerified => get('idVerified');
  String get idEmail => get('idEmail');
  String get idSendCode => get('idSendCode');
  String get idCodeSentToast => get('idCodeSentToast');
  String get idCountry => get('idCountry');
  String get idProvince => get('idProvince');
  String get idCity => get('idCity');
  String get idAddress => get('idAddress');
  String get idZip => get('idZip');

  // Gallery
  String get galHeader => get('galHeader');
  String get galScan360 => get('galScan360');
  String get galUploaded => get('galUploaded');
  String get galPlayToast => get('galPlayToast');
  String get galBasePhotos => get('galBasePhotos');
  String get galUsedInAi => get('galUsedInAi');
  String get galApproved => get('galApproved');
  String get galFullFront => get('galFullFront');
  String get galSideView => get('galSideView');
  String get galSlotAdded => get('galSlotAdded');
  String get galSlotRemoved => get('galSlotRemoved');
  String get galRecorded => get('galRecorded');
  String get galUploadSlot3 => get('galUploadSlot3');
  String get galTip => get('galTip');

  // AI DNA
  String get aiHeader => get('aiHeader');
  String get aiEditable => get('aiEditable');
  String get aiNote => get('aiNote');
  String get aiGender => get('aiGender');
  String get aiFemale => get('aiFemale');
  String get aiMale => get('aiMale');
  String get aiHeight => get('aiHeight');
  String get aiWeight => get('aiWeight');
  String get aiSkinTone => get('aiSkinTone');
  String get aiBodyShape => get('aiBodyShape');
  String get aiFaceShape => get('aiFaceShape');
  String get aiHair => get('aiHair');
  String get aiTailoringHeader => get('aiTailoringHeader');
  String get aiShoulder => get('aiShoulder');
  String get aiChest => get('aiChest');
  String get aiWaist => get('aiWaist');
  String get aiBelly => get('aiBelly');
  String get aiHips => get('aiHips');

  // Wallet
  String get walHeader => get('walHeader');
  String get walActivePlan => get('walActivePlan');
  String get walActive => get('walActive');
  String get walMonthShort => get('walMonthShort');
  String get walBuyCoins => get('walBuyCoins');
  String get walPopular => get('walPopular');
  String get walPromoHint => get('walPromoHint');
  String get walApply => get('walApply');
  String get walRecentTx => get('walRecentTx');
  String get walTxTopup => get('walTxTopup');
  String get walTxTopupTime => get('walTxTopupTime');
  String get walTxTryon => get('walTxTryon');
  String get walTxTryonTime => get('walTxTryonTime');
  String get walPkg200 => get('walPkg200');

  // Referral
  String get refHeader => get('refHeader');
  String get refInvited => get('refInvited');
  String get refBonus => get('refBonus');
  String get refTier => get('refTier');
  String get refLinkLabel => get('refLinkLabel');
  String get refCopy => get('refCopy');
  String get refCopiedToast => get('refCopiedToast');
  String get refJoinedTitle => get('refJoinedTitle');
  String get refRuleInfo => get('refRuleInfo');
  String get refMembersUnit => get('refMembersUnit');

  // Persona
  String get perHeader => get('perHeader');
  String get perSub => get('perSub');
  String get perSelectTitle => get('perSelectTitle');
  String get perDefaultVoice => get('perDefaultVoice');
  String get perCustomName => get('perCustomName');
  String get perCustomNameHint => get('perCustomNameHint');
  String get perToneSection => get('perToneSection');
  String get perToneLabel => get('perToneLabel');
  String get perStrictness => get('perStrictness');
  String get perRespLen => get('perRespLen');
  String get perVoiceSection => get('perVoiceSection');
  String get perScopeLabel => get('perScopeLabel');
  String get perVoiceActive => get('perVoiceActive');
  String get perSpeechSpeed => get('perSpeechSpeed');
  String get perSubtitle => get('perSubtitle');
  String get perDailyTip => get('perDailyTip');
  String get perSaveHistory => get('perSaveHistory');
  String get perResetBtn => get('perResetBtn');

  // Settings
  String get setHeader => get('setHeader');
  String get setPaletteLabel => get('setPaletteLabel');
  String get palWhite => get('palWhite');
  String get palBeige => get('palBeige');
  String get palSlate => get('palSlate');
  String get palObsidian => get('palObsidian');
  String get palEditorial => get('palEditorial');
  String get setBrightnessLabel => get('setBrightnessLabel');
  String get setLangLabel => get('setLangLabel');
  String get setShowSupport => get('setShowSupport');
  String get setShowHeaderCoins => get('setShowHeaderCoins');
  String get setBackupLabel => get('setBackupLabel');
  String get setBackupWeekly => get('setBackupWeekly');
  String get setBackupMonthly => get('setBackupMonthly');
  String get setBackupOff => get('setBackupOff');
  String get setLogoutBtn => get('setLogoutBtn');

  // Wardrobe
  String get wardCatCl => get('wardCatCl');
  String get wardCatSh => get('wardCatSh');
  String get wardCatBg => get('wardCatBg');
  String get wardCatJw => get('wardCatJw');
  String get wardCatAc => get('wardCatAc');
  String get wardItemUnit => get('wardItemUnit');
  String get wardCapacityWord => get('wardCapacityWord');
  String get wardArchive => get('wardArchive');
  String get wardArchiveEmpty => get('wardArchiveEmpty');
  String get wardNotFound => get('wardNotFound');
  String get wardAddItem => get('wardAddItem');
  String get wardAddSheetTitle => get('wardAddSheetTitle');
  String get wardImgLoaded => get('wardImgLoaded');
  String get wardImgClick => get('wardImgClick');
  String get wardImgToast => get('wardImgToast');
  String get wardItemName => get('wardItemName');
  String get wardItemNameHint => get('wardItemNameHint');
  String get wardCategory => get('wardCategory');
  String get wardSelectedColor => get('wardSelectedColor');
  String get wardSeason => get('wardSeason');
  String get wardOccasion => get('wardOccasion');
  String get wardSaveInWardrobe => get('wardSaveInWardrobe');
  String get wardFilterColor => get('wardFilterColor');
  String get wardSpecMainColor => get('wardSpecMainColor');
  String get wardSpecSeason => get('wardSpecSeason');
  String get wardSpecMaterial => get('wardSpecMaterial');
  String get wardSpecSize => get('wardSpecSize');
  String get wardStyleInStylist => get('wardStyleInStylist');
  String get wardUnarchive => get('wardUnarchive');
  String get wardArchiveAction => get('wardArchiveAction');
  String get wardDeleteTitle => get('wardDeleteTitle');
  String get wardDeleteFromWardrobe => get('wardDeleteFromWardrobe');
  String get wardCancel => get('wardCancel');
  String get wardDelete => get('wardDelete');
  String wardSentToStylist(String name) =>
      get('wardSentStylistToast').replaceAll('{name}', name);
  String wardDeleteConfirm(String name) =>
      get('wardDeleteConfirmMsg').replaceAll('{name}', name);

  // Shop
  String get shopSub => get('shopSub');
  String get shopSearchHint => get('shopSearchHint');
  String get shopCatCloth => get('shopCatCloth');
  String get shopCatShoe => get('shopCatShoe');
  String get shopCatBag => get('shopCatBag');
  String get shopCatAcc => get('shopCatAcc');
  String get shopCatBeauty => get('shopCatBeauty');
  String get shopCatFav => get('shopCatFav');
  String get shopSortTitle => get('shopSortTitle');
  String get shopSortRel => get('shopSortRel');
  String get shopSortLo => get('shopSortLo');
  String get shopSortHi => get('shopSortHi');
  String get shopSortRt => get('shopSortRt');
  String get shopSortDc => get('shopSortDc');
  String get shopSortPrefix => get('shopSortPrefix');
  String get shopFitMeBanner => get('shopFitMeBanner');
  String get shopFitMeSub => get('shopFitMeSub');
  String get shopProductUnit => get('shopProductUnit');
  String get shopEmpty => get('shopEmpty');
  String get shopClearAllFilters => get('shopClearAllFilters');
  String get shopClear => get('shopClear');
  String get shopDisclaimer => get('shopDisclaimer');
  String get shopAppBadge => get('shopAppBadge');
  String get shopOutOfStock => get('shopOutOfStock');
  String get shopFromPrice => get('shopFromPrice');
  String get shopStoreUnit => get('shopStoreUnit');
  String get shopFilterTitle => get('shopFilterTitle');
  String get shopSaleType => get('shopSaleType');
  String get shopSaleApp => get('shopSaleApp');
  String get shopSaleSite => get('shopSaleSite');
  String get shopGender => get('shopGender');
  String get shopGenderW => get('shopGenderW');
  String get shopGenderM => get('shopGenderM');
  String get shopGenderU => get('shopGenderU');
  String get shopMaxPriceNoLimit => get('shopMaxPriceNoLimit');
  String get shopMaxPrice => get('shopMaxPrice');
  String get shopBrands => get('shopBrands');
  String get shopToggleAvail => get('shopToggleAvail');
  String get shopToggleDisc => get('shopToggleDisc');
  String get shopToggleVerified => get('shopToggleVerified');
  String get shopRemoveFilters => get('shopRemoveFilters');
  String get shopApplyFilters => get('shopApplyFilters');
  String get shopSellerSiteBtn => get('shopSellerSiteBtn');
  String get shopCompareActive => get('shopCompareActive');
  String get shopAlertActive => get('shopAlertActive');
  String get shopDiscountWord => get('shopDiscountWord');
  String get shopReviewUnit => get('shopReviewUnit');
  String get shopSellersTitle => get('shopSellersTitle');
  String get shopCheapest => get('shopCheapest');
  String get shopDelivery => get('shopDelivery');
  String get shopBuyInApp => get('shopBuyInApp');
  String get shopGoToSite => get('shopGoToSite');
  String get shopProductSpecs => get('shopProductSpecs');
  String get shopBrand => get('shopBrand');
  String get shopMaterial => get('shopMaterial');
  String get shopColorsLabel => get('shopColorsLabel');
  String get shopSizesLabel => get('shopSizesLabel');
  String get shopViewOnSite => get('shopViewOnSite');
  String get shopBuyFromApp => get('shopBuyFromApp');
  String get shopFitTitle => get('shopFitTitle');
  String get shopFitSizeOk => get('shopFitSizeOk');
  String get shopFitColorsOk => get('shopFitColorsOk');
  String get shopWardrobeMatchTitle => get('shopWardrobeMatchTitle');
  String get shopTryOnDesc => get('shopTryOnDesc');
  String get shopTryOnCost5 => get('shopTryOnCost5');
  String get shopSendToTryOn => get('shopSendToTryOn');
  String get shopInsufficientCoins => get('shopInsufficientCoins');
  String get shopOfficialAgent => get('shopOfficialAgent');
  String get shopIndSeller => get('shopIndSeller');
  String get shopRedirectBtn => get('shopRedirectBtn');
  String get shopNoticeOut => get('shopNoticeOut');
  String get shopNoticePay => get('shopNoticePay');
  String get shopNoticeShield => get('shopNoticeShield');
  String shopCompareCount(int count) =>
      get('shopCompareCountMsg').replaceAll('{count}', formatNumber(count));
  String shopCompareReady(int count) =>
      get('shopCompareReadyMsg').replaceAll('{count}', formatNumber(count));
  String shopTryOnSent(String name) => get('shopTryOnSentToast')
      .replaceAll('{name}', name)
      .replaceAll('{coins}', coinsText(5));
  String shopLeavingNotice(String store) =>
      get('shopLeavingToast').replaceAll('{store}', store);
  String shopRedirectMsg(String store) =>
      get('shopRedirectToast').replaceAll('{store}', store);
  String shopOrderPlaced(String name) =>
      get('shopOrderPlacedToast').replaceAll('{name}', name);

  // Stylist
  String get styWeather => get('styWeather');
  String get styEnergy => get('styEnergy');
  String get styMyPalette => get('styMyPalette');
  String get styChatTitle => get('styChatTitle');
  String get styChatBannerSub => get('styChatBannerSub');
  String get styPlanner => get('styPlanner');
  String get styStyleColor => get('styStyleColor');
  String get stySmartShop => get('stySmartShop');
  String get styStats => get('styStats');
  String get styLocked => get('styLocked');
  String get styLock => get('styLock');
  String get stySwap => get('stySwap');
  String get stySaved => get('stySaved');
  String get stySave => get('stySave');
  String get styTryOn => get('styTryOn');
  String get stySwapToast => get('stySwapToast');
  String get styChatFullTitle => get('styChatFullTitle');
  String get styAskHint => get('styAskHint');
  String get styDailyQuota => get('styDailyQuota');
  String get styTryOnDialogTitle => get('styTryOnDialogTitle');
  String get styQualityTierTitle => get('styQualityTierTitle');
  String get stySaveInAlbum => get('stySaveInAlbum');
  String get styTryOnTerms => get('styTryOnTerms');
  String get styWeeklyPlanner => get('styWeeklyPlanner');
  String get styAddCalEvent => get('styAddCalEvent');
  String get styStylePaletteTitle => get('styStylePaletteTitle');
  String get styUpdatePhotoBtn => get('styUpdatePhotoBtn');
  String get stySmartShoppingTitle => get('stySmartShoppingTitle');
  String get styViewInShop => get('styViewInShop');
  String get styStatsTitle => get('styStatsTitle');
  String get styGetReport => get('styGetReport');

  // Atelier
  String get atelSub => get('atelSub');
  String get atelShowcase => get('atelShowcase');
  String get atelCatPortrait => get('atelCatPortrait');
  String get atelCatFashion => get('atelCatFashion');
  String get atelCatSeasonal => get('atelCatSeasonal');
  String get atelCatTravel => get('atelCatTravel');
  String get atelMediaAll => get('atelMediaAll');
  String get atelMediaPhoto => get('atelMediaPhoto');
  String get atelMediaVideo => get('atelMediaVideo');
  String get atelVideoBadge => get('atelVideoBadge');
  String get atelPhotosUnit => get('atelPhotosUnit');
  String get atelSatisfaction => get('atelSatisfaction');
  String get atelStatusReady => get('atelStatusReady');
  String get atelStatusProcessing => get('atelStatusProcessing');
  String get atelStatusFailed => get('atelStatusFailed');
  String get atelEmptyCreations => get('atelEmptyCreations');
  String get atelCoinsRefunded => get('atelCoinsRefunded');
  String get atelRetryFree => get('atelRetryFree');
  String get atelPopularity => get('atelPopularity');
  String get atelUsage => get('atelUsage');
  String get atelBuildTime => get('atelBuildTime');
  String get atelOutputType => get('atelOutputType');
  String get atelProOptions => get('atelProOptions');
  String get atelGuarantee => get('atelGuarantee');
  String get atelConfirmTerms => get('atelConfirmTerms');
  String get atelConfirmStart => get('atelConfirmStart');
  String get atelDownload => get('atelDownload');
  String get atelRebuild => get('atelRebuild');
  String get atelFreeRebuild => get('atelFreeRebuild');
  String get atelPrivateLink => get('atelPrivateLink');
  String get atelPublicLink => get('atelPublicLink');
  String get atelDeleteWork => get('atelDeleteWork');
  String get atelRateQuality => get('atelRateQuality');

  // Wellness
  String get wellPrivacyTooltip => get('wellPrivacyTooltip');
  String get wellBeauty => get('wellBeauty');
  String get wellHealth => get('wellHealth');
  String get wellMind => get('wellMind');
  String get wellFutureYou => get('wellFutureYou');
  String get wellInsightTitle => get('wellInsightTitle');
  String get wellInsightBody => get('wellInsightBody');
  String get wellViewSkinRoutine => get('wellViewSkinRoutine');
  String get wellTodayActions => get('wellTodayActions');
  String get wellTrend7Days => get('wellTrend7Days');
  String get wellAutoUpdate => get('wellAutoUpdate');
  String get wellMetricWeight => get('wellMetricWeight');
  String get wellMetricSleep => get('wellMetricSleep');
  String get wellMetricActivity => get('wellMetricActivity');
  String get wellMetricMood => get('wellMetricMood');
  String get wellMetricHeart => get('wellMetricHeart');
  String get wellDailyCheckinBtn => get('wellDailyCheckinBtn');
  String get wellChartHiddenPrivacy => get('wellChartHiddenPrivacy');
  String get wellBeautySheetTitle => get('wellBeautySheetTitle');
  String get wellHealthSheetTitle => get('wellHealthSheetTitle');
  String get wellMindSheetTitle => get('wellMindSheetTitle');
  String get wellFutureSheetTitle => get('wellFutureSheetTitle');
  String get wellCheckinSheetTitle => get('wellCheckinSheetTitle');
  String get wellClose => get('wellClose');

  // Wearable & Biometrics
  String get wearableCardTitle => get('wearableCardTitle');
  String get wearableStatusConnected => get('wearableStatusConnected');
  String get wearableStatusDisconnected => get('wearableStatusDisconnected');
  String get wearableLastSynced => get('wearableLastSynced');
  String get wearableSyncNow => get('wearableSyncNow');
  String get wearableManagePermissions => get('wearableManagePermissions');
  String get wearableConsentTitle => get('wearableConsentTitle');
  String get wearableSourceDevice => get('wearableSourceDevice');
  String get wearablePermissionsSubtitle => get('wearablePermissionsSubtitle');
  String get wearablePermSteps => get('wearablePermSteps');
  String get wearablePermSleep => get('wearablePermSleep');
  String get wearablePermHeart => get('wearablePermHeart');
  String get wearablePermWeight => get('wearablePermWeight');
  String get wearablePermCalories => get('wearablePermCalories');
  String get wearableReadinessLabel => get('wearableReadinessLabel');
  String get stylistBiometricBannerTitle => get('stylistBiometricBannerTitle');
  String get stylistBiometricComfortHint => get('stylistBiometricComfortHint');
  String get stylistBiometricActiveHint => get('stylistBiometricActiveHint');

  // Auth
  String get authGetStarted => get('authGetStarted');
  String get authWelcomeTagline => get('authWelcomeTagline');
  String get authWelcomeDesc => get('authWelcomeDesc');
  String get authLoginTitle => get('authLoginTitle');
  String get authLoginSubtitle => get('authLoginSubtitle');
  String get authLoginBtn => get('authLoginBtn');
  String get authSignupTitle => get('authSignupTitle');
  String get authSignupSubtitle => get('authSignupSubtitle');
  String get authSignupBtn => get('authSignupBtn');
  String get authEmailLabel => get('authEmailLabel');
  String get authEmailHint => get('authEmailHint');
  String get authPasswordLabel => get('authPasswordLabel');
  String get authPasswordHint => get('authPasswordHint');
  String get authConfirmPasswordLabel => get('authConfirmPasswordLabel');
  String get authConfirmPasswordHint => get('authConfirmPasswordHint');
  String get authOrWith => get('authOrWith');
  String get authSwitchToSignup => get('authSwitchToSignup');
  String get authSwitchToLogin => get('authSwitchToLogin');
  String get authForgotPassword => get('authForgotPassword');
  String get authForgotTitle => get('authForgotTitle');
  String get authForgotSubtitle => get('authForgotSubtitle');
  String get authForgotBtn => get('authForgotBtn');
  String get authBackToLogin => get('authBackToLogin');
  String get authPwStrengthLabel => get('authPwStrengthLabel');
  String get authPwRuleLen => get('authPwRuleLen');
  String get authPwRuleUpper => get('authPwRuleUpper');
  String get authPwRuleLower => get('authPwRuleLower');
  String get authPwRuleDigit => get('authPwRuleDigit');
  String get authPwRuleSpecial => get('authPwRuleSpecial');
  String get authPwMismatch => get('authPwMismatch');
  String get authCopyrightYear => get('authCopyrightYear');

  // Auth Error & Feedback Getters
  String get authErrEmailAlreadyInUse => get('authErrEmailAlreadyInUse');
  String get authErrWrongPassword => get('authErrWrongPassword');
  String get authErrUserNotFound => get('authErrUserNotFound');
  String get authErrInvalidEmail => get('authErrInvalidEmail');
  String get authErrUserDisabled => get('authErrUserDisabled');
  String get authErrWeakPassword => get('authErrWeakPassword');
  String get authErrNetwork => get('authErrNetwork');
  String get authErrTooManyRequests => get('authErrTooManyRequests');
  String get authErrInvalidCredential => get('authErrInvalidCredential');
  String get authErrGoogleCancelled => get('authErrGoogleCancelled');
  String get authErrAppleCancelled => get('authErrAppleCancelled');
  String get authErrGeneric => get('authErrGeneric');
  String get authResetEmailSent => get('authResetEmailSent');

  // Sessions sub-tab getters
  String get tSess => get('tSess');
  String get sessHeader => get('sessHeader');
  String get sessSubtitle => get('sessSubtitle');
  String get sessTerminateAll => get('sessTerminateAll');
  String get sessCurrentDevice => get('sessCurrentDevice');
  String get sessEmpty => get('sessEmpty');
  String get sessPlatform => get('sessPlatform');
  String get sessOs => get('sessOs');
  String get sessUserAgent => get('sessUserAgent');
  String get sessLoginTime => get('sessLoginTime');
  String get sessLastActive => get('sessLastActive');
  String get sessDelete => get('sessDelete');
  String get sessPrimaryBadge => get('sessPrimaryBadge');
  String get sessBlockedBadge => get('sessBlockedBadge');
  String get sessBlockBtn => get('sessBlockBtn');
  String get sessUnblockBtn => get('sessUnblockBtn');
  String get sessConfirmBlockTitle => get('sessConfirmBlockTitle');
  String get sessConfirmBlockMsg => get('sessConfirmBlockMsg');
  String get sessConfirmUnblockTitle => get('sessConfirmUnblockTitle');
  String get sessConfirmUnblockMsg => get('sessConfirmUnblockMsg');
  String get sessConfirmDeleteTitle => get('sessConfirmDeleteTitle');
  String get sessConfirmDeleteMsg => get('sessConfirmDeleteMsg');
  String get sessConfirmTerminateAllTitle => get('sessConfirmTerminateAllTitle');
  String get sessConfirmTerminateAllMsg => get('sessConfirmTerminateAllMsg');
  String get sessDeviceBlockedNotice => get('sessDeviceBlockedNotice');
  String get sessPrimaryOnlyNotice => get('sessPrimaryOnlyNotice');
  String get sessCopiedToast => get('sessCopiedToast');
  String get sessErrLoad => get('sessErrLoad');
  String get dialogCancel => get('dialogCancel');
  String get dialogConfirm => get('dialogConfirm');

  String formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 2) return get('timeJustNow');
    if (diff.inHours < 1) {
      final m = formatNumber(diff.inMinutes);
      return get('timeMinutesAgo').replaceAll('{n}', m);
    }
    if (diff.inHours < 24) {
      final h = formatNumber(diff.inHours);
      return get('timeHoursAgo').replaceAll('{n}', h);
    }
    final d = formatNumber(diff.inDays);
    return get('timeDaysAgo').replaceAll('{n}', d);
  }

  String authErrorMessage(String code) {
    switch (code) {
      case 'device-blocked':
        return sessDeviceBlockedNotice;
      case 'email-already-in-use':
        return authErrEmailAlreadyInUse;
      case 'wrong-password':
        return authErrWrongPassword;
      case 'user-not-found':
        return authErrUserNotFound;
      case 'invalid-email':
        return authErrInvalidEmail;
      case 'user-disabled':
        return authErrUserDisabled;
      case 'weak-password':
        return authErrWeakPassword;
      case 'network-request-failed':
        return authErrNetwork;
      case 'too-many-requests':
        return authErrTooManyRequests;
      case 'invalid-credential':
        return authErrInvalidCredential;
      case 'google-cancelled':
        return authErrGoogleCancelled;
      case 'apple-cancelled':
        return authErrAppleCancelled;
      default:
        return authErrGeneric;
    }
  }
}

extension AppStringsExtension on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
