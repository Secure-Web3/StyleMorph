import 'package:flutter/material.dart';
import '../domain/stylist_models.dart';

class StylistRepository {
  static final List<StylistOutfit> _outfits = [
    const StylistOutfit(
      id: 'outfit_1',
      title: 'ست راحت شهری',
      occasion: 'روزمره',
      tags: ['هماهنگ با زیرتن گرم', 'مناسب ۱۸ درجه'],
      items: [
        StylistOutfitItem(
          title: 'پیراهن آبی کلاسیک',
          category: 'بالاتنه',
          colorHex: '#3b6ea5',
          icon: Icons.checkroom_rounded,
        ),
        StylistOutfitItem(
          title: 'شلوار جین سرمه‌ای',
          category: 'پایین‌تنه',
          colorHex: '#1f2f56',
          icon: Icons.checkroom_rounded,
        ),
        StylistOutfitItem(
          title: 'بوت چرمی قهوه‌ای',
          category: 'کفش',
          colorHex: '#7a5230',
          icon: Icons.snowshoeing_rounded,
        ),
        StylistOutfitItem(
          title: 'کیف دستی بژ',
          category: 'کیف',
          colorHex: '#d6bf9b',
          icon: Icons.shopping_bag_outlined,
        ),
      ],
    ),
    const StylistOutfit(
      id: 'outfit_2',
      title: 'ست بهاره روشن',
      occasion: 'مهمانی',
      tags: ['رنگ‌های پالت شما', 'مناسب مهمانی'],
      items: [
        StylistOutfitItem(
          title: 'لباس مجلسی قرمز',
          category: 'یکسره',
          colorHex: '#c0392b',
          icon: Icons.dry_cleaning_rounded,
        ),
        StylistOutfitItem(
          title: 'کفش پاشنه‌دار مشکی',
          category: 'کفش',
          colorHex: '#222222',
          icon: Icons.snowshoeing_rounded,
        ),
        StylistOutfitItem(
          title: 'کیف مجلسی نقره‌ای',
          category: 'کیف',
          colorHex: '#a9aeb4',
          icon: Icons.shopping_bag_outlined,
        ),
        StylistOutfitItem(
          title: 'گردنبند طلایی',
          category: 'زیورآلات',
          colorHex: '#c9a227',
          icon: Icons.diamond_outlined,
        ),
      ],
    ),
    const StylistOutfit(
      id: 'outfit_3',
      title: 'ست ساده و گرم',
      occasion: 'کار',
      tags: ['لایه‌بندی راحت', 'با ۵ لباس دیگر ست می‌شود'],
      items: [
        StylistOutfitItem(
          title: 'پالتو مشکی اداری',
          category: 'رویه‌پوش',
          colorHex: '#222222',
          icon: Icons.person_pin_rounded,
        ),
        StylistOutfitItem(
          title: 'هودی طوسی ساده',
          category: 'بالاتنه',
          colorHex: '#8a8f94',
          icon: Icons.checkroom_rounded,
        ),
        StylistOutfitItem(
          title: 'کفش رسمی چرم',
          category: 'کفش',
          colorHex: '#7a5230',
          icon: Icons.snowshoeing_rounded,
        ),
        StylistOutfitItem(
          title: 'شال سبز پشمی',
          category: 'اکسسوری',
          colorHex: '#4f7a5a',
          icon: Icons.style_outlined,
        ),
      ],
    ),
  ];

  static final List<ChatMessage> _initialMessages = [
    ChatMessage(
      id: 'msg_1',
      text:
          'سلام سارا عزیز! امروز هوا ۱۸ درجه و آفتابی‌ست. با توجه به برنامه کاری امروز، این ست راحت و شیک شهری را از کمد خودتان پیشنهاد می‌کنم.',
      isUser: false,
      timestamp: DateTime(2026, 11, 9, 8, 30),
      outfitAttachment: const StylistOutfit(
        id: 'outfit_chat',
        title: 'ست راحت شهری',
        occasion: 'روزمره',
        tags: ['هماهنگ با زیرتن گرم'],
        items: [
          StylistOutfitItem(
            title: 'پیراهن آبی',
            category: 'بالاتنه',
            colorHex: '#3b6ea5',
            icon: Icons.checkroom_rounded,
          ),
          StylistOutfitItem(
            title: 'شلوار جین سرمه‌ای',
            category: 'پایین‌تنه',
            colorHex: '#1f2f56',
            icon: Icons.checkroom_rounded,
          ),
        ],
      ),
    ),
    ChatMessage(
      id: 'msg_2',
      text: 'یک گزینه رسمی‌تر هم برای جلسه عصر در نظر داری؟',
      isUser: true,
      timestamp: DateTime(2026, 11, 9, 8, 32),
    ),
    ChatMessage(
      id: 'msg_3',
      text:
          'بله حتماً! می‌توانیم کت سرمه‌ای را با کفش رسمی طوسی جایگزین کنیم تا کاملاً حالت کاری و فاخر به خود بگیرد.',
      isUser: false,
      timestamp: DateTime(2026, 11, 9, 8, 33),
    ),
  ];

  List<StylistOutfit> getOutfits() => List.unmodifiable(_outfits);

  List<ChatMessage> getInitialMessages() => List.unmodifiable(_initialMessages);

  void toggleLock(String id) {
    final idx = _outfits.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _outfits[idx] = _outfits[idx].copyWith(isLocked: !_outfits[idx].isLocked);
    }
  }

  void toggleSave(String id) {
    final idx = _outfits.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _outfits[idx] = _outfits[idx].copyWith(isSaved: !_outfits[idx].isSaved);
    }
  }
}
