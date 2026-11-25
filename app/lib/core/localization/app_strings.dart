import 'package:flutter/material.dart';
import '../utils/digit_formatter.dart';
import 'app_translations_data.dart';
import 'dictionaries/strings_ar.dart';
import 'dictionaries/strings_en.dart';
import 'dictionaries/strings_fa.dart';
import 'dictionaries/strings_tr.dart';

class AppStrings {
  final String localeCode;

  const AppStrings(this.localeCode);

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return AppStrings(locale);
  }

  static String _normalizedLang(String localeCode) =>
      DigitFormatter.normalizeLang(localeCode);

  /// Converts ASCII/Persian/Arabic digits according to the active locale.
  /// Returns Western digits (0-9) for `en` and `tr`, Persian digits for `fa`,
  /// and Eastern Arabic digits for `ar`.
  String formatNumber(Object input) {
    return DigitFormatter.localizeDigits(input, localeCode);
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

  /// Lazy dictionary resolver per language code.
  static Map<String, String>? _dictionaryFor(String lang) {
    switch (lang) {
      case 'fa':
        return stringsFa;
      case 'en':
        return stringsEn;
      case 'ar':
        return stringsAr;
      case 'tr':
        return stringsTr;
      default:
        return null;
    }
  }

  /// In-memory cache for dynamic database translation overrides
  /// (e.g. from Firestore `app_config/translations` or remote CMS).
  static final Map<String, Map<String, String>> _dynamicOverrides = {};

  /// Updates or injects dynamic translations fetched from the database / remote config.
  static void setDynamicOverrides(
    String langCode,
    Map<String, String> overrides,
  ) {
    final normalized = _normalizedLang(langCode);
    _dynamicOverrides[normalized] = {
      ...?_dynamicOverrides[normalized],
      ...overrides,
    };
  }

  /// Clears dynamic translation overrides (useful for testing or cache refresh).
  static void clearDynamicOverrides([String? langCode]) {
    if (langCode != null) {
      _dynamicOverrides.remove(_normalizedLang(langCode));
    } else {
      _dynamicOverrides.clear();
    }
  }

  String get(String key) {
    final lang = _normalizedLang(localeCode);
    final overrideVal =
        _dynamicOverrides[lang]?[key] ?? _dynamicOverrides['en']?[key];
    if (overrideVal != null && overrideVal.isNotEmpty) {
      return overrideVal;
    }
    return _dictionaryFor(lang)?[key] ?? _dictionaryFor('en')?[key] ?? key;
  }

  /// Safely resolves dynamic database-driven keys or fallback value,
  /// allowing zero UI changes when new language columns/keys are added.
  String resolveKey(String key, {String? fallback}) {
    final lang = _normalizedLang(localeCode);
    final overrideVal =
        _dynamicOverrides[lang]?[key] ?? _dynamicOverrides['en']?[key];
    if (overrideVal != null && overrideVal.isNotEmpty) {
      return overrideVal;
    }
    return _dictionaryFor(lang)?[key] ??
        _dictionaryFor('en')?[key] ??
        fallback ??
        key;
  }

  // Dynamic formatted helpers
  String countWithUnit(int count, String unit) =>
      '${formatNumber(count)} $unit';
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

  String walPromoApplied(String code) => get(
    'walPromoToast',
  ).replaceAll('{code}', code).replaceAll('{coins}', coinsText(50));

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
  String get profileSaveErrorToast => get('profileSaveErrorToast');
  String get notificationsTitle => get('notificationsTitle');
  String get markAllRead => get('markAllRead');
  String get noNotifications => get('noNotifications');
  String get notifCatAi => get('notifCatAi');
  String get notifCatShop => get('notifCatShop');
  String get notifCatFinance => get('notifCatFinance');
  String get notifCatAccount => get('notifCatAccount');
  String get notifCatWardrobe => get('notifCatWardrobe');
  String get notifCatWellness => get('notifCatWellness');
  String get notifCatStylist => get('notifCatStylist');
  String get notifCatAtelier => get('notifCatAtelier');
  String get notifCatWallet => get('notifCatWallet');
  String get notifFilterAll => get('notifFilterAll');
  String get notifFilterUnread => get('notifFilterUnread');
  String get notifFilterRead => get('notifFilterRead');
  String get markAsReadTooltip => get('markAsReadTooltip');
  String get deleteNotificationTooltip => get('deleteNotificationTooltip');
  String get newWord => get('newWord');
  String get newUser => get('newUser');

  // Identity
  String get idHeader => get('idHeader');
  String get idFirstName => get('idFirstName');
  String get idFirstNamePlaceholder => get('idFirstNamePlaceholder');
  String get idLastName => get('idLastName');
  String get idLastNamePlaceholder => get('idLastNamePlaceholder');
  String get idNick => get('idNick');
  String get idNickPlaceholder => get('idNickPlaceholder');
  String get idNationalId => get('idNationalId');
  String get idNationalIdPlaceholder => get('idNationalIdPlaceholder');
  String get idDob => get('idDob');
  String get idDobPlaceholder => get('idDobPlaceholder');
  String get idDobAgeRequirement => get('idDobAgeRequirement');
  String get idMobile => get('idMobile');
  String get idMobilePlaceholder => get('idMobilePlaceholder');
  String get idVerifyMobile => get('idVerifyMobile');
  String get commonComingSoon => get('commonComingSoon');
  String get commonGotIt => get('commonGotIt');
  String get idVerifyEmail => get('idVerifyEmail');
  String get idCheckEmailStatus => get('idCheckEmailStatus');
  String get idChangeEmail => get('idChangeEmail');
  String get idSocialEmailNote => get('idSocialEmailNote');
  String get authAppleEmailManagedNote => get('authAppleEmailManagedNote');
  String get idChangeEmailTitle => get('idChangeEmailTitle');
  String get idChangeEmailReauthSubtitle => get('idChangeEmailReauthSubtitle');
  String get idChangeEmailReauthSubtitleGoogle =>
      get('idChangeEmailReauthSubtitleGoogle');
  String get idCurrentPasswordLabel => get('idCurrentPasswordLabel');
  String get idVerifyWithGoogle => get('idVerifyWithGoogle');
  String get idVerifyAndContinue => get('idVerifyAndContinue');
  String get idNewEmailLabel => get('idNewEmailLabel');
  String get idChangeEmailNotice => get('idChangeEmailNotice');
  String get idSendVerificationToNewEmail =>
      get('idSendVerificationToNewEmail');
  String get idChangeEmailSuccessTitle => get('idChangeEmailSuccessTitle');
  String idChangeEmailSuccessDesc(String email) =>
      get('idChangeEmailSuccessDesc').replaceAll('{email}', email);
  String get idLostAccessEmailSupport => get('idLostAccessEmailSupport');
  String get idChangeEmailSameError => get('idChangeEmailSameError');
  String get idChangeEmailInvalidError => get('idChangeEmailInvalidError');
  String get idVerified => get('idVerified');
  String get idEmail => get('idEmail');
  String get idEmailPlaceholder => get('idEmailPlaceholder');
  String get idSendCode => get('idSendCode');
  String get idCodeSentToast => get('idCodeSentToast');
  String get idCountry => get('idCountry');
  String get idCountryPlaceholder => get('idCountryPlaceholder');
  String get idProvince => get('idProvince');
  String get idProvincePlaceholder => get('idProvincePlaceholder');
  String get idCity => get('idCity');
  String get idCityPlaceholder => get('idCityPlaceholder');
  String get idAddress => get('idAddress');
  String get idAddressPlaceholder => get('idAddressPlaceholder');
  String get idZip => get('idZip');
  String get idZipPlaceholder => get('idZipPlaceholder');
  String get idSelectCountry => get('idSelectCountry');
  String get idSelectProvince => get('idSelectProvince');
  String get idSelectCity => get('idSelectCity');
  String get idSelectDialCode => get('idSelectDialCode');
  String get idSearchPlaceholder => get('idSearchPlaceholder');
  String get idUseCustomCity => get('idUseCustomCity');
  String get idErrInvalidNidIran => get('idErrInvalidNidIran');
  String get idErrInvalidNidTurkey => get('idErrInvalidNidTurkey');
  String get idErrInvalidNidInternational =>
      get('idErrInvalidNidInternational');
  String get idErrInvalidZipIran => get('idErrInvalidZipIran');
  String get idErrInvalidZipTurkey => get('idErrInvalidZipTurkey');
  String get idErrInvalidZipInternational =>
      get('idErrInvalidZipInternational');
  String get idErrInvalidMobile => get('idErrInvalidMobile');
  String idAgeYears(int age) {
    final lang = _normalizedLang(localeCode);
    final ageStr = (lang == 'fa' || lang == 'ar')
        ? formatNumber(age)
        : age.toString();
    return get('idAgeYears').replaceAll('{age}', ageStr);
  }

  String get idErrDobInvalid => get('idErrDobInvalid');
  String get idErrDobFuture => get('idErrDobFuture');
  String get idErrFirstName => get('idErrFirstName');
  String get idErrLastName => get('idErrLastName');
  String get idErrValidationSummary => get('idErrValidationSummary');
  String get kycDocTileNationalIdFront => get('kycDocTileNationalIdFront');
  String get kycDocTileNationalIdBack => get('kycDocTileNationalIdBack');
  String get kycDocTilePassportFront => get('kycDocTilePassportFront');
  String get kycDocTilePassportBack => get('kycDocTilePassportBack');
  String get kycDocTileDriversLicenseFront =>
      get('kycDocTileDriversLicenseFront');
  String get kycDocTileDriversLicenseBack =>
      get('kycDocTileDriversLicenseBack');
  String get kycRemoveImage => get('kycRemoveImage');
  String get setChangePasswordTitle => get('setChangePasswordTitle');
  String get setChangePasswordSubtitle => get('setChangePasswordSubtitle');
  String get cpTitle => get('cpTitle');
  String get cpSubtitle => get('cpSubtitle');
  String get cpCurrentPassword => get('cpCurrentPassword');
  String get cpCurrentPasswordPlaceholder =>
      get('cpCurrentPasswordPlaceholder');
  String get cpNewPassword => get('cpNewPassword');
  String get cpNewPasswordPlaceholder => get('cpNewPasswordPlaceholder');
  String get cpConfirmPassword => get('cpConfirmPassword');
  String get cpConfirmPasswordPlaceholder =>
      get('cpConfirmPasswordPlaceholder');
  String get cpSubmit => get('cpSubmit');
  String get cpSuccessToast => get('cpSuccessToast');
  String get cpErrMismatch => get('cpErrMismatch');
  String get cpErrMinLength => get('cpErrMinLength');
  String get cpErrWrongPassword => get('cpErrWrongPassword');
  String get cpForgotPasswordLink => get('cpForgotPasswordLink');
  String get cpResetEmailSent => get('cpResetEmailSent');
  String get cpGoogleUserNote => get('cpGoogleUserNote');
  String get cpSendSetupEmail => get('cpSendSetupEmail');
  String get refTapToShare => get('refTapToShare');
  String get authGeneratePasswordTooltip => get('authGeneratePasswordTooltip');
  String get passwordGeneratedToast => get('passwordGeneratedToast');
  String get appModeLabel => get('appModeLabel');
  String get appModeSimple => get('appModeSimple');
  String get appModeAdvanced => get('appModeAdvanced');
  String get appModeSimpleDesc => get('appModeSimpleDesc');
  String get appModeAdvancedDesc => get('appModeAdvancedDesc');
  String get appModeCardDesc => get('appModeCardDesc');
  String get unsavedChangesTitle => get('unsavedChangesTitle');
  String get unsavedChangesMessage => get('unsavedChangesMessage');
  String get unsavedChangesSaveAndContinue =>
      get('unsavedChangesSaveAndContinue');
  String get unsavedChangesDiscardAndLeave =>
      get('unsavedChangesDiscardAndLeave');
  String get unsavedChangesStay => get('unsavedChangesStay');

  // KYC
  String get kycSectionTitle => get('kycSectionTitle');
  String get kycSectionSubtitle => get('kycSectionSubtitle');
  String get kycStatusNotSubmitted => get('kycStatusNotSubmitted');
  String get kycStatusPending => get('kycStatusPending');
  String get kycStatusVerified => get('kycStatusVerified');
  String get kycStatusRejected => get('kycStatusRejected');
  String get kycVerifiedBadge => get('kycVerifiedBadge');
  String get kycDocNationalId => get('kycDocNationalId');
  String get kycDocPassport => get('kycDocPassport');
  String get kycDocDriversLicense => get('kycDocDriversLicense');
  String get kycSelectDocType => get('kycSelectDocType');
  String get kycUploadFront => get('kycUploadFront');
  String get kycUploadBack => get('kycUploadBack');
  String get kycTakeCamera => get('kycTakeCamera');
  String get kycChooseGallery => get('kycChooseGallery');
  String get kycSubmit => get('kycSubmit');
  String get kycSubmitting => get('kycSubmitting');
  String get kycPreview => get('kycPreview');
  String get kycEdit => get('kycEdit');
  String get kycDelete => get('kycDelete');
  String get kycDeleteConfirmTitle => get('kycDeleteConfirmTitle');
  String get kycDeleteConfirmDesc => get('kycDeleteConfirmDesc');
  String get kycDeleteSuccess => get('kycDeleteSuccess');
  String get kycSubmitSuccess => get('kycSubmitSuccess');
  String get kycRejectionReasonLabel => get('kycRejectionReasonLabel');
  String get kycFrontRequired => get('kycFrontRequired');

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
  String get galPersonaModeTitle => get('galPersonaModeTitle');
  String get galModePrivacy => get('galModePrivacy');
  String get galModePrivacyDesc => get('galModePrivacyDesc');
  String get galModeFullBody => get('galModeFullBody');
  String get galModeFullBodyDesc => get('galModeFullBodyDesc');
  String get galSlotFrontFace => get('galSlotFrontFace');
  String get galSlotSideFace => get('galSlotSideFace');
  String get galSlotBodyFront => get('galSlotBodyFront');
  String get galSlotBodySide => get('galSlotBodySide');
  String get galSlotBodyBack => get('galSlotBodyBack');
  String get galSlotHandSkin => get('galSlotHandSkin');
  String get galSlotScan360 => get('galSlotScan360');
  String get galRequired => get('galRequired');
  String get galOptional => get('galOptional');
  String get galProSlot => get('galProSlot');
  String get galAwaitingUpload => get('galAwaitingUpload');
  String get galClickToScan => get('galClickToScan');
  String get galTakeCameraWithGuide => get('galTakeCameraWithGuide');
  String get galUploadFromGallery => get('galUploadFromGallery');
  String get galAlignmentGuideTitle => get('galAlignmentGuideTitle');
  String get galGuideFrontFace1 => get('galGuideFrontFace1');
  String get galGuideFrontFace2 => get('galGuideFrontFace2');
  String get galGuideFrontFace3 => get('galGuideFrontFace3');
  String get galGuideSideFace1 => get('galGuideSideFace1');
  String get galGuideSideFace2 => get('galGuideSideFace2');
  String get galGuideSideFace3 => get('galGuideSideFace3');
  String get galGuideBodyFront1 => get('galGuideBodyFront1');
  String get galGuideBodyFront2 => get('galGuideBodyFront2');
  String get galGuideBodyFront3 => get('galGuideBodyFront3');
  String get galGuideBodySide1 => get('galGuideBodySide1');
  String get galGuideBodySide2 => get('galGuideBodySide2');
  String get galGuideBodySide3 => get('galGuideBodySide3');
  String get galGuideBodyBack1 => get('galGuideBodyBack1');
  String get galGuideBodyBack2 => get('galGuideBodyBack2');
  String get galGuideBodyBack3 => get('galGuideBodyBack3');
  String get galGuideHandSkin1 => get('galGuideHandSkin1');
  String get galGuideHandSkin2 => get('galGuideHandSkin2');
  String get galGuideHandSkin3 => get('galGuideHandSkin3');
  String get galGuideScan3601 => get('galGuideScan3601');
  String get galGuideScan3602 => get('galGuideScan3602');
  String get galGuideScan3603 => get('galGuideScan3603');
  String get galReadyToCapture => get('galReadyToCapture');
  String get galDeleteConfirmTitle => get('galDeleteConfirmTitle');
  String get galDeleteConfirmDesc => get('galDeleteConfirmDesc');

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

  // AI Anatomy Layers
  String get aiSectionBiometrics => get('aiSectionBiometrics');
  String get aiGenderNonBinary => get('aiGenderNonBinary');
  String get aiBmiLabel => get('aiBmiLabel');
  String get aiBmiUnderweight => get('aiBmiUnderweight');
  String get aiBmiNormal => get('aiBmiNormal');
  String get aiBmiOverweight => get('aiBmiOverweight');
  String get aiBmiObese => get('aiBmiObese');
  String get aiBodySilhouette => get('aiBodySilhouette');
  String get aiSilHourglass => get('aiSilHourglass');
  String get aiSilPear => get('aiSilPear');
  String get aiSilApple => get('aiSilApple');
  String get aiSilRectangle => get('aiSilRectangle');
  String get aiSilInvertedTriangle => get('aiSilInvertedTriangle');
  String get aiSilTrapezoid => get('aiSilTrapezoid');
  String get aiSilOval => get('aiSilOval');

  String get aiSectionColorimetry => get('aiSectionColorimetry');
  String get aiFitzpatrickLabel => get('aiFitzpatrickLabel');
  String get aiFitz1 => get('aiFitz1');
  String get aiFitz2 => get('aiFitz2');
  String get aiFitz3 => get('aiFitz3');
  String get aiFitz4 => get('aiFitz4');
  String get aiFitz5 => get('aiFitz5');
  String get aiFitz6 => get('aiFitz6');
  String get aiUndertone => get('aiUndertone');
  String get aiToneWarm => get('aiToneWarm');
  String get aiToneCool => get('aiToneCool');
  String get aiToneNeutral => get('aiToneNeutral');

  String get aiEyeColor => get('aiEyeColor');
  String get aiEyeBrown => get('aiEyeBrown');
  String get aiEyeHazel => get('aiEyeHazel');
  String get aiEyeGreen => get('aiEyeGreen');
  String get aiEyeBlue => get('aiEyeBlue');
  String get aiEyeGray => get('aiEyeGray');
  String get aiEyeBlack => get('aiEyeBlack');

  String get aiHairProfile => get('aiHairProfile');
  String get aiHairColor => get('aiHairColor');
  String get aiHairLength => get('aiHairLength');
  String get aiHairBlack => get('aiHairBlack');
  String get aiHairDarkBrown => get('aiHairDarkBrown');
  String get aiHairLightBrown => get('aiHairLightBrown');
  String get aiHairBlonde => get('aiHairBlonde');
  String get aiHairAuburn => get('aiHairAuburn');
  String get aiHairGray => get('aiHairGray');
  String get aiHairDyed => get('aiHairDyed');
  String get aiHairShort => get('aiHairShort');
  String get aiHairMedium => get('aiHairMedium');
  String get aiHairLong => get('aiHairLong');
  String get aiHairBald => get('aiHairBald');
  String get aiHairCurly => get('aiHairCurly');
  String get aiHairWavy => get('aiHairWavy');
  String get aiHairStraight => get('aiHairStraight');

  String get aiFaceOval => get('aiFaceOval');
  String get aiFaceRound => get('aiFaceRound');
  String get aiFaceSquare => get('aiFaceSquare');
  String get aiFaceHeart => get('aiFaceHeart');
  String get aiFaceOblong => get('aiFaceOblong');

  String get aiAnthropometricHeader => get('aiAnthropometricHeader');
  String get aiAnthropometricSub => get('aiAnthropometricSub');
  String get aiShoulderHint => get('aiShoulderHint');
  String get aiChestHint => get('aiChestHint');
  String get aiBraSize => get('aiBraSize');
  String get aiBraBand => get('aiBraBand');
  String get aiBraCup => get('aiBraCup');
  String get aiWaistHint => get('aiWaistHint');
  String get aiBellyHint => get('aiBellyHint');
  String get aiHipsHint => get('aiHipsHint');
  String get aiSleeve => get('aiSleeve');
  String get aiSleeveHint => get('aiSleeveHint');
  String get aiInseam => get('aiInseam');
  String get aiInseamHint => get('aiInseamHint');
  String get aiNeck => get('aiNeck');
  String get aiNeckHint => get('aiNeckHint');
  String get aiShoeSize => get('aiShoeSize');
  String get aiShoeSizeHint => get('aiShoeSizeHint');

  String get aiFitPrefHeader => get('aiFitPrefHeader');
  String get aiFitSlim => get('aiFitSlim');
  String get aiFitSlimDesc => get('aiFitSlimDesc');
  String get aiFitRegular => get('aiFitRegular');
  String get aiFitRegularDesc => get('aiFitRegularDesc');
  String get aiFitRelaxed => get('aiFitRelaxed');
  String get aiFitRelaxedDesc => get('aiFitRelaxedDesc');

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
  String get refShare => get('refShare');
  String get refSharedToast => get('refSharedToast');
  String get refEmptyFriends => get('refEmptyFriends');
  String get refTierStarter => get('refTierStarter');
  String get refTierSilver => get('refTierSilver');
  String get refTierGold => get('refTierGold');
  String get refTierAmbassador => get('refTierAmbassador');
  String get authReferralCodeLabel => get('authReferralCodeLabel');
  String get authReferralCodeHint => get('authReferralCodeHint');
  String get authReferralSelfError => get('authReferralSelfError');
  String get authReferralInvalidError => get('authReferralInvalidError');

  String getTierLabel(String tier) {
    switch (tier.toLowerCase()) {
      case 'silver':
        return refTierSilver;
      case 'gold':
        return refTierGold;
      case 'ambassador':
        return refTierAmbassador;
      case 'starter':
      default:
        return refTierStarter;
    }
  }

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
  String get setShowEmailInHeader => get('setShowEmailInHeader');
  String get rankBronze => get('rankBronze');
  String get rankSilver => get('rankSilver');
  String get rankGold => get('rankGold');
  String get rankDiamond => get('rankDiamond');
  String get loyaltyTitle => get('loyaltyTitle');
  String get pts => get('pts');
  String pointsToNextRank(String count) =>
      get('pointsToNextRank').replaceAll('{pts}', count);
  String get maxRankReached => get('maxRankReached');
  String get howToEarnPoints => get('howToEarnPoints');
  String get earnProfileRule => get('earnProfileRule');
  String get earnEmailRule => get('earnEmailRule');
  String get earnReferralRule => get('earnReferralRule');
  String get earnAiRule => get('earnAiRule');
  String get earnWalletRule => get('earnWalletRule');
  String get loyaltyPerksTitle => get('loyaltyPerksTitle');
  String get perkBronze => get('perkBronze');
  String get perkSilver => get('perkSilver');
  String get perkGold => get('perkGold');
  String get perkDiamond => get('perkDiamond');
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
  String get wardCatAll => get('wardCatAll');
  String get wardCatTops => get('wardCatTops');
  String get wardCatBottoms => get('wardCatBottoms');
  String get wardCatOutfit => get('wardCatOutfit');
  String get wardCatOuterwear => get('wardCatOuterwear');
  String get wardCatUnderwear => get('wardCatUnderwear');
  String get wardCatActivewear => get('wardCatActivewear');
  String get wardCatFootwear => get('wardCatFootwear');
  String get wardCatBags => get('wardCatBags');
  String get wardCatJewelry => get('wardCatJewelry');
  String get wardCatAccessories => get('wardCatAccessories');
  String get wardCatHintTops => get('wardCatHintTops');
  String get wardCatHintBottoms => get('wardCatHintBottoms');
  String get wardCatHintOutfit => get('wardCatHintOutfit');
  String get wardCatHintOuterwear => get('wardCatHintOuterwear');
  String get wardCatHintUnderwear => get('wardCatHintUnderwear');
  String get wardCatHintActivewear => get('wardCatHintActivewear');
  String get wardCatHintFootwear => get('wardCatHintFootwear');
  String get wardCatHintBags => get('wardCatHintBags');
  String get wardCatHintJewelry => get('wardCatHintJewelry');
  String get wardCatHintAccessories => get('wardCatHintAccessories');
  String get wardMultiSelectFilter => get('wardMultiSelectFilter');
  String get wardPrimaryPhoto => get('wardPrimaryPhoto');
  String get wardAngle2Photo => get('wardAngle2Photo');
  String get wardAngle3Photo => get('wardAngle3Photo');
  String get wardAddAngle => get('wardAddAngle');
  String wardMultiAngleCount(int count) =>
      get('wardMultiAngleCount').replaceAll('{count}', formatNumber(count));

  String wardrobeCategoryName(String code) {
    switch (code.toLowerCase()) {
      case 'all':
        return wardCatAll;
      case 'tops':
      case 'top':
        return wardCatTops;
      case 'bottoms':
      case 'bottom':
        return wardCatBottoms;
      case 'outfit':
      case 'full_outfit':
      case 'dress':
        return wardCatOutfit;
      case 'outerwear':
        return wardCatOuterwear;
      case 'underwear':
      case 'loungewear':
        return wardCatUnderwear;
      case 'activewear':
        return wardCatActivewear;
      case 'footwear':
      case 'shoes':
        return wardCatFootwear;
      case 'bags':
      case 'bag':
        return wardCatBags;
      case 'jewelry':
        return wardCatJewelry;
      case 'accessories':
      case 'accessory':
        return wardCatAccessories;
      case 'cl':
        return wardCatCl;
      case 'sh':
        return wardCatSh;
      case 'bg':
        return wardCatBg;
      case 'jw':
        return wardCatJw;
      case 'ac':
        return wardCatAc;
      default:
        return tr(code);
    }
  }

  String wardrobeCategoryHint(String code) {
    switch (code.toLowerCase()) {
      case 'tops':
      case 'cl':
      case 'top':
        return wardCatHintTops;
      case 'bottoms':
      case 'bottom':
        return wardCatHintBottoms;
      case 'outfit':
      case 'full_outfit':
      case 'dress':
        return wardCatHintOutfit;
      case 'outerwear':
        return wardCatHintOuterwear;
      case 'underwear':
      case 'loungewear':
        return wardCatHintUnderwear;
      case 'activewear':
        return wardCatHintActivewear;
      case 'footwear':
      case 'sh':
      case 'shoes':
        return wardCatHintFootwear;
      case 'bags':
      case 'bg':
      case 'bag':
        return wardCatHintBags;
      case 'jewelry':
      case 'jw':
        return wardCatHintJewelry;
      case 'accessories':
      case 'ac':
      case 'accessory':
        return wardCatHintAccessories;
      default:
        return '';
    }
  }

  String get wardItemUnit => get('wardItemUnit');
  String get wardCapacityWord => get('wardCapacityWord');
  String get wardArchive => get('wardArchive');
  String get wardArchiveEmpty => get('wardArchiveEmpty');
  String get wardNotFound => get('wardNotFound');
  String get wardEmptyState => get('wardEmptyState');
  String get wardAddFirstItem => get('wardAddFirstItem');
  String get wardApplyFilters => get('wardApplyFilters');
  String get wardFilterSheetTitle => get('wardFilterSheetTitle');
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
  String get wardPhotoRequired => get('wardPhotoRequired');
  String get wardPhotoRequiredInline => get('wardPhotoRequiredInline');
  String get wardItemNameRequired => get('wardItemNameRequired');
  String get wardSaving => get('wardSaving');
  String get wardLoadMore => get('wardLoadMore');
  String get wardPickFromGallery => get('wardPickFromGallery');
  String get wardTakePhoto => get('wardTakePhoto');
  String get wardChangePhoto => get('wardChangePhoto');
  String get wardRemovePhoto => get('wardRemovePhoto');
  String get wardUploadError => get('wardUploadError');
  String get wardPayloadTooLarge => get('wardPayloadTooLarge');
  String get wardEditItem => get('wardEditItem');
  String get wardEditSheetTitle => get('wardEditSheetTitle');
  String get wardSaveChanges => get('wardSaveChanges');
  String get wardItemUpdated => get('wardItemUpdated');

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
  String shopTryOnSent(String name) => get(
    'shopTryOnSentToast',
  ).replaceAll('{name}', name).replaceAll('{coins}', coinsText(5));
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

  // Email verification getters
  String get authEmailVerifyTitle => get('authEmailVerifyTitle');
  String get authEmailVerifyDesc => get('authEmailVerifyDesc');
  String get authEmailCheckBtn => get('authEmailCheckBtn');
  String get authEmailResendBtn => get('authEmailResendBtn');
  String authEmailResendCooldown(int seconds) {
    final lang = _normalizedLang(localeCode);
    final secStr = (lang == 'fa' || lang == 'ar')
        ? formatNumber(seconds)
        : seconds.toString();
    return get('authEmailResendCooldown').replaceAll('{s}', secStr);
  }

  String get authEmailNotVerifiedYet => get('authEmailNotVerifiedYet');
  String get authVerificationEmailSent => get('authVerificationEmailSent');
  String get authBackOrSignOut => get('authBackOrSignOut');
  String get emailVerificationBannerTitle =>
      get('emailVerificationBannerTitle');
  String get emailVerificationBannerDesc => get('emailVerificationBannerDesc');
  String get emailVerificationSoftGateTitle =>
      get('emailVerificationSoftGateTitle');
  String get emailVerificationSoftGateDesc =>
      get('emailVerificationSoftGateDesc');
  String get emailVerificationGoToProfile =>
      get('emailVerificationGoToProfile');
  String get emailVerificationSuccessToast =>
      get('emailVerificationSuccessToast');
  String get idUnverified => get('idUnverified');

  // Turnstile getters
  String get authTurnstilePrompt => get('authTurnstilePrompt');
  String get authTurnstileRequired => get('authTurnstileRequired');
  String get authTurnstileChecking => get('authTurnstileChecking');
  String get authVerificationCloudflare => get('authVerificationCloudflare');
  String get authVerificationMath => get('authVerificationMath');
  String get authFallbackSecurityTitle => get('authFallbackSecurityTitle');
  String get authFallbackVerified => get('authFallbackVerified');
  String get authFallbackAnswerHint => get('authFallbackAnswerHint');
  String authFallbackMathQuestion(int a, int b) {
    final lang = _normalizedLang(localeCode);
    final aStr = (lang == 'fa' || lang == 'ar')
        ? formatNumber(a)
        : a.toString();
    final bStr = (lang == 'fa' || lang == 'ar')
        ? formatNumber(b)
        : b.toString();
    return get(
      'authFallbackMathQuestion',
    ).replaceAll('{a}', aStr).replaceAll('{b}', bStr);
  }

  String get authRememberMe => get('authRememberMe');
  String get authSessionExpired => get('authSessionExpired');
  String get authSessionTerminatedConcurrent =>
      get('authSessionTerminatedConcurrent');
  String authLockoutCooldown(int seconds) {
    final lang = _normalizedLang(localeCode);
    final secStr = (lang == 'fa' || lang == 'ar')
        ? formatNumber(seconds)
        : seconds.toString();
    return get('authLockoutCooldown').replaceAll('{s}', secStr);
  }

  String authLockoutBtn(int seconds) {
    final lang = _normalizedLang(localeCode);
    final secStr = (lang == 'fa' || lang == 'ar')
        ? formatNumber(seconds)
        : seconds.toString();
    return get('authLockoutBtn').replaceAll('{s}', secStr);
  }

  // Biometric lock getters
  String get setBiometricTitle => get('setBiometricTitle');
  String get setBiometricDesc => get('setBiometricDesc');
  String get setBiometricAuthReason => get('setBiometricAuthReason');
  String get setBiometricMobileOnly => get('setBiometricMobileOnly');
  String get setBiometricUnlockBtn => get('setBiometricUnlockBtn');
  String get setBiometricLockedTitle => get('setBiometricLockedTitle');
  String get setBiometricLockedDesc => get('setBiometricLockedDesc');

  // Sessions sub-tab getters
  String get tSess => get('tSess');
  String get sessHeader => get('sessHeader');
  String get sessSubtitle => get('sessSubtitle');
  String get sessTerminateAll => get('sessTerminateAll');
  String get sessCurrentDevice => get('sessCurrentDevice');
  String get sessEmpty => get('sessEmpty');
  String get sessPlatform => get('sessPlatform');
  String get sessIpAddress => get('sessIpAddress');
  String get sessIpLocation => get('sessIpLocation');
  String get commonUnavailable => get('commonUnavailable');
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
  String get sessConfirmTerminateAllTitle =>
      get('sessConfirmTerminateAllTitle');
  String get sessConfirmTerminateAllMsg => get('sessConfirmTerminateAllMsg');
  String get sessDeviceBlockedNotice => get('sessDeviceBlockedNotice');
  String get sessPrimaryOnlyNotice => get('sessPrimaryOnlyNotice');
  String get sessCopiedToast => get('sessCopiedToast');
  String get sessErrLoad => get('sessErrLoad');
  String get dialogCancel => get('dialogCancel');
  String get dialogConfirm => get('dialogConfirm');

  // About & Updates sub-tab getters
  String get tAbout => get('tAbout');
  String get aboutHeader => get('aboutHeader');
  String get aboutTagline => get('aboutTagline');
  String get aboutMission => get('aboutMission');
  String get aboutVersionLabel => get('aboutVersionLabel');
  String get aboutBuildLabel => get('aboutBuildLabel');
  String get aboutReleaseDateLabel => get('aboutReleaseDateLabel');
  String get aboutReleaseDateVal => get('aboutReleaseDateVal');
  String get aboutEnvironmentLabel => get('aboutEnvironmentLabel');
  String get aboutEnvironmentVal => get('aboutEnvironmentVal');
  String get aboutEnvironmentPreview => get('aboutEnvironmentPreview');
  String get aboutEnvironmentStaging => get('aboutEnvironmentStaging');
  String get aboutCheckUpdatesBtn => get('aboutCheckUpdatesBtn');
  String get aboutChecking => get('aboutChecking');
  String get aboutUpToDate => get('aboutUpToDate');
  String get aboutUpdateAvailable => get('aboutUpdateAvailable');
  String get aboutUpdateActionWeb => get('aboutUpdateActionWeb');
  String get aboutUpdateActionMobile => get('aboutUpdateActionMobile');
  String get aboutWhatsNewTitle => get('aboutWhatsNewTitle');
  String get aboutChangelog1Title => get('aboutChangelog1Title');
  String get aboutChangelog1Desc => get('aboutChangelog1Desc');
  String get aboutChangelog2Title => get('aboutChangelog2Title');
  String get aboutChangelog2Desc => get('aboutChangelog2Desc');
  String get aboutChangelog3Title => get('aboutChangelog3Title');
  String get aboutChangelog3Desc => get('aboutChangelog3Desc');
  String get aboutChangelog4Title => get('aboutChangelog4Title');
  String get aboutChangelog4Desc => get('aboutChangelog4Desc');
  String get aboutChangelog5Title => get('aboutChangelog5Title');
  String get aboutChangelog5Desc => get('aboutChangelog5Desc');
  String get aboutLegalSectionTitle => get('aboutLegalSectionTitle');
  String get aboutTermsTitle => get('aboutTermsTitle');
  String get aboutPrivacyTitle => get('aboutPrivacyTitle');
  String get aboutLicensesTitle => get('aboutLicensesTitle');
  String get aboutAgreementTitle => get('aboutAgreementTitle');
  String get aboutAgreementDesc => get('aboutAgreementDesc');
  String get aboutAgreementCheckbox => get('aboutAgreementCheckbox');
  String get aboutAgreementSignBtn => get('aboutAgreementSignBtn');
  String get aboutOpenContractBtn => get('aboutOpenContractBtn');
  String get aboutContractModalTitle => get('aboutContractModalTitle');
  String get aboutCancelSignBtn => get('aboutCancelSignBtn');
  String get aboutAgreementSignedBadge => get('aboutAgreementSignedBadge');
  String get aboutAgreementSignedDate => get('aboutAgreementSignedDate');
  String get aboutAgreementSignedToast => get('aboutAgreementSignedToast');
  String get aboutAgreementUnsignedWarning =>
      get('aboutAgreementUnsignedWarning');
  String get aboutAuditReceiptTitle => get('aboutAuditReceiptTitle');
  String get aboutAuditVerifiedBadge => get('aboutAuditVerifiedBadge');
  String get aboutAuditSignedAt => get('aboutAuditSignedAt');
  String get aboutAuditSignerName => get('aboutAuditSignerName');
  String get aboutAuditSignerEmail => get('aboutAuditSignerEmail');
  String get aboutAuditSignerUid => get('aboutAuditSignerUid');
  String get aboutAuditContractVer => get('aboutAuditContractVer');
  String get aboutAuditIpLoc => get('aboutAuditIpLoc');
  String get aboutAuditDevice => get('aboutAuditDevice');
  String get aboutAuditNotRecorded => get('aboutAuditNotRecorded');
  String get aboutAuditDocHash => get('aboutAuditDocHash');
  String get aboutAuditHashLegacy => get('aboutAuditHashLegacy');
  String get legalTabTerms => get('legalTabTerms');
  String get legalTabPrivacy => get('legalTabPrivacy');
  String get legalTabLegalInfo => get('legalTabLegalInfo');
  String get legalSummaryTitle => get('legalSummaryTitle');
  String get legalExpandAll => get('legalExpandAll');
  String get legalCollapseAll => get('legalCollapseAll');
  String get legalDisputeResolutionTitle => get('legalDisputeResolutionTitle');
  String get aboutContactSectionTitle => get('aboutContactSectionTitle');
  String get aboutSocialMediaLabel => get('aboutSocialMediaLabel');
  String get aboutSocialMediaSubtitle => get('aboutSocialMediaSubtitle');
  String get aboutTelegramOfficial => get('aboutTelegramOfficial');
  String get aboutTelegramMain => get('aboutTelegramMain');
  String get aboutTelegramCommunity => get('aboutTelegramCommunity');
  String get aboutTelegramBot => get('aboutTelegramBot');
  String get aboutSearchLicensesHint => get('aboutSearchLicensesHint');
  String get aboutLicensesCount => get('aboutLicensesCount');
  String get aboutLicenseSingular => get('aboutLicenseSingular');
  String get aboutNoLicensesFound => get('aboutNoLicensesFound');
  String get aboutLoadingLicenses => get('aboutLoadingLicenses');
  String get aboutWebsiteLabel => get('aboutWebsiteLabel');
  String get aboutEmailLabel => get('aboutEmailLabel');
  String get aboutInstagramLabel => get('aboutInstagramLabel');
  String get aboutTelegramLabel => get('aboutTelegramLabel');
  String get aboutCopyrightNotice => get('aboutCopyrightNotice');
  String get aboutLinkCopied => get('aboutLinkCopied');
  String get aboutClose => get('aboutClose');

  // Phase 4: AI Quality-Control & Verification
  String get aiStatusReviewing => get('aiStatusReviewing');
  String get aiStatusApproved => get('aiStatusApproved');
  String get aiStatusRejected => get('aiStatusRejected');
  String get aiStatusManualReview => get('aiStatusManualReview');
  String get aiIssueFileTooLarge => get('aiIssueFileTooLarge');
  String get aiIssueUnsupportedFormat => get('aiIssueUnsupportedFormat');
  String get aiIssueLowResolution => get('aiIssueLowResolution');
  String get aiIssueBlurryOrDark => get('aiIssueBlurryOrDark');
  String get aiIssueMissingSubject => get('aiIssueMissingSubject');
  String get aiIssuePolicyViolation => get('aiIssuePolicyViolation');

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
