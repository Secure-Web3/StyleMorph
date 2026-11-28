import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Structured clause model for legal document sections.
class LegalClause {
  final int number;
  final String title;
  final String shortSummary;
  final String body;

  const LegalClause({
    required this.number,
    required this.title,
    required this.shortSummary,
    required this.body,
  });
}

/// Key point summary item.
class LegalKeyPoint {
  final String headline;
  final String detail;

  const LegalKeyPoint({required this.headline, required this.detail});
}

/// Provider information / Impressum entry.
class LegalInfoEntry {
  final String label;
  final String value;

  const LegalInfoEntry({required this.label, required this.value});
}

/// Canonical Legal Document Version 2.0 (Terms of Service, Privacy Policy & Impressum).
class LegalDocumentV2 {
  static const String version = 'v2.0';

  // ---------------------------------------------------------------------------
  // Canonical English Document Text & Deterministic SHA-256 Hash
  // ---------------------------------------------------------------------------

  static final String _canonicalEnglishFullText = _buildCanonicalFullText();
  static final String sha256Hash = sha256
      .convert(utf8.encode(_canonicalEnglishFullText))
      .toString();

  static String _buildCanonicalFullText() {
    final buffer = StringBuffer();
    buffer.writeln('STYLEMORPH LEGAL AGREEMENT & PRIVACY POLICY');
    buffer.writeln('VERSION: $version');
    buffer.writeln('========================================');
    buffer.writeln('\nPART A: TERMS OF SERVICE');
    for (final clause in englishTermsClauses) {
      buffer.writeln('\n${clause.number}. ${clause.title}');
      buffer.writeln('Summary: ${clause.shortSummary}');
      buffer.writeln(clause.body);
    }
    buffer.writeln('\n========================================');
    buffer.writeln('\nPART B: PRIVACY POLICY & DATA PROTECTION');
    for (final clause in englishPrivacyClauses) {
      buffer.writeln('\n${clause.number}. ${clause.title}');
      buffer.writeln('Summary: ${clause.shortSummary}');
      buffer.writeln(clause.body);
    }
    buffer.writeln('\n========================================');
    buffer.writeln('\nPART C: PROVIDER INFORMATION & IMPRESSUM');
    for (final entry in englishLegalInfoEntries) {
      buffer.writeln('${entry.label}: ${entry.value}');
    }
    buffer.writeln('Dispute Resolution: $englishDisputeResolutionNotice');
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // 7 Key Summary Points (Localized)
  // ---------------------------------------------------------------------------

  static List<LegalKeyPoint> getKeyPoints(String localeCode) {
    switch (localeCode) {
      case 'fa':
        return faKeyPoints;
      case 'ar':
        return arKeyPoints;
      case 'tr':
        return trKeyPoints;
      default:
        return englishKeyPoints;
    }
  }

  static const List<LegalKeyPoint> englishKeyPoints = [
    LegalKeyPoint(
      headline: '13+ only',
      detail:
          'Must be at least 13 years old; AI image and video features work only with your own face and body.',
    ),
    LegalKeyPoint(
      headline: 'Your photos are yours',
      detail:
          'Processed strictly to deliver requested features; never sold, never brokered, and never used to train public AI models.',
    ),
    LegalKeyPoint(
      headline: 'No medical advice',
      detail:
          'Wellness, skin, hair, and body insights are advisory lifestyle estimations, not medical diagnosis or clinical treatment.',
    ),
    LegalKeyPoint(
      headline: 'AI content is labeled',
      detail:
          'All generative AI outputs carry a permanent "AI-generated" digital label and watermark that must not be removed or concealed.',
    ),
    LegalKeyPoint(
      headline: 'StyleCoin is prepaid credit, not money',
      detail:
          'Prepaid utility tokens do not expire; fees are transparently quoted before generation, and uncompleted jobs are automatically refunded.',
    ),
    LegalKeyPoint(
      headline: 'Merchants are independent',
      detail:
          'Partner boutiques and external brands are solely responsible for payment, fulfillment, shipping, product warranty, and returns.',
    ),
    LegalKeyPoint(
      headline: 'You are in control',
      detail:
          'Delete individual photos or purge your entire account directly inside the app, revoke consents anytime, and request data exports.',
    ),
  ];

  static const List<LegalKeyPoint> faKeyPoints = [
    LegalKeyPoint(
      headline: 'فقط ۱۳ سال به بالا',
      detail:
          'استفاده از اپلیکیشن منوط به داشتن حداقل ۱۳ سال است؛ قابلیت‌های هوش مصنوعی منحصراً با چهره و اندام خود کاربر مجاز است.',
    ),
    LegalKeyPoint(
      headline: 'تصاویر متعلق به شماست',
      detail:
          'تصاویر صرفاً برای اجرای درخواست‌های شما پردازش شده و هرگز فروخته نشده و برای آموزش مدل‌های عمومی هوش مصنوعی به کار نمی‌روند.',
    ),
    LegalKeyPoint(
      headline: 'سلب مسئولیت پزشکی',
      detail:
          'تحلیل‌های سبک زندگی، پوست و تناسب اندام جنبه مشاوره‌ای زیبایی دارند و هرگز توصیه، تشخیص یا درمان پزشکی محسوب نمی‌شوند.',
    ),
    LegalKeyPoint(
      headline: 'نشانه‌گذاری محتوای هوش مصنوعی',
      detail:
          'کلیه تصاویر و ویدیوهای تولیدی دارای نشان و برچسب دائمی تولیدشده با هوش مصنوعی (AI-Generated) هستند که نباید پنهان شود.',
    ),
    LegalKeyPoint(
      headline: 'استایل‌کوین اعتبار مصرفی است',
      detail:
          'اعتبار درون‌برنامه‌ای فاقد تاریخ انقضاست؛ هزینه پیش از پردازش تایید شده و در صورت بروز خطای فنی سکه‌ها بلافاصله بازمی‌گردند.',
    ),
    LegalKeyPoint(
      headline: 'فروشگاه‌های همکار مستقل هستند',
      detail:
          'فروشندگان کالاها مسئولیت کامل تراکنش، انبارداری، اصالت فیزیکی، ارسال، گارانتی و رویه مرجوعی اجناس را مستقلاً بر عهده دارند.',
    ),
    LegalKeyPoint(
      headline: 'مدیریت و کنترل کامل داده‌ها',
      detail:
          'امکان حذف تصاویر، استخراج داده‌ها و پاکسازی آنی و دائمی کل حساب کاربری در هر لحظه از داخل تنظیمات پروفایل فراهم است.',
    ),
  ];

  static const List<LegalKeyPoint> arKeyPoints = [
    LegalKeyPoint(
      headline: 'للمستخدمين بعمر +١٣ فقط',
      detail:
          'يجب ألا يقل عمر المستخدم عن ١٣ عاماً؛ استخدام ميزات الذكاء الاصطناعي مسموح به فقط لوجه المستخدم وهيئته الشخصية.',
    ),
    LegalKeyPoint(
      headline: 'صورك ملك خالص لك',
      detail:
          'تُعالج الصور حصرياً لتقديم الميزات المطلوبة، ولا تُباع أبداً ولا تُستخدم لتدريب نماذج الذكاء الاصطناعي العامة.',
    ),
    LegalKeyPoint(
      headline: 'إخلاء مسؤولية طبي كامل',
      detail:
          'تحليلات المظهر والبشرة والعناية هي تقديرات استشارية لنمط الحياة، وليست تشخيصاً أو استشارة طبية أو علاجية بأي شكل.',
    ),
    LegalKeyPoint(
      headline: 'وسم محتوى الذكاء الاصطناعي',
      detail:
          'تحمل جميع المخرجات التوليدية وسماً وعلامة رقمية دائمة تفيد بأنها مولدة بالذكاء الاصطناعي ولا يجوز طمسها أو إزالتها.',
    ),
    LegalKeyPoint(
      headline: 'عملات StyleCoin رصيد مدفوع مسبقاً',
      detail:
          'رصيد الاستخدام الداخلي لا تنتهي صلاحيته؛ يتم توضيح التكلفة قبل المعالجة ويسترد الرصيد تلقائياً في حال فشل التوليد.',
    ),
    LegalKeyPoint(
      headline: 'المتاجر الشريكة مستقلة',
      detail:
          'المتاجر الخارجية مسؤولة مسؤولية كاملة ومستقلة عن الشحن والدفع وجودة المنتجات وسياسات الاستبدال والاسترجاع.',
    ),
    LegalKeyPoint(
      headline: 'أنت صاحب القرار دائماً',
      detail:
          'يمكنك حذف الصور بشكل فردي أو مسح حسابك وبياناتك نهائياً وفورياً من داخل إعدادات التطبيق وتصدير بياناتك متى شئت.',
    ),
  ];

  static const List<LegalKeyPoint> trKeyPoints = [
    LegalKeyPoint(
      headline: 'Yalnızca 13+ Yaş',
      detail:
          'Kullanıcılar en az 13 yaşında olmalıdır; yapay zeka görsel özellikleri yalnızca kendi yüzünüz ve bedeninizle kullanılabilir.',
    ),
    LegalKeyPoint(
      headline: 'Fotoğraflarınız Size Aittir',
      detail:
          'Görseller sadece talep edilen stilleri üretmek için işlenir; asla satılmaz ve genel yapay zeka modellerini eğitmekte kullanılmaz.',
    ),
    LegalKeyPoint(
      headline: 'Tıbbi Tavsiye İçermez',
      detail:
          'Sağlık, cilt ve stil içgörüleri stilistik tahminlerdir; kesinlikle tıbbi tanı, klinik teşhis veya tedavi tavsiyesi değildir.',
    ),
    LegalKeyPoint(
      headline: 'Yapay Zeka İçeriği Etiketlidir',
      detail:
          'Tüm çıktılar kalıcı "AI-Generated" dijital filigranı taşır ve bu işaretin kaldırılması veya gizlenmesi yasaktır.',
    ),
    LegalKeyPoint(
      headline: 'StyleCoin Ön Ödemeli Kredidir',
      detail:
          'Kullanım kredilerinin süresi dolmaz; maliyet işlem öncesinde bildirilir ve teknik hata halinde paralar anında iade edilir.',
    ),
    LegalKeyPoint(
      headline: 'Satıcılar Bağımsızdır',
      detail:
          'Bağlantılı harici mağazalar ödeme, kargolama, ürün garantisi ve iade süreçlerinden münferiden ve münhasıran sorumludur.',
    ),
    LegalKeyPoint(
      headline: 'Kontrol Tamamen Sizde',
      detail:
          'Fotoğrafları veya tüm hesabınızı dilediğiniz an uygulama içerisinden silebilir, izinleri geri alabilir ve veri kopyanızı talep edebilirsiniz.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Tab 1: Terms of Service Clauses (Sections 1–22)
  // ---------------------------------------------------------------------------

  static List<LegalClause> getTermsClauses(String localeCode) {
    switch (localeCode) {
      case 'fa':
        return faTermsClauses;
      case 'ar':
        return arTermsClauses;
      case 'tr':
        return trTermsClauses;
      default:
        return englishTermsClauses;
    }
  }

  static const List<LegalClause> englishTermsClauses = [
    LegalClause(
      number: 1,
      title: 'Scope & Electronic Acceptance',
      shortSummary:
          'Binding agreement covering all StyleMorph platforms, recorded with immutable audit metadata.',
      body:
          'By accessing, downloading, or using the StyleMorph mobile app, responsive web application, or associated services, you enter into a legally binding contract with StyleMorph. Your acceptance is electronically logged with UTC timestamp, account UID, contract version, canonical SHA-256 document hash, and network device telemetry. If you do not agree to these Terms, you must immediately cease using the platform.',
    ),
    LegalClause(
      number: 2,
      title: 'Age Eligibility (Strictly 13+)',
      shortSummary:
          'Platform use is restricted to individuals aged 13 years or older.',
      body:
          'StyleMorph is intended for individuals who are at least 13 years of age (or the minimum digital consent age in your jurisdiction). Individuals under 13 years of age are strictly prohibited from creating accounts, uploading photographs, or utilizing generative AI features, even with parental or guardian consent. Accounts found to belong to users under 13 will be terminated immediately and associated biometric and photo records purged.',
    ),
    LegalClause(
      number: 3,
      title: 'Account Security & Session Management',
      shortSummary:
          'Maximum 5 concurrent sessions, primary device oversight, and 14-day idle expiration.',
      body:
          'You are solely responsible for safeguarding your credentials and authorized devices. StyleMorph allows up to 5 concurrent active sessions per user account, with designated Primary Device authority to inspect and remotely revoke secondary sessions. Inactive sessions automatically expire after 14 days of idle status. StyleMorph enforces a Soft Gate registration policy: general browsing is open, but high-compute generative synthesis and wallet operations strictly require email verification.',
    ),
    LegalClause(
      number: 4,
      title: 'Service Overview & Fair-Use Limits',
      shortSummary:
          'Virtual try-on, digital atelier, and stylist services governed by technical fair-use limits.',
      body:
          'StyleMorph provides personal AI styling, virtual fitting rooms, digital wardrobe organization, and creative atelier outputs. To ensure high availability and equitable platform access, StyleMorph applies automated rate limits, bandwidth throttles, and concurrency queues. Automated scraping, botting, bulk generation scripts, or reverse-engineering attempts are strictly prohibited.',
    ),
    LegalClause(
      number: 5,
      title: 'AI Processing & Auto-Refund on Failure',
      shortSummary:
          'Generative synthesis runs asynchronously with automatic coin refund on technical errors.',
      body:
          'Generative AI requests are queued and processed asynchronously. Processing requires temporary reservation of StyleCoins (Hold). If a generation request encounters a technical error, service timeout, or automated safety filter rejection, the reserved coins are immediately released and returned to your available wallet balance without charge.',
    ),
    LegalClause(
      number: 6,
      title: 'Your Content & Limited Revocable License',
      shortSummary:
          'You retain full ownership; granted license is limited strictly to delivering requested features.',
      body:
          'You retain 100% full intellectual property rights and ownership over all original photographs, garment images, styling notes, and profile assets you upload. You grant StyleMorph only a worldwide, limited, revocable, non-exclusive license strictly necessary to host, process, and render your requested styling features. Your content is never used for public advertising and is never used to train foundational AI models.',
    ),
    LegalClause(
      number: 7,
      title: 'AI Outputs, Watermarks & Personal Use',
      shortSummary:
          'AI-generated outputs carry permanent watermarks and are licensed for personal non-commercial use.',
      body:
          'Content generated by StyleMorph generative models is provided for your personal, non-commercial entertainment and styling inspiration. All synthetic portraits, garment try-on renders, and videos embed a permanent digital watermark and metadata tag indicating AI generation. Tampering with, stripping, or concealing these synthetic identifiers is strictly forbidden.',
    ),
    LegalClause(
      number: 8,
      title: 'Acceptable Use & Anti-Deepfake Policy',
      shortSummary:
          'Strict prohibition of third-party imagery without consent, synthetic impersonation, and NSFW material.',
      body:
          'You represent and warrant that you upload only photographs of yourself or images for which you possess verified express written permission. Utilizing StyleMorph for synthetic identity manipulation, non-consensual imagery, deepfakes, defamatory depictions, harassment, or adult/NSFW content is unconditionally prohibited and leads to immediate account ban and law enforcement escalation.',
    ),
    LegalClause(
      number: 9,
      title: 'Wellness & Beauty Non-Medical Disclaimer',
      shortSummary:
          'Wellness, skin, and body recommendations are aesthetic lifestyle estimates only.',
      body:
          'All analyses, scores, and recommendations within the Wellness & Beauty module (including skin appearance, body shape estimates, color harmony, and hair simulations) are automated lifestyle and cosmetic estimates. They DO NOT constitute medical, dermatological, clinical, nutritional, or psychiatric advice, and must never substitute for examination by a licensed medical practitioner.',
    ),
    LegalClause(
      number: 10,
      title: 'Safety Review, Reports & Human Appeal',
      shortSummary:
          'Multi-tier safety screening with right to request human appeal for disputed moderation actions.',
      body:
          'StyleMorph deploys automated vision-based safety classifiers to protect users against malicious content. Flagged content may be routed to authorized compliance personnel under strict audit logs. If your generation or account is suspended due to an automated false positive, you hold the right to request manual human review by emailing support@stylemorph.app.',
    ),
    LegalClause(
      number: 11,
      title: 'StyleCoin Economy (Hold / Capture Cycle)',
      shortSummary:
          'Internal prepaid utility tokens (~\$0.02 USD reference value) operating on atomic transactions.',
      body:
          'StyleCoin is an internal prepaid digital utility token used exclusively to meter computing power for generative AI services. StyleCoins are not fiat currency, securities, or redeemable cryptocurrency. Indicative reference value is approximately \$0.02 USD per coin. Transactions follow an atomic Hold -> Capture / Release lifecycle, ensuring you are billed only for successfully delivered AI outputs.',
    ),
    LegalClause(
      number: 12,
      title: 'Purchases, Statutory Withdrawal & Refunds',
      shortSummary:
          'Purchased through Apple, Google, or authorized Web providers; 14-day statutory right of withdrawal.',
      body:
          'In-app purchases are fulfilled via Apple App Store, Google Play, or authorized web payment providers (such as Stripe, Paddle, and crypto processors where available). European Union and UK consumers hold a statutory 14-day right of withdrawal for unused coin packages. Once coins have been consumed for completed AI generations, the statutory withdrawal right ceases for the consumed portion. In the event of service discontinuation, StyleMorph will provide at least 60 days advance notice.',
    ),
    LegalClause(
      number: 13,
      title: 'Promotions, Referrals & Loyalty Ranks',
      shortSummary:
          'StylePoints and loyalty tiers (Bronze, Silver, Gold, Diamond) with promotional coin terms.',
      body:
          'StyleMorph offers promotional coin drops, referral incentives, and loyalty tiers based on StylePoints (Bronze: 0–499, Silver: 500–1499, Gold: 1500–3999, Diamond: 4000+). Promotional coins hold no cash value, may carry campaign-specific expiration dates, and cannot be transferred between accounts.',
    ),
    LegalClause(
      number: 14,
      title: 'Independent Merchants & External Links',
      shortSummary:
          'Apparel links connect to independent third-party retailers responsible for commerce fulfillment.',
      body:
          'The StyleMorph Shop module curates links to third-party apparel merchants, designer boutiques, and affiliate partners. StyleMorph does not warehouse, sell, or ship physical garments. All purchases, returns, warranty claims, and shipping inquiries are governed solely by the independent merchant terms of sale.',
    ),
    LegalClause(
      number: 15,
      title: 'Service Availability & Modifications',
      shortSummary:
          '99% targeted availability; maintenance and feature evolutions may occur without prior notice.',
      body:
          'StyleMorph strives for high continuous availability but does not guarantee uninterrupted operation. We reserve the right to perform scheduled maintenance, apply security patches, and modify or deprecate specific generative models to improve system performance and safety standards.',
    ),
    LegalClause(
      number: 16,
      title: 'Limitation of Liability (German Statutory Law)',
      shortSummary:
          'Structured liability adhering to German law: uncapped for intent and gross negligence.',
      body:
          'StyleMorph is liable without limitation for damages caused with intent or gross negligence, in cases of injury to life, limb, or health, and under the German Product Liability Act (ProdHaftG). For simple negligence, liability is limited strictly to typical and foreseeable contractual damages arising from the breach of essential contractual duties (cardinal duties).',
    ),
    LegalClause(
      number: 17,
      title: 'Account Deletion & Contract Termination',
      shortSummary:
          'Terminate anytime in-app via Profile Settings with immediate and irrevocable data erasure.',
      body:
          'You may terminate your agreement with StyleMorph at any time by triggering account deletion via Profile > Settings or by contacting support@stylemorph.app. Upon termination, your active sessions, uploaded photos, digital wardrobe assets, and personal profile fields are immediately and permanently erased from live databases.',
    ),
    LegalClause(
      number: 18,
      title: 'Modifications to These Terms',
      shortSummary:
          'Material changes announced with 30-day advance notice; continued use constitutes consent.',
      body:
          'We may update these Terms to reflect technical enhancements, economic adjustments, or legislative requirements. For material updates, you will receive in-app notice at least 30 days prior to the effective date. Your continued access to StyleMorph following the effective date signifies your full acceptance of the updated Terms.',
    ),
    LegalClause(
      number: 19,
      title: 'Governing Law & Dispute Jurisdiction',
      shortSummary:
          'Governed by the laws of Germany; consumer home jurisdictions preserved under EU regulations.',
      body:
          'These Terms and any contractual disputes shall be governed exclusively by the laws of the Federal Republic of Germany, excluding the UN Convention on Contracts for the International Sale of Goods (CISG). For business entities, the exclusive place of jurisdiction is Germany. If you are an EU consumer, mandatory consumer protection laws and courts of your habitual residence remain unaffected.',
    ),
    LegalClause(
      number: 20,
      title: 'General Provisions & Language Precedence',
      shortSummary:
          'English canonical text prevails over translations; severability clause applies.',
      body:
          'The English-language version of these Terms represents the canonical, legally binding document. Localized translations (including Persian, Arabic, and Turkish) are provided for convenience and scannability; in the event of ambiguity, the English text prevails unless local mandatory consumer law mandates otherwise. If any clause is deemed invalid, the remaining clauses remain fully effective.',
    ),
    LegalClause(
      number: 21,
      title: 'Additional Terms for iOS Devices (Apple EULA)',
      shortSummary:
          'Mandatory terms acknowledging Apple is not party to these Terms and has no warranty liability.',
      body:
          'If you use StyleMorph on an iOS device, you acknowledge that these Terms are concluded solely between you and StyleMorph, not with Apple Inc. Apple has no obligation whatsoever to furnish maintenance or support for the app. In the event of any failure of the app to conform to applicable warranty, you may notify Apple for a purchase price refund; to the maximum extent permitted by applicable law, Apple holds no other warranty obligation.',
    ),
    LegalClause(
      number: 22,
      title: 'Official Legal Contact',
      shortSummary:
          'Reach our dedicated compliance and support team directly at support@stylemorph.app.',
      body:
          'For legal notices, compliance queries, rights requests, or dispute notifications, please contact our legal desk via email at support@stylemorph.app. We respond to all formal inquiries within statutory timeframes.',
    ),
  ];

  static const List<LegalClause> faTermsClauses = [
    LegalClause(
      number: 1,
      title: 'دامنه خدمات و پذیرش الکترونیکی',
      shortSummary:
          'قرارداد الزام‌آور حقوقی با ثبت متادیتای ممیزی تغییرناپذیر شامل زمان UTC و هش اسناد.',
      body:
          'استفاده از اپلیکیشن یا وب‌سایت StyleMorph به منزله انعقاد قرارداد الزام‌آور حقوقی است. پذیرش شما با ثبت زمان دقیق UTC، شناسه کاربری، نسخه قرارداد، هش امنیتی SHA-256 و مشخصات دستگاه ذخیره می‌گردد. در صورت عدم موافقت، استفاده از سرویس باید متوقف شود.',
    ),
    LegalClause(
      number: 2,
      title: 'شرایط سنی (حداقل ۱۳ سال)',
      shortSummary:
          'استفاده از سامانه برای افراد دارای ۱۳ سال تمام یا بیشتر مجاز است.',
      body:
          'استفاده از کلیه امکانات StyleMorph منحصراً برای کاربران با حداقل سن ۱۳ سال تمام مجاز است. عضویت و بارگذاری تصویر توسط افراد زیر ۱۳ سال حتی با رضایت والدین اکیداً ممنوع بوده و در صورت مشاهده، حساب کاربری و تصاویر فوراً پاکسازی خواهند شد.',
    ),
    LegalClause(
      number: 3,
      title: 'امنیت حساب، نشست‌ها و دروازه نرم',
      shortSummary:
          'حداکثر ۵ نشست فعال هم‌زمان، نظارت دستگاه اصلی و انقضای ۱۴ روزه نشست‌های غیرفعال.',
      body:
          'کاربر مسئول حفظ محرمانگی گذرواژه خود است. کاربر مجاز به داشتن حداکثر ۵ نشست فعال هم‌زمان است و دستگاه اصلی توانایی بازرسی و لغو نشست‌ها را دارد. نشست‌های غیرفعال پس از ۱۴ روز خودکار منقضی می‌شوند. عملیات مالی و پردازش‌های سنگین مستلزم تایید نشانی ایمیل است.',
    ),
    LegalClause(
      number: 4,
      title: 'مرور خدمات و حدود استفاده منصفانه',
      shortSummary:
          'پرو مجازی، استایل شخصی و کمد دیجیتال مشمول قوانین خودکار نرخ و سقف مصرف منصفانه.',
      body:
          'خدمات StyleMorph شامل مشاوره استایل، پرو مجازی لباس و آتلیه پرتره است. به منظور حفظ پایداری سیستم، سقف استفاده منصفانه و صف‌های پردازشی خودکار اعمال می‌شود. هرگونه ربات، اسکرپینگ یا مهندسی معکوس ممنوع است.',
    ),
    LegalClause(
      number: 5,
      title: 'پردازش هوش مصنوعی و بازگشت خودکار سکه',
      shortSummary:
          'پردازش ناهمگام با آزادسازی و استرداد فوری سکه‌ها در صورت بروز خطای فنی یا فیلتر ایمنی.',
      body:
          'درخواست‌های هوش مصنوعی پس از رزرو موقت سکه (Hold) پردازش می‌شوند. در صورتی که پردازش به دلیل خطای سرور، اتمام زمان یا فیلترهای خودکار ایمنی متوقف شود، سکه‌های رزرو شده بلافاصله و بدون کسر کارمزد به کیف پول بازگردانده می‌شوند.',
    ),
    LegalClause(
      number: 6,
      title: 'مالکیت محتوای کاربر و مجوز محدود',
      shortSummary:
          'مالکیت کامل تصاویر متعلق به شماست و هرگز برای تبلیغات یا آموزش هوش مصنوعی به کار نمی‌رود.',
      body:
          'کاربر مالکیت کامل تصاویر ورودی و لباس‌های کمد دیجیتال خود را حفظ می‌کند. مجوزی که به StyleMorph اعطا می‌شود صرفاً محدود به پردازش فنی همان درخواست است. تصاویر شما فروخته نشده و برای آموزش مدل‌های عمومی هوش مصنوعی استفاده نمی‌شوند.',
    ),
    LegalClause(
      number: 7,
      title: 'خروجی‌های هوش مصنوعی و برچسب دائمی',
      shortSummary:
          'محتوای تولیدی دارای نشان دائمی AI-Generated بوده و مختص استفاده شخصی غیرتجاری است.',
      body:
          'خروجی‌های تصویری و شبیه‌سازی‌ها برای الهام و استفاده شخصی غیرتجاری ارائه می‌شوند. تمامی خروجی‌ها حاوی برچسب و واترمارک دائمی دیجیتال هوش مصنوعی هستند. هرگونه پاک کردن یا مخدوش ساختن این برچسب‌ها تخلف محسوب می‌شود.',
    ),
    LegalClause(
      number: 8,
      title: 'استفاده مجاز و خط‌مشی ضد جعل عمیق',
      shortSummary:
          'ممنوعیت بارگذاری تصویر اشخاص ثالث بدون رضایت، جعل هویت (دیپ‌فیک) و محتوای غیراخلاقی.',
      body:
          'کاربر متعهد است فقط عکس‌های چهره و اندام خود را بارگذاری نماید. تولید جعل عمیق (دیپ‌فیک)، استفاده از تصاویر دیگران بدون رضایت، ساخت محتوای مستهجن، توهین‌آمیز یا سوءاستفاده از کودکان اکیداً ممنوع بوده و موجب انسداد آنی و پیگرد قانونی خواهد شد.',
    ),
    LegalClause(
      number: 9,
      title: 'سلب مسئولیت پزشکی بخش سلامت و زیبایی',
      shortSummary:
          'توصیه‌های پوست، مو و تناسب اندام جنبه زیبایی دارد و جایگزین درمان پزشکی نیست.',
      body:
          'تحلیل‌های بخش سلامت و زیبایی شامل برآورد کیفیت پوست، فرم چهره و هماهنگی رنگ‌ها صرفاً راهنمایی‌های زیبایی و استایل هستند. این اطلاعات به هیچ وجه نظر، تشخیص یا تجویز پزشکی و درماتولوژی نبوده و نباید جایگزین پزشک متخصص گردد.',
    ),
    LegalClause(
      number: 10,
      title: 'بررسی ایمنی، گزارش تخلف و تجدیدنظر',
      shortSummary:
          'سیستم پایش هوشمند با امکان درخواست بازبینی دستی انسانی برای موارد مسدود شده.',
      body:
          'سیستم‌های خودکار طبقه‌بندی ایمنی برای جلوگیری از محتوای غیرمجاز فعال هستند. چنانچه تولید تصویری به اشتباه توسط سیستم مسدود شود، کاربر می‌تواند از طریق مکاتبه با support@stylemorph.app تقاضای بازبینی انسانی نماید.',
    ),
    LegalClause(
      number: 11,
      title: 'اقتصاد استایل‌کوین (چرخه Hold / Capture)',
      shortSummary:
          'اعتبار درون‌برنامه‌ای (~۰.۰۲ دلار مرجع) با تضمین کسر وجه فقط پس از تحویل موفق خروجی.',
      body:
          'استایل‌کوین یک توکن اعتباری پیش‌پرداخت درون‌برنامه‌ای برای پرداخت توان پردازشی هوش مصنوعی است و ماهیت پول رسمی یا رمزارز ندارد. کسر قطعی سکه تنها پس از تکمیل و تحویل موفق خروجی بصری صورت می‌گیرد.',
    ),
    LegalClause(
      number: 12,
      title: 'خرید سکه، حق انصراف و استرداد وجه',
      shortSummary:
          'خرید از طریق اپ استور، گوگل پلی یا وب؛ مهلت انصراف ۱۴ روزه اتحادیه اروپا برای سکه‌های مصرف‌نشده.',
      body:
          'خرید سکه از طریق اپ استور اپل، گوگل پلی یا درگاه‌های معتبر وب انجام می‌گیرد. کاربران حوزه اتحادیه اروپا از حق قانونی ۱۴ روز انصراف برای بسته‌های مصرف‌نشده برخوردارند. در صورت تصمیم بر توقف خدمات، اطلاعیه ۶۰ روز قبل صادر خواهد شد.',
    ),
    LegalClause(
      number: 13,
      title: 'سکه‌های هدیه، معرف‌ها و سطوح وفاداری',
      shortSummary:
          'امتیازهای استایل و سطوح برنزی، نقره‌ای، طلایی و الماسی با شرایط سکه‌های تبلیغاتی.',
      body:
          'سامانه سطوح وفاداری بر اساس استایل‌پوینت ارائه می‌کند (برنز: ۰-۴۹۹، نقره: ۵۰۰-۱۴۹۹، طلا: ۱۵۰۰-۳۹۹۹، الماس: +۴۰۰۰). سکه‌های تشویقی و جوایز معرف فاقد ارزش نقدی بوده و قابل انتقال به دیگران نیستند.',
    ),
    LegalClause(
      number: 14,
      title: 'فروشگاه‌های همکار و پیوندهای خارجی',
      shortSummary:
          'لینک‌های خرید کالا به فروشگاه‌های مستقل متصل است و مسئولیت ارسال با فروشنده است.',
      body:
          'بخش فروشگاه پیوندهایی به برندها و خرده‌فروشان لباس ارائه می‌دهد. StyleMorph مسئولیتی در قبال قیمت‌گذاری، انبارداری، اصالت فیزیکی، تحویل پستی و گارانتی کالاهای فیزیکی ندارد و این موارد تابع ضوابط فروشنده مربوطه است.',
    ),
    LegalClause(
      number: 15,
      title: 'دسترس‌پذیری و تغییرات نرم‌افزاری',
      shortSummary:
          'تلاش برای پایداری حداکثری؛ به‌روزرسانی مدل‌ها و تعمیرات دوره‌ای بدون اطلاع قبلی.',
      body:
          'سامانه می‌کوشد بالاترین سطح پایداری را ارائه نماید اما عملکرد بدون وقفه را تضمین نمی‌کند. ما حق اعمال اصلاحات فنی، بهینه‌سازی الگوریتم‌ها و ارتقای مدل‌های هوش مصنوعی را برای خود محفوظ می‌داریم.',
    ),
    LegalClause(
      number: 16,
      title: 'حدود مسئولیت قانونی (قوانین آلمان)',
      shortSummary:
          'مسئولیت قانونی طبق قوانین آلمان با مسئولیت کامل برای تقصیر عمده یا آسیب جانی.',
      body:
          'مسئولیت StyleMorph در موارد عمد، تقصیر فاحش یا آسیب به حیات و سلامت مطابق قوانین آلمان نامحدود است. در موارد قصور جزئی، مسئولیت صرفاً محدود به خسارات مستقیم و قابل پیش‌بینی ناشی از نقض تعهدات اساسی قرارداد است.',
    ),
    LegalClause(
      number: 17,
      title: 'حذف حساب کاربری و پایان عضویت',
      shortSummary:
          'امکان حذف آنی و برگشت‌ناپذیر حساب و داده‌ها در هر زمان از منوی تنظیمات پروفایل.',
      body:
          'کاربر در هر زمان می‌تواند با ورود به تنظیمات پروفایل یا از طریق ایمیل، حساب خود را برای همیشه حذف کند. با این اقدام، کلیه تصاویر، کمد دیجیتال و اطلاعات هویتی به صورت برگشت‌ناپذیر پاکسازی می‌شوند.',
    ),
    LegalClause(
      number: 18,
      title: 'تغییرات و به‌روزرسانی شرایط استفاده',
      shortSummary:
          'اعلام تغییرات مهم حداقل ۳۰ روز قبل؛ ادامه استفاده به منزله پذیرش نسخه جدید است.',
      body:
          'در صورت اعمال تغییرات اساسی در این ضوابط، اطلاعیه درون‌برنامه‌ای حداقل ۳۰ روز پیش از اجرا به اطلاع کاربران خواهد رسید. ادامه فعالیت پس از آن به منزله قبول کامل شرایط جدید است.',
    ),
    LegalClause(
      number: 19,
      title: 'قانون حاکم و صلاحیت قضایی',
      shortSummary:
          'حاکمیت قوانین جمهوری فدرال آلمان با حفظ حقوق الزامی مصرف‌کنندگان اتحادیه اروپا.',
      body:
          'این شرایط تابع قوانین جمهوری فدرال آلمان (به استثنای کنوانسیون بیع بین‌المللی کالا) است. برای شرکت‌ها و تجار، دادگاه‌های آلمان صالح به رسیدگی هستند؛ حقوق الزامی مصرف‌کنندگان طبق قوانین کشور متبوع حفظ می‌گردد.',
    ),
    LegalClause(
      number: 20,
      title: 'اعتبار زبان و تفکیک‌پذیری مفاد',
      shortSummary:
          'متن انگلیسی سند دارای وجاهت قانونی اصلی است؛ تفکیک‌پذیری بندهای باطل.',
      body:
          'متن زبان انگلیسی این سند نسخه کانونیکال و معیار قانونی است. ترجمه‌های ارائه شده به زبان‌های دیگر صرفاً برای تسهیل مطالعه است. در صورت ابطال یک بند، سایر بندها به قوت قانونی خود باقی می‌مانند.',
    ),
    LegalClause(
      number: 21,
      title: 'شرایط الحاقی کاربران iOS (اپل)',
      shortSummary:
          'توافق منحصراً میان کاربر و StyleMorph منعقد شده و اپل مسئولیتی در پشتیبانی ندارد.',
      body:
          'کاربران دستگاه‌های اپل تایید می‌کنند که این توافق صرفاً با StyleMorph است نه با شرکت Apple Inc. شرکت اپل تعهدی به نگهداری، پشتیبانی فنی یا پاسخگویی به دعاوی مربوط به اپلیکیشن ندارد.',
    ),
    LegalClause(
      number: 22,
      title: 'راه‌های ارتباطی و مکاتبات حقوقی',
      shortSummary:
          'ارتباط مستقیم با دپارتمان حقوقی و پشتیبانی رسمی از طریق support@stylemorph.app.',
      body:
          'برای هرگونه ابهام، اخطار حقوقی یا درخواست اعمال حقوق کاربران، می‌توانید از طریق پست الکترونیکی رسمی support@stylemorph.app با دپارتمان حقوقی در ارتباط باشید.',
    ),
  ];

  static const List<LegalClause> arTermsClauses = [
    LegalClause(
      number: 1,
      title: 'نطاق الخدمة والموافقة الإلكترونية',
      shortSummary:
          'اتفاقية قانونية ملزمة مدعومة ببيانات تدقيق غير قابلة للتغيير وتوقيت UTC وتشفير SHA-256.',
      body:
          'يشكل استخدامك لتطبيق أو منصة StyleMorph عقداً ملزماً قانوناً. يتم تسجيل موافقتك إلكترونياً مع توقيت UTC الدقيق، ومعرف الحساب، وإصدار العقد، وبصمة SHA-256، وبيانات الجهاز المعتمدة.',
    ),
    LegalClause(
      number: 2,
      title: 'الأهلية القانونية (١٣+ عاماً)',
      shortSummary:
          'يقتصر استخدام الخدمة على الأشخاص البالغين من عمر ١٣ عاماً فما فوق.',
      body:
          'الخدمة مخصصة لمن بلغوا ١٣ عاماً على الأقل. يُحظر تماماً على من هم دون ١٣ عاماً إنشاء حسابات أو رفع صور، حتى بموافقة ولي الأمر، وسيتم مسح الحسابات والصور المخالفة فوراً.',
    ),
    LegalClause(
      number: 3,
      title: 'أمان الحساب وإدارة الجلسات',
      shortSummary:
          'حد أقصى ٥ جلسات نشطة، وإشراف الجهاز الرئيسي، وانتهاء الجلسة بعد ١٤ يوماً من الخمول.',
      body:
          'يتحمل المستخدم سرية حسابه. يُسمح بـ ٥ أجهزة كحد أقصى، مع إمكانية إنهاء الجلسات عبر الجهاز الأساسي، وتنتهي الجلسات غير النشطة بعد ١٤ يوماً. التحقق من البريد إلزامي للميزات المتقدمة.',
    ),
    LegalClause(
      number: 4,
      title: 'حدود الاستخدام العادل والمخرجات',
      shortSummary:
          'تنسيق الأزياء والقياس الافتراضي يخضع لقيود تقنية عادلة لحماية أداء المنصة.',
      body:
          'تقدم المنصة تجربة قياس افتراضية واستشارات مظهر. لضمان الجودة، تطبق حدود استخدام عادل ويحظر أي تجريف آلي أو هندسة عكسية للمنصة.',
    ),
    LegalClause(
      number: 5,
      title: 'معالجة الذكاء الاصطناعي والاسترداد التلقائي',
      shortSummary:
          'استرداد فوري وتلقائي للرصيد المحجوز في حال حدوث أي خطأ فني أو حظر أمان.',
      body:
          'تتم معالجة الطلبات بعد حجز مؤقت للعملات (Hold). إذا تعثرت العملية بسبب عطل تقني أو فلاتر السلامة التلقائية، تُعاد العملات المحجوزة لحسابك فوراً دون خصم.',
    ),
    LegalClause(
      number: 6,
      title: 'ملكية محتوى المستخدم والترخيص المحدود',
      shortSummary:
          'تحتفظ بكامل ملكية صورك ولا تُستخدم أبداً للإعلانات أو تدريب الذكاء الاصطناعي.',
      body:
          'تحتفظ بكامل الملكية الفكرية لصورك وخزانتك الرقمية. الترخيص الممنوح لـ StyleMorph مقصور حصرياً على تنفيذ طلبك ولا تُباع بياناتك أو تُستخدم لتدريب نماذج عامة.',
    ),
    LegalClause(
      number: 7,
      title: 'مخرجات الذكاء الاصطناعي والعلامة المائية',
      shortSummary:
          'تحمل المخرجات علامة رقمية دائمة تفيد بتوليدها آلياً وهي للاستخدام الشخصي غير التجاري.',
      body:
          'المخرجات مخصصة للاستخدام الشخصي والإلهام في المظهر. تحتوي جميع الصور على وسم رقمي دائم (AI-Generated)، ويُحظر قانوناً إزالة أو حجب هذا الوسم.',
    ),
    LegalClause(
      number: 8,
      title: 'الاستخدام المقبول ومكافحة التزييف العميق',
      shortSummary:
          'حظر صور الآخرين دون إذن، ومنع التزييف العميق والمحتوى غير اللائق بشكل قاطع.',
      body:
          'يقر المستخدم برفع صوره الشخصية فقط. يُحظر تماماً التزييف العميق (Deepfake)، أو انتحال الشخصيات، أو رفع محتوى مسيء، ويعرض الحساب للحظر النهائي الفوري.',
    ),
    LegalClause(
      number: 9,
      title: 'إخلاء المسؤولية الطبية للعناية والمظهر',
      shortSummary:
          'تحليلات البشرة والشعر والمظهر استشارية تجميلية ولا تعد استشارة طبية بأي حال.',
      body:
          'تحليلات العناية والمظهر واللون هي تقديرات استشارية لنمط الحياة وليست نصائح طبية أو جلدية، ولا تغني مطلقاً عن مراجعة الطبيب المختص.',
    ),
    LegalClause(
      number: 10,
      title: 'مراجعة الأمان والطعن البشري',
      shortSummary:
          'فلاتر سلامة ذكية مع إمكانية طلب مراجعة يدوية بشرية في حال الاعتراض على الحظر.',
      body:
          'تخضع المنصة لمصنفات أمان ذكية. إذا حُجب محتوى نتيجة خطأ آلي، يحق للمستخدم طلب مراجعة يدوية عبر التواصل مع support@stylemorph.app.',
    ),
    LegalClause(
      number: 11,
      title: 'اقتصاد StyleCoin ودورة الحجز والخصم',
      shortSummary:
          'رصيد مسبق الدفع (بقيمة مرجعية ٠.٠٢ دولار) مع خصم نهائي فقط عند نجاح التسليم.',
      body:
          'عملات StyleCoin هي رصيد مسبق الدفع لحساب طاقة المعالجة وليست نقوداً رسمية. يتم الخصم النهائي حصرياً بعد نجاح توليد الصورة وتسليمها.',
    ),
    LegalClause(
      number: 12,
      title: 'شراء الرصيد، حق التراجع والاسترداد',
      shortSummary:
          'شراء عبر المتاجر المعتمدة وحق تراجع لمدة ١٤ يوماً للعملات غير المستهلكة في الاتحاد الأوروبي.',
      body:
          'تتم المشتريات عبر متجر أبل أو جوجل أو الويب. يتمتع مستخدمو الاتحاد الأوروبي بحق تراجع قانوني لمدة ١٤ يوماً للعملات غير المستخدمة.',
    ),
    LegalClause(
      number: 13,
      title: 'العملات الترويجية ومستويات الولاء',
      shortSummary:
          'نقاط استايل ورتب برونزية وفضية وذهبية وماسية خاضعة لشروط الاستخدام الداخلي.',
      body:
          'يوفر التطبيق رتب ولاء (برونزي، فضي، ذهبي، ماسي). المكافآت الترويجية ليس لها قيمة نقدية ولا يمكن تحويلها بين الحسابات.',
    ),
    LegalClause(
      number: 14,
      title: 'المتاجر المستقلة وروابط التسوق',
      shortSummary:
          'الروابط تنقلك لمتاجر خارجية مسؤولة وحدها عن المنتجات والشحن والضمان.',
      body:
          'يربط قسم المتجر بمواقع متاجر خارجية مستقلة. لا تتحمل StyleMorph مسؤولية الشحن أو الجودة أو الاسترجاع للسلع المادية المباعة من أطراف ثالثة.',
    ),
    LegalClause(
      number: 15,
      title: 'توفر الخدمة والتحديثات التقنية',
      shortSummary:
          'السعي لجاهزية قصوى مع حق الصيانة الدورية وتحديث نماذج الذكاء الاصطناعي.',
      body:
          'نحرص على أعلى مستوى جاهزية ولكن لا نضمن التشغيل بلا انقطاع. نحتفظ بحق إجراء الصيانة وتطوير النماذج دون إشعار مسبق.',
    ),
    LegalClause(
      number: 16,
      title: 'حدود المسؤولية القانونية (القانون الألماني)',
      shortSummary:
          'مسؤولية غير محدودة عن الإهمال الجسيم والضرر البدني بموجب القانون الألماني.',
      body:
          'تتحمل StyleMorph المسؤولية الكاملة عن الإهمال الجسيم أو التعمد أو الأضرار بالصحة والحياة وفق القانون الألماني، وتقتصر في غير ذلك على الأضرار المباشرة المتوقعة.',
    ),
    LegalClause(
      number: 17,
      title: 'حذف الحساب وإنهاء الخدمة',
      shortSummary:
          'حذف فوري ودائم للحساب والصور في أي وقت من خلال إعدادات الملف الشخصي.',
      body:
          'يمكنك إنهاء حسابك ومسحه نهائياً في أي وقت عبر إعدادات التطبيق، مما يؤدي لمسح جميع صورك وخزانتك وسجلاتك نهائياً من الخوادم.',
    ),
    LegalClause(
      number: 18,
      title: 'تعديلات الشروط والأحكام',
      shortSummary:
          'إشعار مسبق قبل ٣٠ يوماً من أي تعديل جوهري؛ استمرار الاستخدام يعد قبولاً.',
      body:
          'في حال تحديث الشروط بشكل جوهري، يُرسل إشعار داخل التطبيق قبل ٣٠ يوماً من سريانها. استمرارك بعد ذلك يعتبر موافقة كاملة عليها.',
    ),
    LegalClause(
      number: 19,
      title: 'القانون الواجب التطبيق والاختصاص القضائي',
      shortSummary:
          'يخضع لقوانين جمهورية ألمانيا الاتحادية مع مراعاة حقوق المستهلك الأوروبي الإلزامية.',
      body:
          'تخضع هذه الشروط لقوانين جمهورية ألمانيا الاتحادية. بالنسبة للشركات يكون الاختصاص لمحاكم ألمانيا، مع الحفاظ على حقوق المستهلك الإلزامية في موطنه.',
    ),
    LegalClause(
      number: 20,
      title: 'أسبقية النص الإنجليزي وفصل البنود',
      shortSummary:
          'النص الإنجليزي هو المعيار القانوني المعتمد في حال أي اختلاف في الترجمة.',
      body:
          'النسخة الإنجليزية هي المرجع القانوني الملزم، والترجمات هي للتوضيح فقط. بطلان أي بند لا يؤثر على سريان وصحة باقي بنود العقد.',
    ),
    LegalClause(
      number: 21,
      title: 'شروط إضافية لأجهزة آبل (Apple EULA)',
      shortSummary:
          'الاتفاقية مع StyleMorph فقط وشركة آبل ليست طرفاً ولا تقدم خدمات الدعم للتطبيق.',
      body:
          'يقر مستخدمو iOS بأن الاتفاقية منعقدة مع StyleMorph فقط، وأن شركة آبل غير مسؤولة عن الصيانة أو الضمان أو مطالبات الخدمة.',
    ),
    LegalClause(
      number: 22,
      title: 'بيانات التواصل القانوني الرسمي',
      shortSummary:
          'للاستفسارات والطلبات القانونية عبر البريد: support@stylemorph.app.',
      body:
          'لأي إشعارات رسمية أو استفسارات حقوقية، يرجى مراسلة فريقنا القانوني عبر: support@stylemorph.app.',
    ),
  ];

  static const List<LegalClause> trTermsClauses = [
    LegalClause(
      number: 1,
      title: 'Hizmet Kapsamı ve Elektronik Kabul',
      shortSummary:
          'UTC zaman damgası, SHA-256 özeti ve cihaz telemetrisi ile kaydedilen bağlayıcı sözleşme.',
      body:
          'StyleMorph hizmetlerini kullanarak bu Koşulları yasal olarak kabul etmiş sayılırsınız. Kabulünüz; UTC zaman damgası, kullanıcı kimliği, sürüm numarası, kanonik SHA-256 özeti ve cihaz verileriyle doğrulanabilir biçimde saklanır.',
    ),
    LegalClause(
      number: 2,
      title: 'Yaş Uygunluğu (13+ Yaş)',
      shortSummary:
          'Platform yalnızca 13 yaş ve üzerindeki kullanıcılar için geçerlidir.',
      body:
          'StyleMorph en az 13 yaşını doldurmuş bireyler içindir. 13 yaşından küçüklerin ebeveyn onayı olsa dahi hesap açması ve görsel yüklemesi yasaktır; tespit edilen hesaplar derhal silinir.',
    ),
    LegalClause(
      number: 3,
      title: 'Hesap Güvenliği ve Oturum Yönetimi',
      shortSummary:
          'En fazla 5 aktif cihaz, ana cihaz denetimi ve 14 günlük hareketsizlik süresi.',
      body:
          'Kullanıcı kimlik bilgilerinin güvenliğinden sorumludur. Eşzamanlı en fazla 5 aktif oturuma izin verilir; ana cihaz diğer oturumları denetleyebilir ve sonlandırabilir. 14 gün işlem görmeyen oturumlar kapatılır.',
    ),
    LegalClause(
      number: 4,
      title: 'Hizmet Genel Bakışı ve Adil Kullanım',
      shortSummary:
          'Sanal prova ve yapay zeka stilistliği adil kullanım kotalarına tabidir.',
      body:
          'StyleMorph sanal kıyafet provası ve stil önerileri sunar. Sistemin kararlılığını sağlamak için adil kullanım kotaları uygulanır; otomatik bot ve kazıma girişimleri yasaktır.',
    ),
    LegalClause(
      number: 5,
      title: 'Yapay Zeka ve Otomatik İade',
      shortSummary:
          'Teknik hata veya güvenlik engeli durumunda ayrılan paralar anında iade edilir.',
      body:
          'Yapay zeka işlemleri geçici bakiye blokajı (Hold) ile yürütülür. Teknik bir hata veya güvenlik filtresi nedeniyle işlemin tamamlanamaması durumunda ayrılan paralar anında kullanıcı bakiyesine iade edilir.',
    ),
    LegalClause(
      number: 6,
      title: 'Kullanıcı İçeriği ve Sınırlı Lisans',
      shortSummary:
          'Fotoğraflarınızın mülkiyeti sizdedir; asla reklam veya yapay zeka eğitimi için kullanılmaz.',
      body:
          'Yüklediğiniz fotoğrafların tüm fikri mülkiyeti size aittir. StyleMorph\'a verilen lisans sadece talep edilen işlemi gerçekleştirmekle sınırlıdır; fotoğraflarınız veri havuzlarına satılmaz.',
    ),
    LegalClause(
      number: 7,
      title: 'Yapay Zeka Çıktıları ve Kalıcı Filigran',
      shortSummary:
          'Tüm çıktılar kalıcı "AI-Generated" işareti taşır ve ticari olmayan kişisel kullanım içindir.',
      body:
          'Üretilen görseller kişisel kullanım içindir. Tüm çıktılarda kalıcı yapay zeka filigranı yer alır; bu dijital işaretlerin gizlenmesi veya kaldırılması yasaktır.',
    ),
    LegalClause(
      number: 8,
      title: 'Kabul Edilebilir Kullanım ve Anti-Deepfake',
      shortSummary:
          'Başkalarının fotoğraflarını izinsiz yüklemek, deepfake ve müstehcen içerik kesinlikle yasaktır.',
      body:
          'Kullanıcı yalnızca kendi fotoğraflarını yükleyebilir. Kimlik manipülasyonu (deepfake), izinsiz yüz kullanımı, müstehcen veya zararlı içerik üretimi hesabın anında kalıcı olarak kapatılmasına yol açar.',
    ),
    LegalClause(
      number: 9,
      title: 'Sağlık ve Bakım Tıbbi Sorumluluk Reddi',
      shortSummary:
          'Cilt ve beden analizleri estetik tahminlerdir, tıbbi tavsiye yerine geçmez.',
      body:
          'Sağlık ve bakım sekmesindeki tüm veriler estetik stil tahminleridir; klinik, dermatolojik veya tıbbi teşhis niteliği taşımaz ve hekim tavsiyesinin yerini alamaz.',
    ),
    LegalClause(
      number: 10,
      title: 'Güvenlik İncelemesi ve İtiraz Hakkı',
      shortSummary:
          'Hatalı engellemeler için support@stylemorph.app üzerinden insan incelemesi talep edilebilir.',
      body:
          'İçerikler otomatik güvenlik filtrelerinden geçirilir. Hatalı bir filtreleme sonucu işleminiz durdurulursa, e-posta yoluyla manuel inceleme talebinde bulunabilirsiniz.',
    ),
    LegalClause(
      number: 11,
      title: 'StyleCoin Ekonomisi (Hold / Capture)',
      shortSummary:
          'Yaklaşık 0,02 USD referans değerli kullanım kredisi; sadece başarılı işlemlerde tahsil edilir.',
      body:
          'StyleCoin platform içi işlem maliyetlerini karşılayan ön ödemeli bir birimdir; kripto para veya yasal para birimi değildir. Ücret yalnızca işlem başarıyla tamamlandığında tahsil edilir.',
    ),
    LegalClause(
      number: 12,
      title: 'Satın Alımlar, Cayma Hakkı ve İadeler',
      shortSummary:
          'AB tüketicileri için kullanılmamış paketlerde 14 günlük yasal cayma hakkı saklıdır.',
      body:
          'Satın alımlar App Store, Google Play veya yetkili web sağlayıcıları üzerinden yapılır. AB tüketicileri harcanmamış paralar için 14 gün içinde cayma hakkına sahiptir.',
    ),
    LegalClause(
      number: 13,
      title: 'Promosyon Paraları ve Sadakat Seviyeleri',
      shortSummary:
          'Bronz, Gümüş, Altın ve Elmas kademeleri ileStylePoint kazanımları nakde çevrilemez.',
      body:
          'Sadakat dereceleri StylePoint ile belirlenir. Hediye ve promosyon paraları nakit değere sahip değildir ve başka kullanıcılara devredilemez.',
    ),
    LegalClause(
      number: 14,
      title: 'Bağımsız Mağazalar ve Dış Bağlantılar',
      shortSummary:
          'Kıyafet bağlantıları harici satıcılara yönlendirir; kargo ve iade ilgili mağazanın sorumluluğundadır.',
      body:
          'Mağaza sekmesindeki ürünler bağımsız satıcılara aittir. StyleMorph fiziki ürünlerin teslimatı, garanti veya iade süreçlerinden sorumlu değildir.',
    ),
    LegalClause(
      number: 15,
      title: 'Hizmet Sürekliliği ve Değişiklikler',
      shortSummary:
          'Kesintisiz erişim hedeflenir; bakım ve yapay zeka güncellemeleri önceden bildirilmeksizin yapılabilir.',
      body:
          'Yüksek erişilebilirlik amaçlansa da kesintisiz çalışma garanti edilmez. Model güncellemeleri ve teknik bakım hakları saklıdır.',
    ),
    LegalClause(
      number: 16,
      title: 'Sorumluluğun Sınırlandırılması (Alman Hukuku)',
      shortSummary:
          'Ağır kusur ve can güvenliği zararlarında Alman hukuku uyarınca tam sorumluluk.',
      body:
          'StyleMorph kasıt veya ağır ihmal durumlarında Alman kanunları uyarınca sınırsız sorumludur; hafif ihmallerde yalnızca öngörülebilir doğrudan sözleşme zararları tazmin edilir.',
    ),
    LegalClause(
      number: 17,
      title: 'Hesap Silme ve Fesih',
      shortSummary:
          'Profil ayarlarından hesabı ve tüm verileri tek tıkla kalıcı olarak silme imkanı.',
      body:
          'Hesabınızı Profil > Ayarlar menüsünden dilediğiniz zaman kalıcı olarak silebilirsiniz. Silme işlemiyle fotoğraflarınız ve verileriniz sunuculardan tamamen temizlenir.',
    ),
    LegalClause(
      number: 18,
      title: 'Kullanım Koşullarında Değişiklikler',
      shortSummary:
          'Önemli değişiklikler 30 gün önceden bildirilir; kullanıma devam etmek onayı ifade eder.',
      body:
          'Şartlardaki esaslı güncellemeler 30 gün önceden duyurulur. Belirtilen tarihten sonra uygulamayı kullanmaya devam etmeniz yeni şartları kabul ettiğiniz anlamına gelir.',
    ),
    LegalClause(
      number: 19,
      title: 'Uygulanacak Hukuk ve Yetkili Mahkeme',
      shortSummary:
          'Almanya Federal Cumhuriyeti hukuku uygulanır; tüketici koruma hakları saklıdır.',
      body:
          'Bu Koşullar Almanya Federal Cumhuriyeti kanunlarına tabidir. Ticari uyuşmazlıklarda yetkili merci Almanya mahkemeleridir; zorunlu tüketici hakları korunur.',
    ),
    LegalClause(
      number: 20,
      title: 'İngilizce Metnin Önceliği ve Bölünebilirlik',
      shortSummary:
          'Uyuşmazlıklarda İngilizce kanonik metin esastır; çeviriler kolaylık amaçlıdır.',
      body:
          'Kanonik metin İngilizce sürümdür; çeviriler bilgilendirme amaçlıdır. Bir maddenin geçersiz sayılması diğer maddelerin geçerliliğini etkilemez.',
    ),
    LegalClause(
      number: 21,
      title: 'iOS Cihazları İçin Ek Koşullar (Apple EULA)',
      shortSummary:
          'Sözleşme yalnızca StyleMorph iledir; Apple destek veya garanti tarafı değildir.',
      body:
          'iOS kullanıcıları bu şartların Apple Inc. ile değil yalnızca StyleMorph ile akdedildiğini, Apple\'ın bakım ve destek yükümlülüğü olmadığını kabul eder.',
    ),
    LegalClause(
      number: 22,
      title: 'Resmi Yasal İletişim',
      shortSummary:
          'Yasal bildirimler ve sorularınız için: support@stylemorph.app.',
      body:
          'Her türlü yasal başvuru, tebligat ve hak talepleriniz için support@stylemorph.app üzerinden ekibimizle iletişime geçebilirsiniz.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Tab 2: Privacy Policy Clauses (Sections 1–22)
  // ---------------------------------------------------------------------------

  static List<LegalClause> getPrivacyClauses(String localeCode) {
    switch (localeCode) {
      case 'fa':
        return faPrivacyClauses;
      case 'ar':
        return arPrivacyClauses;
      case 'tr':
        return trPrivacyClauses;
      default:
        return englishPrivacyClauses;
    }
  }

  static const List<LegalClause> englishPrivacyClauses = [
    LegalClause(
      number: 1,
      title: 'Data Controller Identity',
      shortSummary:
          'Operating under GDPR and German Federal Data Protection Act (BDSG).',
      body:
          'The data controller responsible for the processing of your personal data on StyleMorph is the operator of StyleMorph, located in Germany. Contact for privacy inquiries: support@stylemorph.app.',
    ),
    LegalClause(
      number: 2,
      title: 'Categories of Data Processed',
      shortSummary:
          'Account credentials, photos, styling specs, wardrobe assets, wallet ledger, and security telemetry.',
      body:
          'We process: 1) Account data (email, handle, display name), 2) Uploaded photos/videos and facial/body reference images, 3) Body and styling preferences (tagged as AI-generated or USER-entered), 4) Digital wardrobe metadata, 5) AI interaction prompts, 6) Optional wellness and lifestyle measurements, 7) Wallet balances and immutable financial ledger transactions, 8) Shop interactions and affiliate click telemetry, 9) Security telemetry (session tokens, IP addresses, device descriptors), 10) Context-aware support tickets, 11) AdMob consent signals where applicable, and 12) Legal consent audit trail records.',
    ),
    LegalClause(
      number: 3,
      title: 'Purposes & GDPR Legal Bases',
      shortSummary:
          'Contract fulfillment (Art. 6(1)(b)), consent (Art. 6(1)(a) & Art. 9(2)(a)), and compliance (Art. 6(1)(c)).',
      body:
          'We process data to deliver AI styling and virtual try-on under Art. 6(1)(b) GDPR (contract performance); sensitive body or wellness insights under Art. 9(2)(a) GDPR (explicit opt-in consent); fraud prevention, App Check validation, and system security under Art. 6(1)(f) GDPR (legitimate interests); and financial ledger archiving under Art. 6(1)(c) GDPR (statutory commercial and tax compliance).',
    ),
    LegalClause(
      number: 4,
      title: 'Optional vs. Mandatory Data',
      shortSummary:
          'Core account requires only email; anatomy, wardrobe, and wellness data are strictly voluntary.',
      body:
          'Only a valid email address and account credential are required to initialize an account. Uploading profile photographs, entering precise body dimensions, connecting wearable health data, or populating a digital closet are entirely optional choices under your direct control.',
    ),
    LegalClause(
      number: 5,
      title: 'Photos, Body Data & AI Processing',
      shortSummary:
          'Processed via secure Google Cloud Vertex AI / Gemini APIs; zero AI model training.',
      body:
          'Photos uploaded for virtual try-on or portrait atelier generation are transmitted via TLS 1.3 to Google Cloud Vertex AI and enterprise Gemini APIs located in Frankfurt, Germany. Storage buckets apply strict private deny-by-default rules. Uploaded imagery is validated via digital SHA-256 hash caching to prevent redundant compute. Photos are never used to train public or foundational AI models.',
    ),
    LegalClause(
      number: 6,
      title: 'Health & Wellness Data (Explicit Consent)',
      shortSummary:
          'Processed only with explicit opt-in; strictly isolated and zero advertisements.',
      body:
          'Wellness logs, skin quality indicators, and optional HealthKit / Health Connect metrics are classified as sensitive personal data. They are stored in an isolated, encrypted collection (health_dna) accessible strictly by the user. Wellness data is never shared with third-party advertisers or data brokers and contains zero commercial advertisements.',
    ),
    LegalClause(
      number: 7,
      title: 'What We Never Do (Zero-Sale Guarantee)',
      shortSummary:
          'We never sell your data, never broker photos, and never conduct emotion-based ad targeting.',
      body:
          'StyleMorph upholds a strict Zero-Sale Guarantee: we do not sell, rent, monetize, or broker personal data, biometric markers, or photographs to any third party. We do not perform real-time facial emotion profiling or cross-site behavioral ad retargeting using your uploaded styling photos.',
    ),
    LegalClause(
      number: 8,
      title: 'Stylist Companion Chat & Audio Processing',
      shortSummary:
          'Ephemeral voice processing with zero permanent retention of raw audio files.',
      body:
          'When interacting with the AI Stylist via voice, audio streams are transcribed ephemerally to text for query processing. Raw audio waveforms are immediately purged upon completion of speech-to-text inference and are never stored permanently.',
    ),
    LegalClause(
      number: 9,
      title: 'Safety Review & Flagged Content',
      shortSummary:
          'Vision models perform automated anatomical integrity checks; human review only on flag/appeal.',
      body:
          'Automated safety classifiers verify that generations comply with anti-deepfake and age safety rules. Content flagged for potential violations is quarantined. Access to flagged items is strictly restricted to authorized compliance officers and logged in immutable audit records.',
    ),
    LegalClause(
      number: 10,
      title: 'Fraud, Security & Abuse Prevention',
      shortSummary:
          'Firebase App Check and Cloudflare Turnstile; hardware IMEI and serials are never collected.',
      body:
          'We defend against automated abuse using Firebase App Check, Cloudflare Turnstile bot detection, and network telemetry. We do not collect persistent hardware serial numbers or cellular IMEI codes.',
    ),
    LegalClause(
      number: 11,
      title: 'Data Recipients & Sub-Processors',
      shortSummary:
          'Google Cloud (Frankfurt), Cloudflare, Apple/Google stores, and authorized payment gateways.',
      body:
          'Personal data is shared only with strictly audited sub-processors bound by GDPR Data Processing Agreements (DPAs): Google Cloud Platform / Firebase (Frankfurt europe-west3 for hosting, Firestore, Storage, and AI Vertex inference), Cloudflare (bot and DDoS mitigation), Apple App Store & Google Play (in-app billing), and certified payment providers (Stripe, Paddle, NOWPayments/Cryptomus) for web purchases.',
    ),
    LegalClause(
      number: 12,
      title: 'International Transfers & EU Data Residency',
      shortSummary:
          'Primary databases located in Frankfurt, Germany; transfers protected by EU Standard Contractual Clauses.',
      body:
          'Primary user databases and storage buckets reside within the European Union (Frankfurt, Germany). Where auxiliary cloud routing involves international data transfer, compliance is guaranteed under the EU-U.S. Data Privacy Framework (DPF) and European Commission Standard Contractual Clauses (SCCs).',
    ),
    LegalClause(
      number: 13,
      title: 'Data Retention & Purge Schedule',
      shortSummary:
          'Live data erased within 30 days of deletion; financial ledger preserved up to 10 years by tax law.',
      body:
          'Active session tokens expire after 14 days of idle status. When an account is deleted, personal profile data, digital wardrobe items, and uploaded photographs are permanently purged from live databases within 30 days and backups within 90 days. In accordance with German Commercial (HGB) and Tax (AO) statutory law, financial ledger transaction records are retained for up to 10 years.',
    ),
    LegalClause(
      number: 14,
      title: 'Infrastructure Security & Encryption Standards',
      shortSummary:
          'End-to-end TLS 1.3 in transit, AES-256 at rest, deny-by-default rules, and mandatory staff 2FA.',
      body:
          'We implement rigorous technical safeguards including TLS 1.3 for all data in transit, AES-256 encryption at rest across Firestore and Cloud Storage, strict security rules with zero-trust perimeter, and mandatory two-factor authentication (2FA) for all administrative personnel. Enterprise ISO 27001 and SOC 2 certifications apply directly to Google Cloud infrastructure.',
    ),
    LegalClause(
      number: 15,
      title: 'Your GDPR Rights & Supervisory Authority',
      shortSummary:
          'Full rights to access, rectification, erasure, restriction, portability, and lodging complaints.',
      body:
          'Under Chapter III of the GDPR, you have the right to: access your stored data (Art. 15), rectify inaccuracies (Art. 16), request erasure / Right to be Forgotten (Art. 17), restrict processing (Art. 18), obtain data portability (Art. 20), and object to processing (Art. 21). You also have the right to lodge a complaint with a competent German State Data Protection Authority.',
    ),
    LegalClause(
      number: 16,
      title: 'Instant Self-Service Data Deletion & Export',
      shortSummary:
          'Instant 1-click account purge directly available under Profile > Settings.',
      body:
          'StyleMorph provides self-service tools inside the app. You can purge your entire profile, wardrobe, and associated records directly under Profile > Settings without submitting a manual support ticket.',
    ),
    LegalClause(
      number: 17,
      title: 'Children’s Privacy (13+ Enforcement)',
      shortSummary:
          'Zero intentional collection of data from users under 13; accounts under 13 are immediately purged.',
      body:
          'Our service is restricted to users aged 13 and older. We do not knowingly collect personal or biometric information from children under 13. If we discover that a user under 13 has submitted personal photos, the account and all related files are immediately and irrevocably deleted.',
    ),
    LegalClause(
      number: 18,
      title: 'Automated Processing & Profiling Decisions',
      shortSummary:
          'Automated AI sizing suggestions do not produce legal or significant adverse effects.',
      body:
          'StyleMorph uses machine learning models to recommend styling pairings and garment fits. These automated recommendations do not produce legal effects or similarly significant effects under Art. 22 GDPR. You may always adjust or override recommendations manually.',
    ),
    LegalClause(
      number: 19,
      title: 'Regional Disclosures (EEA/UK, US & Global)',
      shortSummary:
          'Compliance with CCPA/CPRA, UK GDPR, and international privacy standards.',
      body:
          'For California residents (CCPA/CPRA): StyleMorph does not sell personal information or share personal information for cross-context behavioral advertising. For UK and Swiss users, processing adheres to UK GDPR and the Swiss Federal Act on Data Protection (FADP).',
    ),
    LegalClause(
      number: 20,
      title: 'Web Application & Local Client Storage',
      shortSummary:
          'Local storage utilized strictly for theme preferences and session tokens.',
      body:
          'Our responsive web application utilizes browser local storage (localStorage and sessionStorage) strictly to preserve essential user preferences (such as selected theme and language) and active authentication tokens. We do not deploy third-party tracking cookies.',
    ),
    LegalClause(
      number: 21,
      title: 'Policy Updates & Version Tracking',
      shortSummary:
          'Transparent updates versioned and linked to immutable consent audit logs.',
      body:
          'Any updates to this Privacy Policy will be posted within the app accompanied by an updated version number and date. If changes materially alter how your personal data is handled, you will receive prominent advance notification.',
    ),
    LegalClause(
      number: 22,
      title: 'Data Protection Officer & Privacy Desk',
      shortSummary:
          'Contact our dedicated privacy and data protection team at support@stylemorph.app.',
      body:
          'For questions regarding your privacy rights, data subject requests, or supervisory authority inquiries, please contact our Data Protection Desk directly via email: support@stylemorph.app.',
    ),
  ];

  static const List<LegalClause> faPrivacyClauses = [
    LegalClause(
      number: 1,
      title: 'هویت کنترل‌کننده داده‌ها',
      shortSummary:
          'فعالیت منطبق بر مقررات عمومی حفاظت از داده‌های اروپا (GDPR) و قانون آلمان (BDSG).',
      body:
          'کنترل‌کننده داده‌های شخصی در StyleMorph، گرداننده قانونی مستقر در کشور آلمان است. برای ارتباط با بخش حفظ حریم خصوصی: support@stylemorph.app.',
    ),
    LegalClause(
      number: 2,
      title: 'دسته‌بندی داده‌های پردازش‌شده',
      shortSummary:
          'اطلاعات حساب، تصاویر، مشخصات استایل، کمد لباس، دفتر مالی و تله‌متری امنیتی.',
      body:
          'داده‌های پردازش‌شده شامل: ۱) مشخصات حساب (ایمیل، نام کاربری)، ۲) تصاویر و ویدیوهای ارسالی، ۳) اندازه‌های فیزیکی و سلیقه استایل، ۴) اقلام کمد دیجیتال، ۵) متن تعاملات با استایلیست، ۶) اطلاعات اختیاری بخش تندرستی، ۷) موجودی و دفترکل تراکنش‌های مالی، ۸) تعاملات با بخش فروشگاه، ۹) تله‌متری امنیتی و نشست‌ها، ۱۰) تیکت‌های پشتیبانی، ۱۱) وضعیت رضایت تبلیغات، و ۱۲) متادیتای ممیزی رضایت حقوقی.',
    ),
    LegalClause(
      number: 3,
      title: 'اهداف پردازش و مبانی حقوقی GDPR',
      shortSummary:
          'اجرای قرارداد (بند ۶(۱)(b))، رضایت صریح (بند ۹(۲)(a)) و تکالیف قانونی مالیاتی.',
      body:
          'پردازش داده‌ها جهت ارائه خدمات پرو و استایلینگ بر مبنای ماده ۶(۱)(b) GDPR، تحلیل‌های حساس تندرستی بر مبنای رضایت صریح کاربر طبق ماده ۹(۲)(a) GDPR، و نگهداری سوابق مالی طبق تکالیف قانونی ماده ۶(۱)(c) صورت می‌پذیرد.',
    ),
    LegalClause(
      number: 4,
      title: 'داده‌های اختیاری در برابر داده‌های الزامی',
      shortSummary:
          'ایجاد حساب فقط نیازمند ایمیل است؛ ثبت آناتومی، کمد و سلامت کاملاً اختیاری است.',
      body:
          'تنها نشانی ایمیل معتبر جهت راه‌اندازی حساب کاربری اجباری است. بارگذاری تصاویر شخصی، اندازه‌گیری‌های خیاطی و داده‌های تندرستی تماماً به انتخاب و اراده مستقیم خود کاربر بستگی دارد.',
    ),
    LegalClause(
      number: 5,
      title: 'تصاویر، پردازش ابری و عدم آموزش مدل‌ها',
      shortSummary:
          'پردازش امن در منطقه فرانکفورت گوگل کلود؛ بدون هرگونه استفاده در آموزش مدل‌های عمومی.',
      body:
          'تصاویر ارسالی از طریق اتصال امن TLS 1.3 در سرورهای ابری اختصاصی Google Cloud در فرانکفورت آلمان پردازش می‌شوند. تصاویر با امضای امنیتی SHA-256 تطبیق داده شده و هرگز برای آموزش مدل‌های عمومی هوش مصنوعی به کار نمی‌روند.',
    ),
    LegalClause(
      number: 6,
      title: 'داده‌های تندرستی و سلامت (رضایت صریح)',
      shortSummary:
          'ذخیره‌سازی ایزوله با رضایت صریح کاربر، بدون هرگونه تبلیغات تجاری.',
      body:
          'داده‌های ثبت‌شده در بخش سلامت و زیبایی به عنوان داده‌های حساس در مجموعه‌ای کاملاً ایزوله (health_dna) نگهداری می‌شوند. این داده‌ها هرگز در اختیار شرکت‌های تبلیغاتی قرار نگرفته و فاقد هرگونه تبلیغات است.',
    ),
    LegalClause(
      number: 7,
      title: 'آنچه هرگز انجام نمی‌دهیم (تضمین عدم فروش)',
      shortSummary:
          'ما هرگز داده‌ها و عکس‌های شما را نمی‌فروشیم و بازاریابی مبتنی بر احساسات انجام نمی‌دهیم.',
      body:
          'StyleMorph متعهد به تضمین قطعی عدم فروش داده‌ها (Zero-Sale Guarantee) است: ما هرگز عکس‌ها، ابعاد بدن یا داده‌های شخصی را به دلالان داده یا شبکه‌های تبلیغاتی ثالث واگذار نکرده و نمی‌فروشیم.',
    ),
    LegalClause(
      number: 8,
      title: 'چت و صوت با استایلیست شخصی',
      shortSummary:
          'تبدیل آنی صوت به متن با پاکسازی بلافاصله فایل صوتی خام پس از پایان پردازش.',
      body:
          'در هنگام مکالمه صوتی با استایلیست هوش مصنوعی، صوت کاربر به صورت موقت جهت تبدیل به متن پردازش شده و فایل صوتی خام فوراً و بدون ذخیره‌سازی دائمی پاک می‌شود.',
    ),
    LegalClause(
      number: 9,
      title: 'بررسی ایمنی و محتوای مشکوک',
      shortSummary:
          'پایش خودکار ضد جعل عمیق؛ دسترسی عوامل انسانی فقط برای موارد گزارش‌شده با ثبت لاگ.',
      body:
          'سیستم‌های پایش هوشمند با هدف ممانعت از جعل عمیق و سوءاستفاده‌های تصویری بر فرایند تولید نظارت دارند. دسترسی به موارد مشکوک صرفاً محدود به کارشناسان تایید صلاحیت‌شده و با ثبت سوابق ممیزی است.',
    ),
    LegalClause(
      number: 10,
      title: 'پیشگیری از تقلب و امنیت دستگاه',
      shortSummary:
          'بهره‌گیری از Firebase App Check و Turnstile؛ عدم جمع‌آوری شماره سریال و IMEI.',
      body:
          'برای جلوگیری از حملات سایبری و بات‌ها از سرویس‌های App Check و کلودفلر بهره گرفته می‌شود. شماره سریال سخت‌افزاری و کد IMEI دستگاه کاربران هرگز ذخیره نمی‌گردد.',
    ),
    LegalClause(
      number: 11,
      title: 'دریافت‌کنندگان داده‌ها و پردازنده‌های ثالث',
      shortSummary:
          'سرورهای گوگل کلود (فرانکفورت)، کلودفلر، فروشگاه‌های اپل و گوگل و درگاه‌های پرداخت.',
      body:
          'داده‌ها منحصراً با ارائه‌دهندگان زیرساخت پایبند به توافق‌نامه پردازش داده‌های GDPR به اشتراک گذاشته می‌شوند: Google Cloud / Firebase در فرانکفورت آلمان، کلودفلر جهت امنیت، اپ استور و گوگل پلی جهت خرید درون‌برنامه‌ای، و درگاه‌های پرداخت معتبر برای وب.',
    ),
    LegalClause(
      number: 12,
      title: 'انتقال بین‌المللی و ذخیره‌سازی در اروپا',
      shortSummary:
          'پایگاه داده اصلی در فرانکفورت آلمان؛ انتقالات تحت مفاد قراردادی استاندارد اتحادیه اروپا (SCCs).',
      body:
          'پایگاه‌های داده و مخازن ذخیره فایل در منطقه europe-west3 فرانکفورت آلمان مستقر هستند. هرگونه تبادل فنی کمکی بر اساس چارچوب امنیت داده‌های اتحادیه اروپا-آمریکا و مفاد استاندارد قراردادی (SCCs) صورت می‌گیرد.',
    ),
    LegalClause(
      number: 13,
      title: 'برنامه زمان‌بندی نگهداری و پاکسازی داده‌ها',
      shortSummary:
          'حذف زنده داده‌ها ظرف ۳۰ روز از درخواست؛ نگهداری سوابق مالیاتی تا ۱۰ سال طبق قانون آلمان.',
      body:
          'نشست‌های غیرفعال پس از ۱۴ روز منقضی می‌شوند. پس از حذف حساب، داده‌ها و تصاویر ظرف حداکثر ۳۰ روز از سرورهای زنده و ۹۰ روز از بک‌آپ‌ها پاک می‌شوند. بر اساس قوانین تجاری و مالیاتی آلمان، دفاتر مالی تراکنش‌ها تا ۱۰ سال نگهداری می‌گردند.',
    ),
    LegalClause(
      number: 14,
      title: 'استانداردهای امنیت و رمزنگاری داده‌ها',
      shortSummary:
          'رمزنگاری TLS 1.3 در انتقال، AES-256 در حالت سکون، و احراز هویت دو مرحله‌ای کارکنان.',
      body:
          'امنیت اطلاعات از طریق پروتکل TLS 1.3 در انتقال، استاندارد قدرتمند AES-256 در پایگاه داده Firestore و Storage، قوانین امنیتی پیشرفته و احراز هویت دومرحله‌ای اجباری تیم مدیریت تضمین می‌شود.',
    ),
    LegalClause(
      number: 15,
      title: 'حقوق کاربران در چارچوب GDPR و نهاد ناظر',
      shortSummary:
          'حق دسترسی، اصلاح، حذف دائمی، انتقال داده و ثبت شکایت در مراجع نظارتی آلمان.',
      body:
          'کاربران طبق قوانین GDPR از حق دسترسی، ویرایش، حذف دائمی (حق فراموش شدن)، محدودسازی پردازش، انتقال داده‌ها و ثبت شکایت نزد مراجع نظارتی حفاظت از داده‌های آلمان برخوردارند.',
    ),
    LegalClause(
      number: 16,
      title: 'حذف و استخراج داده‌ها به صورت خودکار',
      shortSummary:
          'امکان پاکسازی آنی و بلادرنگ حساب کاربری و تمامی داده‌ها از منوی تنظیمات پروفایل.',
      body:
          'کاربر در هر زمان می‌تواند با مراجعه به بخش تنظیمات پروفایل، بدون نیاز به ارسال تیکت، تمام داده‌ها، تصاویر و حساب خود را با یک اقدام حذف دائمی نماید.',
    ),
    LegalClause(
      number: 17,
      title: 'حریم خصوصی کودکان (الزام ۱۳+)',
      shortSummary:
          'عدم گردآوری آگاهانه اطلاعات افراد زیر ۱۳ سال و پاکسازی فوری حساب‌های خاطی.',
      body:
          'خدمات ما صرفاً برای افراد ۱۳ سال و بالاتر طراحی شده است. هیچ‌گونه اطلاعاتی از افراد زیر ۱۳ سال آگاهانه جمع‌آوری نشده و در صورت کشف، حساب و فایل‌های مربوطه فوراً امحا می‌شوند.',
    ),
    LegalClause(
      number: 18,
      title: 'تصمیم‌گیری‌های خودکار و پیشنهادهای استایل',
      shortSummary:
          'پیشنهادات استایل فاقد اثر حقوقی هستند و کاربر می‌تواند مستقلاً آن‌ها را تغییر دهد.',
      body:
          'پیشنهادات هوش مصنوعی برای ست لباس صرفاً جنبه مشاوره‌ای دارد و مشمول تصمیم‌گیری‌های خودکار دارای اثر حقوقی طبق ماده ۲۲ GDPR نمی‌باشد.',
    ),
    LegalClause(
      number: 19,
      title: 'اطلاعیه‌های منطقه‌ای (اروپا، بریتانیا، کالیفرنیا)',
      shortSummary:
          'پایبندی به استانداردهای بین‌المللی حفظ حریم خصوصی از جمله CCPA/CPRA و UK GDPR.',
      body:
          'برای ساکنان ایالت کالیفرنیا (CCPA)، StyleMorph اطلاعات شخصی کاربران را هرگز به فروش نمی‌رساند. کاربران بریتانیا و سایر کشورها نیز از استانداردهای حفاظتی متناظر بهره‌مند هستند.',
    ),
    LegalClause(
      number: 20,
      title: 'اپلیکیشن وب و حافظه محلی مرورگر',
      shortSummary:
          'استفاده از LocalStorage صرفاً برای ذخیره تنظیمات پوسته و توکن نشست‌های معتبر.',
      body:
          'در نسخه وب، از حافظه محلی مرورگر صرفاً برای حفظ وضعیت پوسته، زبان انتخابی و توکن احراز هویت بهره گرفته می‌شود و هیچ کوکی ردیابی تبلیغاتی شخص ثالث استفاده نمی‌شود.',
    ),
    LegalClause(
      number: 21,
      title: 'به‌روزرسانی سیاست‌نامه و پیگیری نسخه‌ها',
      shortSummary:
          'اطلاع‌رسانی تغییرات با شماره نسخه مشخص و پیوند به لاگ‌های ممیزی تغییرناپذیر.',
      body:
          'هرگونه تغییر در این سیاست‌نامه با شماره نسخه جدید در اپلیکیشن منتشر می‌شود. تغییرات بااهمیت از قبل به اطلاع کاربران گرامی خواهد رسید.',
    ),
    LegalClause(
      number: 22,
      title: 'دپارتمان حفاظت از داده‌ها و راه‌های ارتباط',
      shortSummary:
          'ارتباط مستقیم با تیم حفظ حریم خصوصی و امنیت داده‌ها: support@stylemorph.app.',
      body:
          'برای طرح هرگونه پرسش پیرامون حریم خصوصی و احقاق حقوق خود می‌توانید مستقیماً با دپارتمان حفاظت از داده‌ها از طریق ایمیل support@stylemorph.app در تماس باشید.',
    ),
  ];

  static const List<LegalClause> arPrivacyClauses = [
    LegalClause(
      number: 1,
      title: 'هوية المسؤول عن معالجة البيانات',
      shortSummary:
          'العمل وفق اللائحة العامة لحماية البيانات (GDPR) والقانون الاتحادي الألماني (BDSG).',
      body:
          'المسؤول عن معالجة البيانات الشخصية لمنصة StyleMorph هو المشغل المسجل في ألمانيا. للتواصل بشأن الخصوصية: support@stylemorph.app.',
    ),
    LegalClause(
      number: 2,
      title: 'فئات البيانات المعالجة',
      shortSummary:
          'بيانات الحساب، الصور، تفضيلات المظهر، الخزانة، السجل المالي، وسجلات الأمان.',
      body:
          'نعالج بيانات الحساب والصور المرفوعة وتفضيلات المظهر والقياسات وخزانة الملابس والتعاملات مع المنسق والسجلات المالية وأمان الجلسات وسجلات التدقيق القانوني.',
    ),
    LegalClause(
      number: 3,
      title: 'أغراض المعالجة والأسس القانونية',
      shortSummary:
          'تنفيذ العقد (المادة ٦(١)(b)) والموافقة الصريحة والامتثال للالتزامات الضريبية.',
      body:
          'تتم المعالجة لتقديم خدمات القياس الافتراضي وتنسيق الأزياء وفق المادة ٦(١)(b) من GDPR، ومعالجة بيانات العناية الحساسة بموافقة صريحة وفق المادة ٩(٢)(a)، والامتثال المالي وفق المادة ٦(١)(c).',
    ),
    LegalClause(
      number: 4,
      title: 'البيانات الاختيارية مقابل الإلزامية',
      shortSummary:
          'التسجيل يتطلب البريد فقط؛ صور الوجه وتفاصيل القياسات اختيارية تماماً.',
      body:
          'البريد الإلكتروني هو البيان الإلزامي الوحيد لإنشاء الحساب. رفع الصور الشخصية وتحديد قياسات الجسم وإضافة خزانة الملابس هي خيارات طوعية تحت تحكمك الكامل.',
    ),
    LegalClause(
      number: 5,
      title: 'الصور والمعالجة وعدم تدريب النماذج',
      shortSummary:
          'معالجة آمنة في خوادم Google Cloud بفرانكفورت دون استخدامها في تدريب الذكاء الاصطناعي.',
      body:
          'تُعالج الصور عبر اتصال TLS 1.3 مشفر في مراكز Google Cloud بفرانكفورت. تُوقع الصور رقمياً بـ SHA-256 ولا تُستخدم أبداً لتدريب نماذج الذكاء الاصطناعي العامة.',
    ),
    LegalClause(
      number: 6,
      title: 'بيانات العناية والمظهر (موافقة صريحة)',
      shortSummary:
          'تخزين معزول وسري للبيانات الحساسة وخلو تام من الإعلانات التجارية.',
      body:
          'تُحفظ بيانات العناية والمظهر في سجلات معزولة ومحمية (health_dna). لا تُشارك هذه البيانات مع أي أطراف إعلانية ولا تتضمن المنصة أي إعلانات في هذا القسم.',
    ),
    LegalClause(
      number: 7,
      title: 'ما لا نفعله أبداً (ضمان عدم البيع)',
      shortSummary:
          'نلتزم بعدم بيع بياناتك أو صورك مطلقاً وعدم استهداف الإعلانات بناءً على المشاعر.',
      body:
          'نقدم ضماناً قاطعاً بعدم بيع البيانات (Zero-Sale Guarantee)؛ حيث نلتزم بعدم بيع أو تأجير صورك أو بياناتك لأي جهات تسويقية أو سماسرة بيانات.',
    ),
    LegalClause(
      number: 8,
      title: 'المحادثات الصوتية مع المنسق الذكي',
      shortSummary:
          'تحويل فوري للصوت إلى نص مع مسح التسجيل الصوتي الخام فور انتهاء المعالجة.',
      body:
          'عند استخدام التفاعل الصوتي، تتم معالجة الصوت لتحويله إلى نص رقمي فقط، ويتم مسح الملف الصوتي فوراً دون الاحتفاظ به في خوادمنا.',
    ),
    LegalClause(
      number: 9,
      title: 'مراجعة الأمان والمحتوى المبلغ عنه',
      shortSummary:
          'فحص ذكي للسلامة ومكافحة التزييف مع قصر الوصول البشري على الحالات المبلغ عنها.',
      body:
          'تراقب مصنفات الأمان الذكية التزام المخرجات بمعايير منع التزييف العميق. يُحظر الوصول البشري للمحتوى إلا في حالات الطعن والشكاوى وبتوثيق رسمي.',
    ),
    LegalClause(
      number: 10,
      title: 'مكافحة الاحتيال وحماية الأجهزة',
      shortSummary:
          'استخدام Firebase App Check وTurnstile دون جمع الأرقام التسلسلية للأجهزة أو IMEI.',
      body:
          'نحمي النظام من الهجمات الآلية باستخدام App Check وTurnstile. لا نقوم مطلقاً بجمع الأرقام التسلسلية الدائمة للأجهزة أو رموز IMEI.',
    ),
    LegalClause(
      number: 11,
      title: 'الجهات المستلمة للبيانات ومعالجوها',
      shortSummary:
          'Google Cloud (فرانكفورت)، وCloudflare، ومتاجر التطبيقات، وبوابات الدفع المعتمدة.',
      body:
          'تقتصر مشاركة البيانات على الشركاء التقنيين الملتزمين بمعايير GDPR: بنية Google Cloud في ألمانيا، وشبكة Cloudflare، ومتاجر Apple وGoogle، وبوابات الدفع الرسمية.',
    ),
    LegalClause(
      number: 12,
      title: 'نقل البيانات وتوطينها في أوروبا',
      shortSummary:
          'قواعد البيانات في فرانكفورت بألمانيا والنقل محمي بالبنود التعاقدية القياسية (SCCs).',
      body:
          'تستقر قواعد البيانات ومخازن الصور داخل الاتحاد الأوروبي (فرانكفورت). وتخضع أي عمليات تقنية مساعدة للبند التعاقدي القياسي الصادر عن المفوضية الأوروبية.',
    ),
    LegalClause(
      number: 13,
      title: 'فترات الاحتفاظ بالبيانات وجدول المسح',
      shortSummary:
          'مسح البيانات الحية خلال ٣٠ يوماً؛ والاحتفاظ بالسجلات المالية لـ ١٠ سنوات وفق القانون.',
      body:
          'تنتهي الجلسات غير النشطة بعد ١٤ يوماً. عند حذف الحساب، تُمسح البيانات والصور خلال ٣٠ يوماً من الأنظمة الحية. تُحفظ السجلات المالية لـ ١٠ سنوات بموجب القانون الضريبي الألماني.',
    ),
    LegalClause(
      number: 14,
      title: 'معايير التشفير وأمن البنية التحتية',
      shortSummary:
          'تشفير TLS 1.3 أثناء النقل وAES-256 أثناء التخزين ومصادقة ثنائية إلزامية للموظفين.',
      body:
          'نطبق أعلى معايير الأمان التقني: تشفير TLS 1.3 أثناء النقل وتشفير AES-256 لقواعد البيانات والمخازن، وسياسات أمان صارمة مع تفعيل المصادقة الثنائية لفرق الإشراف.',
    ),
    LegalClause(
      number: 15,
      title: 'حقوقك بموجب GDPR والسلطة الرقابية',
      shortSummary:
          'الحق في الوصول والتصحيح والحذف ونقل البيانات والشكوى لدى هيئات حماية البيانات بألمانيا.',
      body:
          'تتمتع بكامل حقوق الوصول، وتصحيح البيانات، والحذف النهائي (الحق في النسيان)، ونقل البيانات، والاعتراض، وتقديم الشكاوى لدى سلطات حماية البيانات الألمانية.',
    ),
    LegalClause(
      number: 16,
      title: 'الحذف الذاتي الفوري وتصدير البيانات',
      shortSummary:
          'إمكانية حذف الحساب وكامل البيانات بضغطة واحدة من إعدادات الملف الشخصي.',
      body:
          'يتيح لك التطبيق أدوات تحكم ذاتية تمكنك من مسح حسابك وصورك وبياناتك فورياً ودائماً من خلال إعدادات التطبيق دون الحاجة لمراسلة الدعم.',
    ),
    LegalClause(
      number: 17,
      title: 'خصوصية الأطفال (الزام ١٣+)',
      shortSummary:
          'عدم جمع بيانات من هم دون ١٣ عاماً ومسح أي حسابات مخالفة على الفور.',
      body:
          'الخدمة مخصصة للمستخدمين بعمر ١٣ عاماً فما فوق. لا نجمع بيانات الأطفال دون ١٣ عاماً عن قصد، وفي حال اكتشاف ذلك يتم مسح الحساب وملفاته فوراً.',
    ),
    LegalClause(
      number: 18,
      title: 'المعالجة الآلية وقرارات التنسيق الذكي',
      shortSummary:
          'اقتراحات التنسيق استشارية وليست قرارات ذات أثر قانوني وفق المادة ٢٢ من GDPR.',
      body:
          'تُستخدم نماذج الذكاء الاصطناعي لاقتراح تنسيقات الأزياء فقط، ولا ترتب هذه الاقتراحات أي آثار قانونية ملزمة للمستخدم وفق اللائحة الأوروبية.',
    ),
    LegalClause(
      number: 19,
      title: 'إشعارات إقليمية (كاليفورنيا، بريطانيا، عالمياً)',
      shortSummary:
          'الالتزام بقوانين الخصوصية الدولية بما فيها CCPA/CPRA وقانون المملكة المتحدة.',
      body:
          'لسكان كاليفورنيا (CCPA): لا نبيع معلوماتك الشخصية لأي أغراض تجارية. ويتمتع المستخدمون في المملكة المتحدة وكافة الدول بحماية مطابقة للمعايير الدولية.',
    ),
    LegalClause(
      number: 20,
      title: 'تطبيق الويب والتخزين المحلي للمتصفح',
      shortSummary:
          'استخدام التخزين المحلي فقط لحفظ إعدادات المظهر واللغة وجلسات تسجيل الدخول.',
      body:
          'نستخدم في تطبيق الويب التخزين المحلي (LocalStorage) لحفظ إعدادات المظهر واللغة ورمز الدخول الآمن فقط، دون استخدام أي ملفات تعريف تتبع إعلانية.',
    ),
    LegalClause(
      number: 21,
      title: 'تحديثات السياسة وسجل الإصدارات',
      shortSummary:
          'إعلان شفاف عن التحديثات وتوثيق رقم الإصدار مع سجلات تدقيق الموافقة.',
      body:
          'يتم نشر أي تحديث يطرأ على هذه السياسة داخل التطبيق مع رقم الإصدار وتاريخ التفعيل، ويتم إشعار المستخدمين بالتغييرات الجوهرية مسبقاً.',
    ),
    LegalClause(
      number: 22,
      title: 'مكتب حماية البيانات والتواصل الرسمي',
      shortSummary:
          'لأي استفسارات أو ممارسة لحقوق الخصوصية: support@stylemorph.app.',
      body:
          'لممارسة أي من حقوقك أو التواصل مع مسؤول حماية البيانات، يرجى مراسلتنا عبر: support@stylemorph.app.',
    ),
  ];

  static const List<LegalClause> trPrivacyClauses = [
    LegalClause(
      number: 1,
      title: 'Veri Sorumlusunun Kimliği',
      shortSummary:
          'GDPR ve Almanya Federal Veri Koruma Kanunu (BDSG) uyarınca veri sorumlusu.',
      body:
          'StyleMorph platformunda işlenen kişisel verilerinizden sorumlu veri sorumlusu Almanya merkezli StyleMorph işleticisidir. İletişim: support@stylemorph.app.',
    ),
    LegalClause(
      number: 2,
      title: 'İşlenen Veri Kategorileri',
      shortSummary:
          'Hesap, fotoğraflar, stil tercihleri, gardırop, cüzdan defteri ve güvenlik verileri.',
      body:
          'İşlenen veriler: 1) Hesap bilgileri, 2) Yüklenen fotoğraflar, 3) Beden ölçüleri ve stil tercihleri, 4) Dijital gardırop kayıtları, 5) Stilist sohbet istemleri, 6) İsteğe bağlı sağlık/bakım verileri, 7) Cüzdan bakiyesi ve mali kayıtlar, 8) Mağaza tıklamaları, 9) Cihaz güvenliği ve oturum telemetrisi, 10) Destek kayıtları, 11) Reklam izin sinyalleri ve 12) Hukuki onay denetim kayıtları.',
    ),
    LegalClause(
      number: 3,
      title: 'Veri İşleme Amaçları ve GDPR Dayanakları',
      shortSummary:
          'Sözleşmenin ifası (Madde 6(1)(b)), açık rıza (Madde 9(2)(a)) ve yasal vergisel yükümlülükler.',
      body:
          'Veriler; stil ve sanal prova hizmetlerini sunmak için Sözleşmenin İfası (GDPR Madde 6(1)(b)), özel nitelikli sağlık/bakım verileri için Açık Rıza (Madde 9(2)(a)) ve mali kayıtlar için Yasal Yükümlülük (Madde 6(1)(c)) kapsamında işlenir.',
    ),
    LegalClause(
      number: 4,
      title: 'İsteğe Bağlı ve Zorunlu Veriler',
      shortSummary:
          'Hesap açmak için yalnızca e-posta zorunludur; fotoğraf, beden ve sağlık verileri isteğe bağlıdır.',
      body:
          'Hesap oluşturmak için yalnızca geçerli bir e-posta adresi zorunludur. Fotoğraf yüklemek, beden ölçülerini girmek veya gardırop oluşturmak tamamen sizin tercihinize bağlıdır.',
    ),
    LegalClause(
      number: 5,
      title: 'Fotoğraflar, Bulut İşleme ve Model Eğitimi Yasağı',
      shortSummary:
          'Frankfurt Google Cloud üzerinde güvenli işleme; genel yapay zeka modelleri eğitilmez.',
      body:
          'Fotoğraflar TLS 1.3 şifrelemesiyle Frankfurt\'taki Google Cloud Vertex AI sunucularına aktarılır. SHA-256 özetiyle doğrulanır ve asla genel yapay zeka modellerini eğitmekte kullanılmaz.',
    ),
    LegalClause(
      number: 6,
      title: 'Sağlık ve Bakım Verileri (Açık Rıza)',
      shortSummary:
          'Açık rıza ile izole depolama; kesinlikle reklamlara kapalı ve ticari olmayan alan.',
      body:
          'Sağlık ve bakım sekmesindeki veriler özel nitelikli veri olarak izole bir veri tabanında (health_dna) saklanır. Reklam ağlarıyla paylaşılmaz ve bu alanda reklam gösterilmez.',
    ),
    LegalClause(
      number: 7,
      title: 'Asla Yapmadıklarımız (Sıfır Veri Satışı)',
      shortSummary:
          'Verilerinizi asla satmayız ve duygulara dayalı reklam hedeflemesi yapmayız.',
      body:
          'StyleMorph kesin Sıfır Veri Satışı Garantisi verir: Fotoğraflarınızı, yüz verilerinizi veya kişisel kayıtlarınızı asla veri simsarlarına veya reklamcılara satmaz ve kiralamayız.',
    ),
    LegalClause(
      number: 8,
      title: 'Stilist Sesli ve Yazılı İletişimi',
      shortSummary:
          'Sesli komutlar anında metne dönüştürülür ve ham ses dosyası işlem sonrası derhal silinir.',
      body:
          'Stilist ile sesli etkileşimde ses verisi yalnızca metne dönüştürülmek üzere geçici olarak işlenir; ham ses kayıtları sunucularda kalıcı olarak depolanmaz.',
    ),
    LegalClause(
      number: 9,
      title: 'Güvenlik İncelemesi ve Bildirilen İçerikler',
      shortSummary:
          'Otomatik anti-deepfake denetimleri; insan erişimi yalnızca şikayet ve itiraz halleriyle sınırlıdır.',
      body:
          'Yapay zeka modelleri deepfake ve kötüye kullanımı engellemek için otomatik güvenlik taraması yapar. Şüpheli içeriklere insan erişimi yalnızca denetim kaydı altında ve itiraz durumlarında mümkündür.',
    ),
    LegalClause(
      number: 10,
      title: 'Dolandırıcılık ve Güvenlik Koruması',
      shortSummary:
          'Firebase App Check ve Turnstile kullanımı; donanım seri numarası ve IMEI toplanmaz.',
      body:
          'Sistem güvenliği için Firebase App Check ve Cloudflare Turnstile araçları kullanılır. Kalıcı donanım seri numaraları veya IMEI kodları asla kaydedilmez.',
    ),
    LegalClause(
      number: 11,
      title: 'Veri Alıcıları ve Alt İşleyiciler',
      shortSummary:
          'Google Cloud (Frankfurt), Cloudflare, Apple/Google uygulama mağazaları ve ödeme ağ geçitleri.',
      body:
          'Veriler yalnızca GDPR uyumlu sözleşmeli sağlayıcılarla paylaşılır: Google Cloud Platform (Frankfurt europe-west3), Cloudflare, Apple/Google mağazaları ve onaylı ödeme ortakları.',
    ),
    LegalClause(
      number: 12,
      title: 'Uluslararası Veri Aktarımı ve Avrupa Konumu',
      shortSummary:
          'Ana veri tabanları Frankfurt / Almanya\'dadır; aktarımlar Standart Sözleşme Maddeleri (SCC) ile korunur.',
      body:
          'Verileriniz Avrupa Birliği sınırları içinde (Frankfurt, Almanya) barındırılır. Olası uluslararası teknik aktarımlar AB Standart Sözleşme Maddeleri (SCC) güvencesi altındadır.',
    ),
    LegalClause(
      number: 13,
      title: 'Veri Saklama Süreleri ve Silme Takvimi',
      shortSummary:
          'Silinen veriler 30 gün içinde canlı sistemden kaldırılır; vergi kayıtları 10 yıl saklanır.',
      body:
          'Hareketsiz oturumlar 14 günde kapanır. Hesap silindiğinde fotoğraflar ve veriler 30 gün içinde canlı sistemlerden silinir. Mali kayıtlar Alman vergi kanunları gereğince 10 yıla kadar saklanır.',
    ),
    LegalClause(
      number: 14,
      title: 'Altyapı Güvenliği ve Şifreleme',
      shortSummary:
          'İletimde TLS 1.3, depolamada AES-256 ve zorunlu iki faktörlü personel kimlik doğrulaması.',
      body:
          'Tüm iletişim TLS 1.3, veritabanı kayıtları ise AES-256 ile şifrelenir. Sistem yönetimi için iki faktörlü kimlik doğrulaması (2FA) zorunludur.',
    ),
    LegalClause(
      number: 15,
      title: 'GDPR Haklarınız ve Denetim Otoritesi',
      shortSummary:
          'Erişim, düzeltme, unutulma, veri taşıma ve Alman veri koruma otoritesine şikayet hakları.',
      body:
          'Kullanıcılar GDPR uyarınca verilerine erişme, düzeltme, kalıcı silinmesini isteme (unutulma hakkı), taşıma ve Alman Veri Koruma Otoritelerine şikayette bulunma hakkına sahiptir.',
    ),
    LegalClause(
      number: 16,
      title: 'Anında Self-Servis Veri Silme ve Dışa Aktarma',
      shortSummary:
          'Profil > Ayarlar menüsünden tüm hesabı ve verileri anında kalıcı olarak silme imkanı.',
      body:
          'Destek ekibine yazmaya gerek kalmaksızın, Profil > Ayarlar menüsünden tüm hesabınızı, gardırobunuzu ve fotoğraflarınızı anında ve kalıcı olarak silebilirsiniz.',
    ),
    LegalClause(
      number: 17,
      title: 'Çocukların Gizliliği (13+ Yaş Sınırı)',
      shortSummary:
          '13 yaş altındaki bireylerin verileri toplanmaz; tespit edilenler derhal silinir.',
      body:
          'Hizmetlerimiz 13 yaş ve üzeri kullanıcılar içindir. 13 yaşından küçüklerin kişisel verileri bilerek toplanmaz ve tespit edildiğinde derhal imha edilir.',
    ),
    LegalClause(
      number: 18,
      title: 'Otomatik İşleme ve Profilleme Kararları',
      shortSummary:
          'Yapay zeka stil önerileri tavsiye niteliğindedir, bağlayıcı yasal sonuç doğurmaz.',
      body:
          'Yapay zeka önerileri yalnızca stil danışmanlığı amacı taşır; GDPR Madde 22 kapsamında yasal veya benzeri bağlayıcı sonuç doğuran otomatik kararlar içermez.',
    ),
    LegalClause(
      number: 19,
      title: 'Bölgesel Bildirimler (Kaliforniya, İngiltere, Global)',
      shortSummary:
          'CCPA/CPRA, UK GDPR ve küresel veri koruma standartlarına tam uyum.',
      body:
          'Kaliforniya sakinleri (CCPA) için kişisel veriler satılmaz veya üçüncü taraf reklamcılığı için paylaşılmaz. İngiltere ve diğer ülke kullanıcıları da denk haklara sahiptir.',
    ),
    LegalClause(
      number: 20,
      title: 'Web Uygulaması ve Yerel Tarayıcı Depolama',
      shortSummary:
          'Yerel depolama yalnızca tema ve oturum belirteçleri için kullanılır; üçüncü taraf takip çerezleri yoktur.',
      body:
          'Web sitemizde localStorage yalnızca tema tercihi ve güvenli oturum belirteçleri için kullanılır; reklam amaçlı üçüncü taraf takip çerezleri yer almaz.',
    ),
    LegalClause(
      number: 21,
      title: 'Politika Güncellemeleri ve Sürüm Takibi',
      shortSummary:
          'Şeffaf sürümleme ve değiştirilemez denetim kayıtları ile güncellemelerin takibi.',
      body:
          'Gizlilik politikasındaki değişiklikler yeni sürüm numarasıyla duyurulur. Esaslı değişikliklerde kullanıcılara uygulama içinden önceden bilgi verilir.',
    ),
    LegalClause(
      number: 22,
      title: 'Veri Koruma Görevlisi ve İletişim Masası',
      shortSummary:
          'Gizlilik haklarınız ve talepleriniz için doğrudan iletişim: support@stylemorph.app.',
      body:
          'Veri koruma ile ilgili tüm soru, talep ve hak kullanımlarınız için Veri Koruma Masamıza e-posta ile ulaşabilirsiniz: support@stylemorph.app.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Tab 3: Legal Info / Impressum Entries & Dispute Resolution
  // ---------------------------------------------------------------------------

  static List<LegalInfoEntry> getLegalInfoEntries(String localeCode) {
    switch (localeCode) {
      case 'fa':
        return faLegalInfoEntries;
      case 'ar':
        return arLegalInfoEntries;
      case 'tr':
        return trLegalInfoEntries;
      default:
        return englishLegalInfoEntries;
    }
  }

  static const List<LegalInfoEntry> englishLegalInfoEntries = [
    LegalInfoEntry(label: 'Service Name', value: 'StyleMorph'),
    LegalInfoEntry(
      label: 'Operator / Provider',
      value: '[Full legal name of the operator], trading as StyleMorph',
    ),
    LegalInfoEntry(
      label: 'Postal Address',
      value: '[Street and number], [Postal code] [City], Germany',
    ),
    LegalInfoEntry(label: 'Official Email', value: 'support@stylemorph.app'),
    LegalInfoEntry(label: 'Official Website', value: 'https://stylemorph.app'),
    LegalInfoEntry(
      label: 'VAT ID (USt-IdNr.)',
      value: '[VAT identification number]',
    ),
    LegalInfoEntry(label: 'Effective Date', value: '2026-11-23'),
  ];

  static const List<LegalInfoEntry> faLegalInfoEntries = [
    LegalInfoEntry(label: 'نام سرویس', value: 'StyleMorph'),
    LegalInfoEntry(
      label: 'ارائه‌دهنده قانونی',
      value: '[Full legal name of the operator], trading as StyleMorph',
    ),
    LegalInfoEntry(
      label: 'نشانی پستی اقامتگاه',
      value: '[Street and number], [Postal code] [City], Germany',
    ),
    LegalInfoEntry(
      label: 'پست الکترونیکی رسمی',
      value: 'support@stylemorph.app',
    ),
    LegalInfoEntry(label: 'وب‌سایت رسمی', value: 'https://stylemorph.app'),
    LegalInfoEntry(
      label: 'شناسه مالیات بر ارزش افزوده',
      value: '[شماره مالیاتی]',
    ),
    LegalInfoEntry(label: 'تاریخ لازم‌الاجرا شدن', value: '۲۰۲۶/۱۱/۲۳'),
  ];

  static const List<LegalInfoEntry> arLegalInfoEntries = [
    LegalInfoEntry(label: 'اسم الخدمة', value: 'StyleMorph'),
    LegalInfoEntry(
      label: 'المشغل القانوني',
      value: '[Full legal name of the operator], trading as StyleMorph',
    ),
    LegalInfoEntry(
      label: 'العنوان البريدي',
      value: '[Street and number], [Postal code] [City], Germany',
    ),
    LegalInfoEntry(label: 'البريد الإلكتروني', value: 'support@stylemorph.app'),
    LegalInfoEntry(label: 'الموقع الرسمي', value: 'https://stylemorph.app'),
    LegalInfoEntry(label: 'الرقم الضريبي (VAT)', value: '[الرقم الضريبي]'),
    LegalInfoEntry(label: 'تاريخ السريان', value: '٢٠٢٦/١١/٢٣'),
  ];

  static const List<LegalInfoEntry> trLegalInfoEntries = [
    LegalInfoEntry(label: 'Hizmet Adı', value: 'StyleMorph'),
    LegalInfoEntry(
      label: 'Yasal İşletici / Sağlayıcı',
      value: '[Full legal name of the operator], trading as StyleMorph',
    ),
    LegalInfoEntry(
      label: 'Posta Adresi',
      value: '[Street and number], [Postal code] [City], Germany',
    ),
    LegalInfoEntry(label: 'Resmi E-posta', value: 'support@stylemorph.app'),
    LegalInfoEntry(label: 'Resmi Web Sitesi', value: 'https://stylemorph.app'),
    LegalInfoEntry(label: 'KDV Kimlik No (VAT)', value: '[KDV Numarası]'),
    LegalInfoEntry(label: 'Yürürlük Tarihi', value: '2026-11-23'),
  ];

  static String getDisputeResolutionNotice(String localeCode) {
    switch (localeCode) {
      case 'fa':
        return 'اطلاعیه حل و فصل اختلافات مصرف‌کننده: کمیسیون اروپا سامانه‌ای برای حل و فصل آنلاین اختلافات (ODR) در آدرس https://ec.europa.eu/consumers/odr فراهم نموده است. ما ملزم یا مایل به شرکت در فرآیندهای حل اختلاف نزد هیئت‌های داوری مصرف‌کننده نیستیم.';
      case 'ar':
        return 'إشعار تسوية منازعات المستهلك: توفر المفوضية الأوروبية منصة لتسوية النزاعات عبر الإنترنت (ODR) عبر الرابط https://ec.europa.eu/consumers/odr. نحن لسنا ملزمين ولا نرغب في المشاركة في إجراءات تسوية المنازعات أمام هيئة تحكيم المستهلك.';
      case 'tr':
        return 'Tüketici Uyuşmazlık Çözümü Bildirimi: Avrupa Komisyonu, https://ec.europa.eu/consumers/odr adresinde çevrimiçi uyuşmazlık çözümü (ODR) platformu sağlamaktadır. Tüketici hakem heyetleri nezdinde uyuşmazlık çözüm prosedürlerine katılmakla yükümlü değiliz ve buna taraf olmayı tercih etmemekteyiz.';
      default:
        return englishDisputeResolutionNotice;
    }
  }

  static const String englishDisputeResolutionNotice =
      'Online Dispute Resolution Notice: The European Commission provides an Online Dispute Resolution (ODR) platform under Art. 14(1) ODR-VO at https://ec.europa.eu/consumers/odr. We are neither obligated nor willing to participate in dispute settlement proceedings before a consumer arbitration board.';
}
