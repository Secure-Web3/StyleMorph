import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';

class LegalDocSection {
  final String title;
  final String content;

  const LegalDocSection({required this.title, required this.content});
}

class LegalDocModalSheet extends StatelessWidget {
  final String title;
  final FaIconData icon;
  final List<LegalDocSection> sections;

  const LegalDocModalSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.sections,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required FaIconData icon,
    required List<LegalDocSection> sections,
  }) {
    return AppModal.showSheet(
      context: context,
      child: LegalDocModalSheet(title: title, icon: icon, sections: sections),
    );
  }

  static void showTerms(BuildContext context) {
    final strings = context.strings;
    final isFa = strings.localeCode == 'fa';
    final isAr = strings.localeCode == 'ar';
    final isTr = strings.localeCode == 'tr';

    List<LegalDocSection> sections;
    if (isFa) {
      sections = const [
        LegalDocSection(
          title: '۱. پذیرش و دامنه خدمات',
          content:
              'استفاده از خدمات، وب‌سایت و اپلیکیشن استایل‌مورف (StyleMorph) به منزله پذیرش کامل این قوانین و مقررات است. این پلتفرم ارائه‌دهنده خدمات مد، استایل هوشمند، پرو مجازی البسه و مشاوره‌های مرتبط با استایل و زیبایی بر پایه هوش مصنوعی مولد است.',
        ),
        LegalDocSection(
          title: '۲. حساب کاربری و مسئولیت‌ها',
          content:
              'کاربران موظف به حفظ محرمانگی نام کاربری، رمز عبور و نشست‌های فعال خود هستند. هرگونه فعالیت انجام‌شده از طریق حساب کاربری، متوجه صاحب حساب بوده و استفاده غیرمجاز یا ایجاد اختلال در پلتفرم موجب تعلیق فوری حساب خواهد شد.',
        ),
        LegalDocSection(
          title: '۳. حقوق مالکیت فکری و خروجی‌های هوش مصنوعی',
          content:
              'کلیه حقوق نرم‌افزار، علائم تجاری، معماری سامانه و طراحی‌های رابط کاربری متعلق به استایل‌مورف است. تصاویر و رندرهای تولیدشده توسط پرو مجازی یا آتلیه هوش مصنوعی برای استفاده شخصی یا تجاری مجاز در چارچوب قوانین پلتفرم در اختیار کاربر قرار می‌گیرد.',
        ),
        LegalDocSection(
          title: '۴. محتوای فروشندگان همکار و سلب مسئولیت',
          content:
              'استایل‌مورف در نسخه فعلی صرفاً بستر نمایش، مقایسه و هدایت به فروشگاه‌های همکار است. کیفیت فیزیکی، قیمت‌گذاری و ارسال کالاهای ارائه‌شده توسط فروشندگان شخص ثالث بر عهده فروشنده مربوطه بوده و تابع قوانین تجاری اختصاصی آنهاست.',
        ),
        LegalDocSection(
          title: '۵. به‌روزرسانی و اصلاح شرایط',
          content:
              'استایل‌مورف حق اعمال تغییرات در قوانین و مقررات را در هر زمان برای خود محفوظ می‌دارد. تغییرات اساسی از طریق اعلان‌های درون‌برنامه‌ای به اطلاع کاربران خواهد رسید.',
        ),
      ];
    } else if (isAr) {
      sections = const [
        LegalDocSection(
          title: '١. قبول الشروط ونطاق الخدمة',
          content:
              'استخدامك لتطبيق وخدمات ستايل مورف يعني موافقتك الكاملة على هذه الشروط. توفر المنصة خدمات تنسيق الأزياء والقياس الافتراضي المدعومة بالذكاء الاصطناعي.',
        ),
        LegalDocSection(
          title: '٢. حسابات المستخدمين والمسؤوليات',
          content:
              'يتحمل المستخدم مسؤولية الحفاظ على سرية بيانات الدخول وجلساته النشطة. أي استخدام غير قانوني أو محاولة للإضرار بالخدمة سيؤدي إلى إنهاء الحساب فوراً.',
        ),
        LegalDocSection(
          title: '٣. الملكية الفكرية ومحتوى الذكاء الاصطناعي',
          content:
              'جميع حقوق الملكية والعلامات التجارية محفوظة لستايل مورف. تُمنح مخرجات الذكاء الاصطناعي للمستخدمين للاستخدام الشخصي المصرح به وفقاً للإرشادات العامة.',
        ),
        LegalDocSection(
          title: '٤. المتاجر الشريكة وإخلاء المسؤولية',
          content:
              'توفر المنصة حالياً استعراضاً وتوجيهاً لمنتجات المتاجر الشريكة. تقع مسؤولية الشحن والأسعار على عاتق البائعين الخارجيين.',
        ),
        LegalDocSection(
          title: '٥. تحديث الشروط والأحكام',
          content:
              'تحتفظ ستايل مورف بالحق في تعديل هذه الشروط في أي وقت مع إشعار المستخدمين عبر التطبيق.',
        ),
      ];
    } else if (isTr) {
      sections = const [
        LegalDocSection(
          title: '1. Şartların Kabulü ve Hizmet Kapsamı',
          content:
              'StyleMorph uygulamasını kullanarak bu koşulları kabul etmiş sayılırsınız. Platform, yapay zeka destekli sanal deneme ve kişisel stil danışmanlığı sunar.',
        ),
        LegalDocSection(
          title: '2. Kullanıcı Hesapları ve Sorumluluklar',
          content:
              'Kullanıcılar oturum bilgilerinin güvenliğinden sorumludur. Platformun kötüye kullanımı hesabın askıya alınmasına yol açabilir.',
        ),
        LegalDocSection(
          title: '3. Fikri Mülkiyet ve Yapay Zeka Çıktıları',
          content:
              'StyleMorph\'un tüm ticari markaları ve yazılım hakları saklıdır. Yapay zeka ile üretilen çıktılar kişisel kullanım için kullanıcının tasarrufundadır.',
        ),
        LegalDocSection(
          title: '4. Üçüncü Taraf Mağazalar ve Sorumluluk Reddi',
          content:
              'Harici satıcı bağlantıları aracılığıyla yapılan alışverişlerde ürün teslimatı ve iade süreçleri ilgili satıcının sorumluluğundadır.',
        ),
        LegalDocSection(
          title: '5. Şartlarda Değişiklik',
          content:
              'StyleMorph bu şartları güncelleme hakkını saklı tutar. Önemli güncellemeler uygulama içi bildirimle duyurulur.',
        ),
      ];
    } else {
      sections = const [
        LegalDocSection(
          title: '1. Acceptance of Terms & Service Scope',
          content:
              'By accessing or using StyleMorph, you agree to be bound by these Terms of Service. StyleMorph provides personal AI stylist consulting, virtual garment fitting, and digital wardrobe organization powered by generative models.',
        ),
        LegalDocSection(
          title: '2. User Accounts & Responsibilities',
          content:
              'You are responsible for maintaining the confidentiality of your credentials and authorized devices. Any malicious use, automated scraping, or disruption of platform infrastructure will result in immediate account termination.',
        ),
        LegalDocSection(
          title: '3. Intellectual Property & AI-Generated Outputs',
          content:
              'All trademarks, logos, UI designs, and proprietary models are owned exclusively by StyleMorph. AI fitting previews and styled imagery are licensed to you for authorized personal and editorial presentation.',
        ),
        LegalDocSection(
          title: '4. Partner Stores & Third-Party Disclaimer',
          content:
              'StyleMorph connects users with curated external apparel merchants. Physical garment orders, shipping, and store warranties are executed directly under the merchant\'s independent policies.',
        ),
        LegalDocSection(
          title: '5. Policy Updates & Modifications',
          content:
              'We reserve the right to revise these Terms periodically. Notice of significant material changes will be provided directly through in-app notifications.',
        ),
      ];
    }

    show(
      context,
      title: strings.aboutTermsTitle,
      icon: FontAwesomeIcons.fileContract,
      sections: sections,
    );
  }

  static void showPrivacy(BuildContext context) {
    final strings = context.strings;
    final isFa = strings.localeCode == 'fa';
    final isAr = strings.localeCode == 'ar';
    final isTr = strings.localeCode == 'tr';

    List<LegalDocSection> sections;
    if (isFa) {
      sections = const [
        LegalDocSection(
          title: '۱. تعهد بنیادین به حفاظت از حریم خصوصی',
          content:
              'حفظ محرمانگی تصاویر و داده‌های شخصی کاربران اصل تغییرناپذیر استایل‌مورف است. ما هرگز اطلاعات بیومتریک، اندازه‌های خیاطی یا تصاویر چهره شما را به اشخاص ثالث، تبلیغ‌کنندگان یا دلالان داده نمی‌فروشیم.',
        ),
        LegalDocSection(
          title: '۲. خط لوله پردازش امن تصاویر هوش مصنوعی',
          content:
              'تصاویر ورودی برای پرو مجازی منحصراً در حافظه موقت (RAM) پردازش شده و با امضای دیجیتال رمزنگاری‌شده SHA-256 هش می‌شوند تا از ارسال توکن‌های غیرضروری جلوگیری شود. پس از استخراج ویژگی‌های البسه، تصاویر خام موقت طبق خط‌مشی محرمانگی پاکسازی می‌گردند.',
        ),
        LegalDocSection(
          title: '۳. حالت آواتار خصوصی (Dual-Persona Privacy)',
          content:
              'کاربرانی که تمایل به استفاده از عکس واقعی چهره خود ندارند، می‌توانند در بخش رسانه حالت «مانکن دیجیتال مینیمال» را فعال کنند تا پرو لباس منحصراً روی فیگور خنثی انجام شود.',
        ),
        LegalDocSection(
          title: '۴. رمزنگاری داده‌ها و امنیت نشست‌ها',
          content:
              'کلیه ارتباطات شبکه با گواهی TLS/SSL رمزنگاری‌شده و پایگاه داده با استاندارد AES-256 محافظت می‌شود. سیستم مانیتورینگ نشست‌ها امکان رصد و قطع دسترسی دستگاه‌های ناشناس را در هر لحظه فراهم می‌سازد.',
        ),
        LegalDocSection(
          title: '۵. حق حذف دائمی اطلاعات',
          content:
              'کاربران در هر زمان حق دارند درخواست حذف کامل حساب کاربری، فایل‌های کمد، تصاویر ذخیره‌شده و سوابق آناتومی خود را ثبت کنند که بلافاصله از سرورها پاکسازی خواهد شد.',
        ),
      ];
    } else if (isAr) {
      sections = const [
        LegalDocSection(
          title: '١. التزامنا الصارم بحماية الخصوصية',
          content:
              'تلتزم ستايل مورف بحماية صورك وبياناتك الشخصية. لا نبيع أبداً قياساتك أو صور وجهك لأي أطراف ثالثة أو معلنين.',
        ),
        LegalDocSection(
          title: '٢. معالجة الصور الآمنة بالذكاء الاصطناعي',
          content:
              'تتم معالجة الصور في الذاكرة المؤقتة فقط وتُشفر بتوقيعات رقمية SHA-256. تُحذف الصور الخام تلقائياً بعد استخراج سمات الملابس المطلوبة.',
        ),
        LegalDocSection(
          title: '٣. وضع الأفاتار الخاص (المانيكان المحايد)',
          content:
              'يمكن للمستخدمين تفعيل وضع «المانيكان المحايد» لتجربة وتنسيق الملابس دون الحاجة لرفع صور شخصية حقيقية.',
        ),
        LegalDocSection(
          title: '٤. التشفير وأمان الجلسات',
          content:
              'تُشفر جميع البيانات المنقولة والمخزنة بمعايير AES-256 وTLS. يمكنك مراقبة وإنهاء الجلسات النشطة في أي وقت عبر تبويب الجلسات.',
        ),
        LegalDocSection(
          title: '٥. حق الحذف النهائي للبيانات',
          content:
              'يحق لك في أي وقت حذف حسابك وجميع صور خزانتك وبياناتك نهائياً من خوادمنا بشكل فوري.',
        ),
      ];
    } else if (isTr) {
      sections = const [
        LegalDocSection(
          title: '1. Gizlilik İlkemiz ve Veri Güvenliği',
          content:
              'StyleMorph, kişisel fotoğraflarınızı ve ölçülerinizi korumayı taahhüt eder. Biyometrik verileriniz asla üçüncü taraflara satılmaz.',
        ),
        LegalDocSection(
          title: '2. Yapay Zeka Görsel İşleme Standartları',
          content:
              'Görseller geçici bellekte işlenir ve SHA-256 ile şifrelenir. Giysi özellikleri çıkarıldıktan sonra ham fotoğraflar otomatik olarak silinir.',
        ),
        LegalDocSection(
          title: '3. Gizlilik Odaklı Çift Kişilikli Avatar',
          content:
              'Gerçek yüz fotoğrafınızı yüklemek istemiyorsanız, giysileri nötr bir manken üzerinde denemek için gizlilik avatarını seçebilirsiniz.',
        ),
        LegalDocSection(
          title: '4. Uçtan Uca Şifreleme ve Oturum Güvenliği',
          content:
              'Tüm veriler AES-256 ve TLS standartlarıyla korunur. Cihaz oturumlarınızı dilediğiniz an yönetebilir ve kapatabilirsiniz.',
        ),
        LegalDocSection(
          title: '5. Veri Silme Hakkı',
          content:
              'Kullanıcılar diledikleri zaman hesaplarını, gardırop fotoğraflarını ve tüm verilerini kalıcı olarak silme hakkına sahiptir.',
        ),
      ];
    } else {
      sections = const [
        LegalDocSection(
          title: '1. Core Privacy Commitment',
          content:
              'StyleMorph strictly protects your personal images and tailoring measurements. We never sell, rent, or monetize your photos or facial biometric data to data brokers or advertisers.',
        ),
        LegalDocSection(
          title: '2. Secure AI Image Processing & Hashing',
          content:
              'Images for virtual try-on are processed ephemeral in-memory and hashed via digital SHA-256 signatures to avoid redundant cloud token consumption. Raw temporary uploads expire automatically per privacy rules.',
        ),
        LegalDocSection(
          title: '3. Dual-Persona Privacy Avatar Mode',
          content:
              'Users who prefer not to use real facial photographs can select the neutral digital mannequin mode in Media Settings to fit garments on an anonymous silhouette.',
        ),
        LegalDocSection(
          title: '4. Encryption & Session Oversight',
          content:
              'All data in transit is encrypted with TLS/SSL and stored with AES-256 standards. Our session manager allows you to audit and terminate unrecognized devices at any time.',
        ),
        LegalDocSection(
          title: '5. Right to Erasure & Account Deletion',
          content:
              'You retain full sovereignty over your data and may permanently delete your wardrobe assets, tailoring measurements, and account records at any time.',
        ),
      ];
    }

    show(
      context,
      title: strings.aboutPrivacyTitle,
      icon: FontAwesomeIcons.shieldHalved,
      sections: sections,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return AppBottomSheetShell(
      title: title,
      titleLeading: FaIcon(icon, size: 16, color: colors.prt),
      bottomBar: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: AppButton(
          variant: AppButtonVariant.outline,
          isFullWidth: true,
          text: strings.aboutClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final sec = sections[index];
          return AppCard(
            variant: AppCardVariant.surface,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sec.title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  sec.content,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colors.mu,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
