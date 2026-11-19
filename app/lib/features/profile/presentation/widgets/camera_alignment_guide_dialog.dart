import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class CameraAlignmentGuideDialog extends StatelessWidget {
  final String slotKey;
  final String slotTitle;

  const CameraAlignmentGuideDialog({
    super.key,
    required this.slotKey,
    required this.slotTitle,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String slotKey,
    required String slotTitle,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CameraAlignmentGuideDialog(
        slotKey: slotKey,
        slotTitle: slotTitle,
      ),
    );
  }

  FaIconData _getSlotIcon() {
    switch (slotKey) {
      case 'front_face':
        return FontAwesomeIcons.solidUser;
      case 'side_face':
        return FontAwesomeIcons.user;
      case 'body_front':
        return FontAwesomeIcons.person;
      case 'body_side':
        return FontAwesomeIcons.personWalking;
      case 'body_back':
        return FontAwesomeIcons.personBooth;
      case 'hand_skin':
        return FontAwesomeIcons.hand;
      case 'scan_360':
        return FontAwesomeIcons.video;
      default:
        return FontAwesomeIcons.camera;
    }
  }

  List<String> _getGuidancePoints(BuildContext context) {
    final strings = context.strings;
    final isEn = strings.localeCode == 'en';
    final isFa = strings.localeCode == 'fa';
    final isAr = strings.localeCode == 'ar';

    if (slotKey == 'front_face') {
      if (isEn) {
        return [
          'Look directly into the camera at eye level.',
          'Keep a neutral facial expression with good, even lighting.',
          'Ensure hair and jawline are clearly visible without sunglasses or hats.',
        ];
      }
      if (isAr) {
        return [
          'انظر مباشرة إلى الكاميرا على مستوى العين.',
          'حافظ على تعبير وجه محايد مع إضاءة جيدة ومتساوية.',
          'تأكد من وضوح خط الفك والشعر دون قبعة أو نظارات شمسية.',
        ];
      }
      if (isFa) {
        return [
          'مستقیماً در راستای تراز چشم به دوربین نگاه کنید.',
          'حالت چهره خنثی باشد و نورپردازی شفاف و یکنواخت باشد.',
          'خط فک و موها کاملاً واضح باشند و از عینک آفتابی یا کلاه استفاده نشود.',
        ];
      }
      // Turkish / default
      return [
        'Göz hizasında doğrudan kameraya bakın.',
        'İyi ve dengeli ışıkta nötr bir yüz ifadesi koruyun.',
        'Güneş gözlüğü veya şapka olmadan çene hattı ve saçın net göründüğünden emin olun.',
      ];
    }

    if (slotKey == 'side_face') {
      if (isEn) {
        return [
          'Turn head 90 degrees to the side profile.',
          'Keep your neck, jawline, and ear clearly visible.',
          'Avoid tilting head up or down.',
        ];
      }
      if (isAr) {
        return [
          'أدر رأسك ٩٠ درجة لعرض جانبي كامل.',
          'تأكد من وضوح خط الرقبة والفك والأذن.',
          'تجنب إمالة الرأس لأعلى أو لأسفل.',
        ];
      }
      if (isFa) {
        return [
          'سر خود را دقیقاً ۹۰ درجه به پهلو بچرخانید.',
          'خط گردن، فک و گوش کاملاً بدون پوشش دیده شوند.',
          'از کج کردن سر به بالا یا پایین خودداری نمایید.',
        ];
      }
      return [
        'Başınızı tam 90 derece yana çevirin.',
        'Boyun, çene hattı ve kulağın net göründüğünden emin olun.',
        'Başınızı yukarı veya aşağı eğmeyin.',
      ];
    }

    if (slotKey == 'body_front') {
      if (isEn) {
        return [
          'Stand in standard A-Pose (arms 30° from body, feet shoulder-width).',
          'Camera at waist height, capturing full body head-to-toe.',
          'Wear form-fitting clothing for optimal 3D mesh modeling.',
        ];
      }
      if (isAr) {
        return [
          'قف في وضع A القياسي (الذراعان بزاوية ٣٠ درجة، القدمان بعرض الكتفين).',
          'الكاميرا بمستوى الخصر لتغطية كامل الجسم من الرأس إلى القدمين.',
          'ارتدِ ملابس ضيقة ومناسبة للحصول على نمذجة ثلاثية الأبعاد دقيقة.',
        ];
      }
      if (isFa) {
        return [
          'در حالت استاندارد A-Pose بایستید (دست‌ها ۳۰ درجه با بدن، پاها به عرض شانه).',
          'دوربین در ارتفاع کمر قرار گیرد تا تمام‌قد از سر تا پا ثبت شود.',
          'لباس جذب و فیت بپوشید تا دقت مش‌بندی سه‌بعدی هوش مصنوعی حداکثر باشد.',
        ];
      }
      return [
        'Standart A-Duruşunda durun (kollar 30° açık, ayaklar omuz hizasında).',
        'Kamera bel hizasında, baştan ayağa tüm vücudu kapsamalıdır.',
        'Optimum 3D modelleme için vücuda oturan giysiler tercih edin.',
      ];
    }

    if (slotKey == 'body_side') {
      if (isEn) {
        return [
          'Turn 90 degrees sideways in A-Pose posture.',
          'Keep spine upright with natural standing balance.',
          'Ensure entire vertical height from head to feet is inside frame.',
        ];
      }
      if (isAr) {
        return [
          'أدر جسمك ٩٠ درجة جانباً في وضع A.',
          'حافظ على استقامة العمود الفقري وتوازن الوقوف الطبيعي.',
          'تأكد من وجود كامل الطول من الرأس إلى القدمين داخل الإطار.',
        ];
      }
      if (isFa) {
        return [
          'تمام بدن را ۹۰ درجه به پهلو بچرخانید و در حالت A-Pose بمانید.',
          'ستون فقرات کاملاً صاف و حالت ایستادن طبیعی باشد.',
          'کادر تصویر تمام قد شما از نوک سر تا انگشتان پا را در بر بگیرد.',
        ];
      }
      return [
        'A-Duruşunda tüm vücudunuzla 90 derece yana dönün.',
        'Omurganızı dik tutun ve doğal bir duruş sergileyin.',
        'Baştan ayağa tüm boyun kadrajda olduğundan emin olun.',
      ];
    }

    if (slotKey == 'body_back') {
      if (isEn) {
        return [
          'Face directly away from the camera in standard A-Pose.',
          'Keep posture upright showing shoulder and waist silhouette.',
          'Ensure camera captures full body from head to heels.',
        ];
      }
      if (isAr) {
        return [
          'قف بظهرك نحو الكاميرا مباشرة في وضع A القياسي.',
          'حافظ على وقفة مستقيمة لإبراز محاذاة الأكتاف والخصر.',
          'تأكد من تصوير الجسم بالكامل من الرأس إلى الكعبين.',
        ];
      }
      if (isFa) {
        return [
          'پشت به دوربین در وضعیت استاندارد A-Pose بایستید.',
          'قامت صاف باشد تا خط شانه و کادر دور کمر دقیق مشخص گردد.',
          'تمام‌قد از پشت سر تا پاشنه پا در کادر قرار گیرد.',
        ];
      }
      return [
        'Standart A-Duruşunda doğrudan sırtınız kameraya dönük durun.',
        'Omuz ve bel siluetini gösterecek şekilde dik durun.',
        'Kameranın baştan topuğa tüm vücudu aldığından emin olun.',
      ];
    }

    if (slotKey == 'hand_skin') {
      if (isEn) {
        return [
          'Hold the back of your hand facing the camera.',
          'Use natural daylight or neutral indoor lighting.',
          'Keep skin texture in sharp focus without harsh shadows.',
        ];
      }
      if (isAr) {
        return [
          'ضع ظهر يدك في مواجهة الكاميرا.',
          'استخدم ضوء النهار الطبيعي أو إضاءة داخلية محايدة.',
          'تأكد من وضوح نسيج البشرة دون ظلال حادة.',
        ];
      }
      if (isFa) {
        return [
          'پشت دست خود را رو به دوربین نگه دارید.',
          'زیر نور طبیعی روز یا نور سفید یکنواخت عکاسی کنید.',
          'بافت پوست کاملاً فوکوس باشد و سایه‌های شدید نیفتد.',
        ];
      }
      return [
        'Elinizin tersini kameraya dönük tutun.',
        'Doğal gün ışığı veya nötr iç mekan aydınlatması kullanın.',
        'Sert gölgeler olmadan cilt dokusunun odakta olduğundan emin olun.',
      ];
    }

    // scan_360
    if (isEn) {
      return [
        'Stand in an open space with good 360° clearance.',
        'Record a smooth, continuous 360° slow rotation in 10-15 seconds.',
        'Keep arms slightly away from the torso in A-Pose while rotating.',
      ];
    }
    if (isAr) {
      return [
        'قف في مساحة مفتوحة تسمح بحرية الحركة ٣٦٠ درجة.',
        'سجل دوراناً بطيئاً وسلساً ٣٦٠ درجة خلال ١٠ إلى ١٥ ثانية.',
        'أبعد الذراعين قليلاً عن الجذع في وضع A أثناء الدوران.',
      ];
    }
    if (isFa) {
      return [
        'در فضایی باز با آزادی چرخش کامل ۳۶۰ درجه بایستید.',
        'یک چرخش آرام و مداوم ۳۶۰ درجه در مدت ۱۰ الی ۱۵ ثانیه ضبط کنید.',
        'هنگام چرخش، دست‌ها در حالت A-Pose کمی از تنه فاصله داشته باشند.',
      ];
    }
    return [
      '360° dönebileceğiniz açık ve aydınlık bir alanda durun.',
      '10-15 saniyede akıcı, yavaş ve kesintisiz 360° tam dönüş kaydedin.',
      'Dönerken kolları A-Duruşunda gövdeden hafif açık tutun.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final points = _getGuidancePoints(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: colors.sf,
          borderRadius: AppRadius.rXl,
          border: Border.all(color: colors.bd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                end: AppSpacing.sm,
                top: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      strings.galAlignmentGuideTitle,
                      style: AppTypography.titleMedium(color: colors.tx),
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Silhouette preview area
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: AppRadius.rLg,
                      border: Border.all(
                        color: colors.pr.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle grid/crosshair lines
                        CustomPaint(
                          size: const Size(double.infinity, 140),
                          painter: _CrosshairPainter(color: colors.bd),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colors.pr.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.pr.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Center(
                                child: FaIcon(
                                  _getSlotIcon(),
                                  size: 28,
                                  color: colors.pr,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              slotTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.tx,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Guidance checklist items
                  ...points.map(
                    (pt) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: FaIcon(
                              FontAwesomeIcons.circleCheck,
                              size: 13,
                              color: colors.ok,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              pt,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11,
                                height: 1.45,
                                color: colors.tx,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: strings.galReadyToCapture,
                      icon: const FaIcon(FontAwesomeIcons.camera, size: 14),
                      variant: AppButtonVariant.primary,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Color color;

  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Center vertical and horizontal dashed guides
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
