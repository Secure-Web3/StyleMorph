import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
          title: '۱. دامنه خدمات و شرایط احراز سن قانونی',
          content:
              'استفاده از خدمات، اپلیکیشن و وب‌سایت StyleMorph به منزله پذیرش کامل این شرایط است. حداقل سن قانونی برای عضویت و استفاده از خدمات ۱۳ سال تمام است (یا ۱۶ سال در حوزه اتحادیه اروپا/GDPR). کاربران زیر سن قانونی موظف به کسب رضایت صریح والدین یا سرپرست قانونی خود می‌باشند.',
        ),
        LegalDocSection(
          title: '۲. امنیت حساب، تأیید ایمیل و مدیریت نشست‌ها',
          content:
              'کاربران مسئول حفظ محرمانگی گذرواژه و نشست‌های فعال خود هستند. StyleMorph سیاست دروازه نرم (Soft Gate) را اعمال می‌کند که طی آن ثبت‌نام اولیه آزاد است، اما اجرای قابلیت‌های پیشرفته و تعاملات مالی منوط به تأیید نشانی ایمیل می‌باشد. امکان مدیریت، بازرسی و خاتمه دادن به دستگاه‌های متصل در بخش نشست‌ها فراهم است.',
        ),
        LegalDocSection(
          title: '۳. سلب مسئولیت صریح غیرپزشکی و خروجی‌های هوش مصنوعی',
          content:
              'خروجی‌های اتاق پرو مجازی، استایلیست شخصی، آتلیه و پیشنهادات بخش تندرستی (Wellness) صرفاً شبیه‌سازی بصری و راهنمایی‌های مشاوره‌ای بر پایه هوش مصنوعی مولد هستند. این توصیه‌ها تحت هیچ شرایطی نظر یا تشخیص پزشکی، درماتولوژی (پوست و مو) یا سلامت بالینی محسوب نمی‌شوند و نباید جایگزین نظر متخصصان سلامت و پزشک معالج گردند.',
        ),
        LegalDocSection(
          title: '۴. استفاده مجاز و خط‌مشی ضد جعل عمیق (Anti-Deepfake)',
          content:
              'بارگذاری هرگونه تصویر بدون رضایت صریح صاحب تصویر، محتوای غیراخلاقی، مستهجن، نژادپرستانه، ترویج خشونت یا سوءاستفاده از چهره اشخاص ثالث به عنوان جعل عمیق اکیداً ممنوع است. نقض این بند موجب مسدودسازی فوری و دائمی حساب و ارجاع موضوع به مراجع ذی‌صلاح قانونی خواهد شد.',
        ),
        LegalDocSection(
          title: '۵. مالکیت فکری و مجوز محدود محتوای کاربر',
          content:
              'کاربر مالکیت کامل تصاویر ورودی، عکس‌های چهره و دارایی‌های شخصی کمد دیجیتال خود را حفظ می‌کند. با ارسال تصویر، کاربر صرفاً مجوزی محدود، موقت و غیرانحصاری به StyleMorph اعطا می‌کند تا پردازش‌های درخواستی را به انجام برساند. کلیه کدها، علائم تجاری و الگوریتم‌های اختصاصی متعلق به StyleMorph است.',
        ),
        LegalDocSection(
          title: '۶. اقتصاد StyleCoin و فروشگاه‌های همکار شخص ثالث',
          content:
              'واحد ارزش درون‌برنامه‌ای StyleCoin (با ارزش مرجع تقریبی ۰.۰۲ دلار آمریکا به ازای هر کوین) جهت پردازش‌های هوش مصنوعی به کار می‌رود و سکه‌های خریداری‌شده فاقد تاریخ انقضا هستند. در نسخه فعلی، StyleMorph بستر هدایت به فروشگاه‌های همکار است و مسئولیت قیمت، انبارداری، سلامت فیزیکی کالا و ارسال بر عهده فروشنده مستقل مربوطه است.',
        ),
        LegalDocSection(
          title: '۷. تعلیق حساب، قوانین حاکم و پشتیبانی رسمی',
          content:
              'StyleMorph حق تعلیق یا مسدودسازی حساب‌های ناقض این قوانین را محفوظ می‌دارد. در صورت بروز هرگونه سوال، ابهام یا درخواست حقوقی، کاربران گرامی می‌توانند مستقیماً از طریق ایمیل support@stylemorph.app با پشتیبانی رسمی در ارتباط باشند.',
        ),
      ];
    } else if (isAr) {
      sections = const [
        LegalDocSection(
          title: '١. نطاق الخدمة وأهلية الاستخدام والسن القانوني',
          content:
              'يُعد استخدامك لمنصة وتطبيق StyleMorph موافقة كاملة على هذه الشروط. الحد الأدنى للسن القانوني للاستخدام هو ١٣ عاماً (أو ١٦ عاماً في دول الاتحاد الأوروبي/GDPR). يتوجب على القاصرين الحصول على موافقة صريحة من ولي الأمر أو الوصي القانوني قبل الاستخدام.',
        ),
        LegalDocSection(
          title: '٢. أمان الحساب وتأكيد البريد الإلكتروني والجلسات',
          content:
              'يتحمل المستخدم المسؤولية الكاملة عن سرية بيانات حسابه وكلمة المرور. تطبق StyleMorph سياسة البوابة المرنة حيث يمكن استكشاف المنصة بحرية، في حين تتطلب المعاملات المالية وتوليد الذكاء الاصطناعي المتقدم توثيق البريد الإلكتروني. تتيح المنصة إدارة الجلسات ومراجعة الأجهزة المصرح بها.',
        ),
        LegalDocSection(
          title: '٣. إخلاء المسؤولية الطبية الصريح ومخرجات الذكاء الاصطناعي',
          content:
              'إن مخرجات غرفة القياس الافتراضي، المنسق الشخصي، واستوديو التصوير، وتحليلات العناية والمظهر هي محاكاة بصرية ونصائح استشارية مبنية على الذكاء الاصطناعي التوليدي. لا تُعد هذه التوجيهات بأي حال من الأحوال تشخيصاً أو استشارة طبية أو جلدية، ولا تغني عن استشارة الأطباء والمختصين.',
        ),
        LegalDocSection(
          title:
              '٤. الاستخدام المقبول وسياسة مكافحة التزييف العميق (Anti-Deepfake)',
          content:
              'يُحظر تماماً رفع صور أشخاص آخرين دون موافقتهم الصريحة، أو رفع محتوى غير لائق أو مسيء أو مضلل بغرض التزييف العميق. سيؤدي أي انتهاك لهذه السياسة إلى إغلاق الحساب نهائياً وفورياً مع اتخاذ الإجراءات القانونية اللازمة.',
        ),
        LegalDocSection(
          title: '٥. الملكية الفكرية وترخيص محتوى المستخدم',
          content:
              'يحتفظ المستخدم بملكية كاملة لجميع صوره المرفوعة وبيانات خزانته الرقمية. يمنح المستخدم منصة StyleMorph ترخيصاً محدوداً ومؤقتاً لمعالجة الصور لتنفيذ طلبات القياس والتنسيق فقط. جميع البرمجيات والعلامات التجارية لـ StyleMorph محمية ومملوكة للمنصة حصراً.',
        ),
        LegalDocSection(
          title: '٦. اقتصاد StyleCoin والروابط مع المتاجر الخارجية',
          content:
              'تُستخدم عملة StyleCoin (بقيمة مرجعية تعادل تقريباً ٠.٠٢ دولار أمريكي للعملة) لتشغيل خدمات الذكاء الاصطناعي التوليدي. ترتبط المنصة بمتاجر شركاء معتمدين، وتقع مسؤولية الشحن والأسعار وجودة السلع الفعلية على عاتق المتاجر الخارجية المعنية وفقاً لسياساتها المستقلة.',
        ),
        LegalDocSection(
          title: '٧. إنهاء الخدمة والقوانين المعمول بها وقنوات التواصل',
          content:
              'تحتفظ StyleMorph بالحق في تعليق الحسابات المخالفة لهذه الشروط. لأي استفسارات قانونية أو طلبات دعم، يُرجى التواصل معنا عبر البريد الإلكتروني الرسمي: support@stylemorph.app.',
        ),
      ];
    } else if (isTr) {
      sections = const [
        LegalDocSection(
          title: '1. Hizmet Kapsamı ve Yasal Yaş Uygunluğu',
          content:
              'StyleMorph uygulamasını ve web platformunu kullanarak bu Şartları kabul etmiş sayılırsınız. Hizmetlerimizi kullanmak için asgari yasal yaş 13\'tür (Avrupa Birliği/GDPR kapsamında 16\'dır). Reşit olmayan kullanıcılar ebeveyn veya yasal vasi onayına sahip olmalıdır.',
        ),
        LegalDocSection(
          title: '2. Hesap Güvenliği, E-posta Doğrulama ve Oturum Yönetimi',
          content:
              'Kullanıcılar kimlik bilgilerinin ve yetkili oturumlarının güvenliğinden münhasıran sorumludur. StyleMorph esnek geçiş politikası uygular; gelişmiş yapay zeka oluşturma ve cüzdan işlemleri e-posta doğrulama gerektirir. Oturumlar sekmesinden aktif cihazlarınızı denetleyebilir ve sonlandırabilirsiniz.',
        ),
        LegalDocSection(
          title: '3. Tıbbi Olmayan Sorumluluk Reddi ve Yapay Zeka Çıktıları',
          content:
              'Sanal deneme odası, yapay zeka stilisti, atölye ve sağlık/bakım önerileri üretken yapay zekaya dayalı görsel simülasyon ve danışmanlık amaçlıdır. Bu çıktılar kesinlikle tıbbi, dermatolojik veya klinik tavsiye niteliği taşımaz ve sağlık uzmanlarının görüşünün yerine geçemez.',
        ),
        LegalDocSection(
          title: '4. Kabul Edilebilir Kullanım ve Anti-Deepfake Politikası',
          content:
              'Açık rızası olmaksızın üçüncü şahıslara ait fotoğrafların yüklenmesi, müstehcen, yasa dışı, zararlı veya sahte içerik üretimi (deepfake) kesinlikle yasaktır. İhlal durumunda kullanıcı hesabı derhal ve kalıcı olarak feshedilir.',
        ),
        LegalDocSection(
          title: '5. Fikri Mülkiyet ve Kullanıcı İçeriği Lisansı',
          content:
              'Kullanıcılar yükledikleri fotoğrafların ve gardırop varlıklarının tüm mülkiyetini korur. StyleMorph\'a yalnızca talep edilen yapay zeka hizmetlerini gerçekleştirmek üzere sınırlı ve geçici bir işleme lisansı verilir. StyleMorph\'un tüm ticari markaları, algoritmaları ve yazılım hakları saklıdır.',
        ),
        LegalDocSection(
          title: '6. StyleCoin Ekonomisi ve Üçüncü Taraf Mağazalar',
          content:
              'Platform içi StyleCoin birimi (referans değeri yaklaşık 0,02 USD) yapay zeka işlem maliyetleri için kullanılır ve satın alınan paraların süresi dolmaz. StyleMorph harici satıcı bağlantıları sunar; fiziksel ürünlerin kargolanması, fiyatlandırması ve iadesi ilgili satıcının sorumluluğundadır.',
        ),
        LegalDocSection(
          title: '7. Fesih, Yürürlükteki Hukuk ve Resmi İletişim',
          content:
              'StyleMorph bu kuralları ihlal eden hesapları askıya alma hakkını saklı tutar. Yasal sorularınız ve geri bildirimleriniz için support@stylemorph.app adresi üzerinden ekibimizle iletişime geçebilirsiniz.',
        ),
      ];
    } else {
      sections = const [
        LegalDocSection(
          title: '1. Scope of Service & Legal Age Eligibility',
          content:
              'By accessing or using StyleMorph, you agree to be bound by these Terms of Service. You must be at least 13 years old (or 16 in the European Union/EEA under GDPR) to use our platform. Minors must have express parental or legal guardian consent prior to accessing generative AI features.',
        ),
        LegalDocSection(
          title: '2. Account Security, Email Verification & Session Oversight',
          content:
              'You are responsible for safeguarding your credentials and authorized devices. StyleMorph utilizes a soft-gate policy: browsing is open, while high-compute AI synthesis and wallet transactions strictly mandate a verified email. You may inspect and revoke authorized active sessions at any time via the Sessions dashboard.',
        ),
        LegalDocSection(
          title: '3. AI-Generated Outputs & Explicit Non-Medical Disclaimer',
          content:
              'All virtual garment try-ons, personal stylist chats, atelier portraits, and wellness recommendations are aesthetic visual simulations and advisory insights powered by generative models. They DO NOT constitute medical, clinical, dermatological, or healthcare advice and must never replace consultation with a licensed medical professional.',
        ),
        LegalDocSection(
          title: '4. Acceptable Use & Strict Anti-Deepfake Policy',
          content:
              'Uploading imagery of third parties without their express verifiable consent, generating explicit, defamatory, or abusive content, or using StyleMorph for synthetic identity manipulation (deepfakes) is strictly prohibited. Violations will trigger immediate, permanent account termination and applicable law enforcement reporting.',
        ),
        LegalDocSection(
          title: '5. Intellectual Property & Limited User Content License',
          content:
              'You retain 100% full ownership over your uploaded photos, styling preferences, and digital wardrobe items. You grant StyleMorph only a limited, revocable, non-exclusive license solely to process and render the AI features you actively request. All proprietary algorithms, logos, and UI designs belong exclusively to StyleMorph.',
        ),
        LegalDocSection(
          title: '6. StyleCoin Economy & External Merchant Disclaimer',
          content:
              'The internal utility coin StyleCoin (pegged at approximately \$0.02 USD reference value) powers generative processing cycles; purchased coins do not expire. In the current release, StyleMorph curates links to verified partner apparel merchants. Physical fulfillment, shipping, returns, and product warranties are governed solely by the respective merchant\'s independent policies.',
        ),
        LegalDocSection(
          title: '7. Suspension, Governing Law & Contact Support',
          content:
              'StyleMorph reserves the right to suspend or terminate accounts that breach these Terms. For legal inquiries, compliance audits, or account support, contact us directly at support@stylemorph.app.',
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
          title: '۱. دسته‌بندی داده‌های گردآوری‌شده',
          content:
              'ما داده‌های لازم را در چهار بخش شفاف جمع‌آوری می‌کنیم: ۱) اطلاعات هویتی و ثبت‌نامی (ایمیل، نام کاربری و اختیاری نام و شهر)، ۲) مشخصات دلخواه آناتومی، اندازه‌های خیاطی و سلیقه استایل، ۳) تصاویر کمد و پرو مجازی بارگذاری‌شده توسط کاربر، و ۴) تله‌متری امنیتی دستگاه و نشست‌ها.',
        ),
        LegalDocSection(
          title: '۲. زیرساخت ابری ایمن Google Cloud و استانداردهای رمزنگاری',
          content:
              'تمامی داده‌ها روی زیرساخت امن ابری گوگل (Google Cloud Platform / Firebase در منطقه europe-west3 فرانکفورت) نگهداری می‌شوند. تمامی ارتباطات داده‌ای تحت پروتکل TLS 1.3 رمزنگاری شده و داده‌های ذخیره شده در Firestore و Storage با استاندارد قدرتمند AES-256 محافظت می‌گردند.',
        ),
        LegalDocSection(
          title:
              '۳. پردازش تصاویر و تضمین قطعی عدم فروش داده (Zero-Sale Guarantee)',
          content:
              'StyleMorph هرگز و تحت هیچ شرایطی تصاویر، مشخصات فیزیکی یا داده‌های شخصی کاربران را به واسطه‌های تبلیغاتی، دلالان داده یا اشخاص ثالث نمی‌فروشد. تصاویر بارگذاری‌شده هرگز برای آموزش مدل‌های عمومی هوش مصنوعی بدون رضایت صریح استفاده نمی‌شوند. تصاویر با امضای دیجیتال SHA-256 هش شده و کاربران می‌توانند از حالت مانکن دیجیتال (Dual-Persona Private Avatar) استفاده نمایند.',
        ),
        LegalDocSection(
          title: '۴. پردازشگرهای شخص ثالث ضروری و مورد اعتماد',
          content:
              'جهت ارائه پایدار خدمات، ما از خدمات زیربنایی استاندارد صنعت شامل احراز هویت و ذخیره‌سازی امن Firebase، مدل‌های پیشرفته هوش مصنوعی ابری Google Cloud AI، و سیستم حفاظتی ضد بات Cloudflare Turnstile بهره می‌بریم که همگی متعهد به استانداردهای سختگیرانه GDPR هستند.',
        ),
        LegalDocSection(
          title:
              '۵. حقوق انحصاری کاربران (مطابق با GDPR، CCPA و استانداردهای Google & Apple)',
          content:
              'کاربران از حق دسترسی کامل، ویرایش، استخراج نسخه پشتیبان و «حذف دائمی و بلادرنگ حساب کاربری و کلیه داده‌های ذخیره‌شده» برخوردارند. امکان پاکسازی اطلاعات در هر زمان از طریق بخش تنظیمات پروفایل یا مکاتبه مستقیم با support@stylemorph.app مهیاست و کلیه اطلاعات کمد، تصاویر و نشست‌ها فوراً محو خواهند شد.',
        ),
        LegalDocSection(
          title: '۶. حریم خصوصی کودکان و اصلاحات سیاست‌نامه',
          content:
              'سرویس‌های ما برای افراد زیر ۱۳ سال در نظر گرفته نشده و آگاهانه هیچ اطلاعاتی از کودکان جمع‌آوری نمی‌شود. هرگونه به‌روزرسانی اساسی در این سیاست‌نامه از طریق اعلان‌های درون‌برنامه‌ای به اطلاع کاربران خواهد رسید.',
        ),
      ];
    } else if (isAr) {
      sections = const [
        LegalDocSection(
          title: '١. فئات البيانات التي يتم جمعها',
          content:
              'تجمع منصة StyleMorph البيانات الضرورية ضمن أربع فئات واضحة: ١) بيانات الهوية والتسجيل (البريد الإلكتروني، اسم المستخدم، وبيانات الملف الشخصي الاختيارية)، ٢) تفضيلات القياس والأناتومي وتنسيق الأزياء، ٣) صور الخزانة والقياس الافتراضي المرفوعة، ٤) سجلات أمان الأجهزة والجلسات.',
        ),
        LegalDocSection(
          title: '٢. بنية Google Cloud التحتية ومعايير التشفير العالية',
          content:
              'تُخزن جميع البيانات على بنية Google Cloud وFirebase المعتمدة عالمياً في منطقة فرانكفورت (europe-west3). جميع الاتصالات مشفرة ببروتوكول TLS 1.3 أثناء النقل، والبيانات المخزنة في Firestore وStorage محمية بتشفير AES-256 وفق سياسات أمان صارمة.',
        ),
        LegalDocSection(
          title: '٣. معالجة الصور وضمان عدم بيع البيانات نهائياً (Zero-Sale)',
          content:
              'تلتزم StyleMorph التزاماً قاطعاً بعدم بيع صور المستخدمين أو قياساتهم أو بياناتهم الشخصية لأي معلنين أو سماسرة بيانات. لا تُستخدم الصور لتدريب نماذج الذكاء الاصطناعي العامة دون موافقة صريحة. تُشفر الصور بتوقيعات رقمية SHA-256، ويمكن للمستخدمين تفعيل وضع المانيكان المحايد للحفاظ التام على خصوصية الوجه.',
        ),
        LegalDocSection(
          title: '٤. معالجو البيانات الخارجيون الأساسيون',
          content:
              'لضمان استقرار الخدمة وكفاءتها، نعتمد على خدمات موثوقة متوافقة مع معايير الأمان العالمية، بما يشمل: خدمات Google Firebase للمصادقة وقواعد البيانات، خوادم Google Cloud AI لمعالجة الذكاء الاصطناعي، وخدمات Cloudflare Turnstile للحماية من الهجمات الآلية.',
        ),
        LegalDocSection(
          title: '٥. حقوق المستخدمين الإلزامية (GDPR وCCPA ومتاجر التطبيقات)',
          content:
              'يتمتع المستخدم بكامل الحقوق القانونية في الوصول إلى بياناته، وتصحيحها، وتصديرها، و«الحذف الدائم والفوري للحساب وجميع البيانات والصور المرفوعة» في أي وقت عبر إعدادات الملف الشخصي أو بمراسلتنا على support@stylemorph.app.',
        ),
        LegalDocSection(
          title: '٦. خصوصية الأطفال وتحديثات سياسة الخصوصية',
          content:
              'الخدمة غير موجهة للأطفال دون سن ١٣ عاماً ولا نجمع بياناتهم عن قصد. يتم إخطار المستخدمين بأي تحديثات جوهرية تطرأ على هذه السياسة عبر إشعارات التطبيق الرسمية.',
        ),
      ];
    } else if (isTr) {
      sections = const [
        LegalDocSection(
          title: '1. Toplanan Veri Kategorileri',
          content:
              'StyleMorph verileri dört şeffaf kategoride toplar: 1) Hesap ve kimlik bilgileri (e-posta, kullanıcı adı, isteğe bağlı profil alanları), 2) Beden ölçüleri, stil ve giyim tercihleri, 3) Sanal deneme ve dijital gardırop için yüklenen fotoğraflar, 4) Cihaz güvenliği ve oturum telemetrisi.',
        ),
        LegalDocSection(
          title: '2. Google Cloud ve Firebase Altyapı Güvenliği',
          content:
              'Tüm veriler Google Cloud Platform / Firebase üzerinde (Frankfurt / europe-west3 bölgesi) barındırılır. Aktarım esnasında TLS 1.3, veritabanı ve depolama katmanında ise AES-256 şifreleme standartları uygulanır.',
        ),
        LegalDocSection(
          title: '3. Görsel İşleme ve Sıfır Veri Satışı Garantisi',
          content:
              'StyleMorph kişisel fotoğraflarınızı, yüz verilerinizi veya ölçülerinizi asla veri simsarlarına veya reklamcılara satmaz. Yüklenen fotoğraflar açık rıza olmaksızın halka açık genel yapay zeka modellerini eğitmek için kullanılmaz. Görseller SHA-256 ile imzalanır ve kullanıcılar nötr manken avatarı modunu tercih edebilir.',
        ),
        LegalDocSection(
          title: '4. Zorunlu ve Güvenilir Üçüncü Taraf İşleyiciler',
          content:
              'Hizmet sürekliliği için GDPR uyumlu küresel sağlayıcılarla çalışıyoruz: Google Firebase (Kimlik doğrulama ve depolama), Google Cloud AI (Yapay zeka işleme) ve Cloudflare Turnstile (Bot ve güvenlik koruması).',
        ),
        LegalDocSection(
          title:
              '5. Zorunlu Kullanıcı Hakları (GDPR, CCPA ve Mağaza Standartları)',
          content:
              'Kullanıcılar verilerine erişme, düzeltme, dışa aktarma ve «Hesabını ve Tüm Verilerini Kalıcı Olarak Silme» hakkına sahiptir. Bu işlem profil ayarlarından veya support@stylemorph.app adresine yazarak anında gerçekleştirilebilir.',
        ),
        LegalDocSection(
          title: '6. Çocukların Gizliliği ve Politika Değişiklikleri',
          content:
              'StyleMorph 13 yaşın altındaki çocuklara yönelik değildir ve bilerek çocuk verisi toplamaz. Bu ilkelerdeki önemli güncellemeler uygulama içi bildirimler aracılığıyla duyurulur.',
        ),
      ];
    } else {
      sections = const [
        LegalDocSection(
          title: '1. Categories of Data Collected',
          content:
              'We collect data across four transparent categories: 1) Identity and account credentials (email address, handle, optional name and location), 2) Optional anatomical tailoring specs and personal style preferences, 3) Digital wardrobe garments and try-on reference photographs, and 4) Session security, active device telemetry, and IP audit trails.',
        ),
        LegalDocSection(
          title: '2. Google Cloud & Firebase Infrastructure Security',
          content:
              'All customer data is hosted on enterprise Google Cloud Platform and Firebase infrastructure in Frankfurt, Germany (europe-west3). We enforce strict end-to-end TLS 1.3 in transit, AES-256 encryption at rest, and Zero-Trust Firestore and Cloud Storage security rules.',
        ),
        LegalDocSection(
          title: '3. AI Image Processing & Strict Zero-Sale Guarantee',
          content:
              'StyleMorph strictly DOES NOT sell, monetize, or broker personal imagery, biometric features, or styling data to advertisers or commercial data aggregators. Customer photos are never used to train public, open, or third-party foundational AI models without explicit opt-in consent. Image uploads are verified ephemeral via digital SHA-256 hash caching, and users can enable Dual-Persona Private Avatar mode to fit clothes onto a neutral mannequin silhouette without displaying real facial photos.',
        ),
        LegalDocSection(
          title: '4. Essential Third-Party Data Processors',
          content:
              'We partner only with rigorously audited, industry-standard infrastructure providers bound by strict GDPR/SOC-2 data processing agreements: Google Firebase (authentication and database), Google Cloud AI (generative inference pipelines), and Cloudflare Turnstile (bot mitigation and DDoS prevention).',
        ),
        LegalDocSection(
          title:
              '5. Mandatory User Rights (GDPR, CCPA, Apple App Store & Google Play)',
          content:
              'You hold unconditional legal rights to access, rectify, export, and enact the **Permanent Deletion of Your Account and Associated Data** at any time. Data erasure can be triggered immediately via Profile Settings or by emailing support@stylemorph.app; your wardrobe files, try-on history, and session records will be permanently purged from all servers.',
        ),
        LegalDocSection(
          title: '6. Children\'s Privacy Protection & Policy Updates',
          content:
              'StyleMorph is not directed at children under the age of 13, and we do not knowingly collect personal data from minors. Any substantial updates to this Privacy Policy will be highlighted via in-app notifications and updated version logs.',
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
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: AppRadius.rSheetTop,
        border: Border(top: BorderSide(color: colors.bd, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Standardized Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: colors.bd,
                    borderRadius: AppRadius.rFull,
                  ),
                ),
              ),

              // Header Bar with clean 2-line title wrapping & close button
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FaIcon(icon, size: 16, color: colors.prt),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.moduleTitle(color: colors.tx),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colors.mu,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: colors.bd, height: 1.0),

              // Scrollable Legal Sections
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  itemCount: sections.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
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
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Close Button Bar
              Divider(color: colors.bd, height: 1.0),
              Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                child: AppButton(
                  variant: AppButtonVariant.outline,
                  isFullWidth: true,
                  text: strings.aboutClose,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
