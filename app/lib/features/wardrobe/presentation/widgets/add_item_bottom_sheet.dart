import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/storage/media_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_media_image.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/wardrobe_item.dart';
import '../wardrobe_provider.dart';

class AddItemBottomSheet extends StatefulWidget {
  const AddItemBottomSheet({
    super.key,
    this.itemToEdit,
    this.initialItem,
    this.onAdd,
    this.onAddWithImage,
    this.onAddWithImages,
    this.onEdit,
    this.onEditWithImage,
    this.onEditWithImages,
    this.initialImageBytes,
    this.initialMimeType,
  });

  final WardrobeItem? itemToEdit;
  final WardrobeItem? initialItem;
  final void Function(WardrobeItem)? onAdd;
  final Future<dynamic> Function({
    required Uint8List imageBytes,
    required String mimeType,
    required String title,
    required String category,
    required String subCategory,
    required String colorName,
    required String colorHex,
    required String season,
    required String occasion,
    required String material,
    required String size,
  })?
  onAddWithImage;

  final Future<void> Function({
    required List<Uint8List> images,
    List<String>? mimeTypes,
    required String title,
    required String category,
    required String subCategory,
    required String colorName,
    required String colorHex,
    required String season,
    required String occasion,
    required String material,
    required String size,
  })?
  onAddWithImages;

  final void Function(WardrobeItem)? onEdit;
  final Future<void> Function({
    required String id,
    Uint8List? newImageBytes,
    String? mimeType,
    required String title,
    required String category,
    required String subCategory,
    required String colorName,
    required String colorHex,
    required String season,
    required String occasion,
    required String material,
    required String size,
  })?
  onEditWithImage;

  final Future<void> Function({
    required String id,
    List<Uint8List?>? slotBytes,
    List<String?>? slotUrls,
    List<String?>? slotMimes,
    required String title,
    required String category,
    required String subCategory,
    required String colorName,
    required String colorHex,
    required String season,
    required String occasion,
    required String material,
    required String size,
  })?
  onEditWithImages;

  final Uint8List? initialImageBytes;
  final String? initialMimeType;

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _subCtrl = TextEditingController(text: 'بالاتنه');
  final _matCtrl = TextEditingController(text: 'نخ / پنبه');
  final _sizeCtrl = TextEditingController(text: 'M');

  String _selectedCat = 'tops';
  String _selectedSeason = 'همه';
  String _selectedOccasion = 'روزمره';
  String _selectedColorName = 'آبی';
  String _selectedColorHex = '#3b6ea5';

  Uint8List? _imageBytes;
  String _imageMimeType = 'image/jpeg';
  Uint8List? _angle2Bytes;
  String _angle2MimeType = 'image/jpeg';
  Uint8List? _angle3Bytes;
  String _angle3MimeType = 'image/jpeg';

  String _existingImageUrl = '';
  String _existingAngle2Url = '';
  String _existingAngle3Url = '';

  bool _photoError = false;
  bool _isSaving = false;

  static const _catOptions = [
    'tops',
    'bottoms',
    'outfit',
    'outerwear',
    'underwear',
    'activewear',
    'footwear',
    'bags',
    'jewelry',
    'accessories',
  ];

  static const _swatches = [
    ('سیاه', '#222222', Color(0xFF222222)),
    ('سفید', '#f4f4f2', Color(0xFFF4F4F2)),
    ('بژ', '#d6bf9b', Color(0xFFD6BF9B)),
    ('قهوه‌ای', '#7a5230', Color(0xFF7A5230)),
    ('آبی', '#3b6ea5', Color(0xFF3B6EA5)),
    ('سرمه‌ای', '#1f2f56', Color(0xFF1F2F56)),
    ('قرمز', '#c0392b', Color(0xFFC0392B)),
    ('سبز', '#4f7a5a', Color(0xFF4F7A5A)),
    ('صورتی', '#e29bb0', Color(0xFFE29BB0)),
    ('طلایی', '#c9a227', Color(0xFFC9A227)),
    ('نقره‌ای', '#a9aeb4', Color(0xFFA9AEB4)),
    ('طوسی', '#8a8f94', Color(0xFF8A8F94)),
  ];

  static const _seasons = ['همه', 'بهار', 'تابستان', 'پاییز', 'زمستان'];
  static const _occasions = ['روزمره', 'رسمی', 'ورزشی', 'مجلسی'];

  WardrobeItem? get effectiveEditItem =>
      widget.itemToEdit ?? widget.initialItem;

  bool get isEditMode => effectiveEditItem != null;

  bool get _hasPhoto =>
      _imageBytes != null || (isEditMode && _existingImageUrl.isNotEmpty);

  @override
  void initState() {
    super.initState();
    final edit = effectiveEditItem;
    if (edit != null) {
      _nameCtrl.text = edit.title;
      _subCtrl.text = edit.subCategory;
      _matCtrl.text = edit.material;
      _sizeCtrl.text = edit.size;
      _selectedCat = edit.category;
      _selectedSeason = edit.season;
      _selectedOccasion = edit.occasion;
      _selectedColorName = edit.colorName;
      _selectedColorHex = edit.colorHex;

      final urls = edit.imageUrls.isNotEmpty
          ? edit.imageUrls
          : (edit.originalUrl.isNotEmpty
                ? [edit.originalUrl]
                : (edit.thumbUrl.isNotEmpty ? [edit.thumbUrl] : <String>[]));
      if (urls.isNotEmpty) _existingImageUrl = urls[0];
      if (urls.length > 1) _existingAngle2Url = urls[1];
      if (urls.length > 2) _existingAngle3Url = urls[2];
    }
    if (widget.initialImageBytes != null) {
      _imageBytes = widget.initialImageBytes;
      _imageMimeType = widget.initialMimeType ?? 'image/jpeg';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subCtrl.dispose();
    _matCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, int slot) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 65,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          if (slot == 0) {
            _imageBytes = bytes;
            _imageMimeType = picked.mimeType ?? 'image/jpeg';
            _photoError = false;
          } else if (slot == 1) {
            _angle2Bytes = bytes;
            _angle2MimeType = picked.mimeType ?? 'image/jpeg';
          } else if (slot == 2) {
            _angle3Bytes = bytes;
            _angle3MimeType = picked.mimeType ?? 'image/jpeg';
          }
        });
      }
    } catch (_) {}
  }

  void _showImageSourcePicker(BuildContext context, int slot) {
    final colors = context.colors;
    final strings = context.strings;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.sf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: colors.pr),
                title: Text(
                  strings.wardPickFromGallery,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.tx,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery, slot);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: colors.pr),
                title: Text(
                  strings.wardTakePhoto,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.tx,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera, slot);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final enteredName = _nameCtrl.text.trim();
    final name = enteredName.isNotEmpty
        ? enteredName
        : context.strings.wardrobeCategoryName(_selectedCat);

    if (!_hasPhoto) {
      setState(() => _photoError = true);
      AppToast.showError(context, context.strings.wardPhotoRequired);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final extraImages = <Uint8List>[];
      final extraMimes = <String>[];
      if (_angle2Bytes != null) {
        extraImages.add(_angle2Bytes!);
        extraMimes.add(_angle2MimeType);
      }
      if (_angle3Bytes != null) {
        extraImages.add(_angle3Bytes!);
        extraMimes.add(_angle3MimeType);
      }

      if (isEditMode) {
        final edit = effectiveEditItem!;
        final slotBytes = [_imageBytes, _angle2Bytes, _angle3Bytes];
        final slotUrls = [
          _imageBytes == null ? _existingImageUrl : null,
          _angle2Bytes == null && _existingAngle2Url.isNotEmpty
              ? _existingAngle2Url
              : null,
          _angle3Bytes == null && _existingAngle3Url.isNotEmpty
              ? _existingAngle3Url
              : null,
        ];
        final slotMimes = [_imageMimeType, _angle2MimeType, _angle3MimeType];

        ProviderContainer? container;
        try {
          container = ProviderScope.containerOf(context, listen: false);
        } catch (_) {}

        if (widget.onEditWithImages != null) {
          await widget.onEditWithImages!(
            id: edit.id,
            slotBytes: slotBytes,
            slotUrls: slotUrls,
            slotMimes: slotMimes,
            title: name,
            category: _selectedCat,
            subCategory: _subCtrl.text.trim().isEmpty
                ? edit.subCategory
                : _subCtrl.text.trim(),
            colorName: _selectedColorName,
            colorHex: _selectedColorHex,
            season: _selectedSeason,
            occasion: _selectedOccasion,
            material: _matCtrl.text.trim().isEmpty
                ? 'پارچه'
                : _matCtrl.text.trim(),
            size: _sizeCtrl.text.trim().isEmpty ? 'M' : _sizeCtrl.text.trim(),
          );
        } else if (container != null) {
          await container
              .read(wardrobeProvider.notifier)
              .updateItemWithImages(
                id: edit.id,
                slotBytes: slotBytes,
                slotUrls: slotUrls,
                slotMimes: slotMimes,
                title: name,
                category: _selectedCat,
                subCategory: _subCtrl.text.trim().isEmpty
                    ? edit.subCategory
                    : _subCtrl.text.trim(),
                colorName: _selectedColorName,
                colorHex: _selectedColorHex,
                season: _selectedSeason,
                occasion: _selectedOccasion,
                material: _matCtrl.text.trim().isEmpty
                    ? 'پارچه'
                    : _matCtrl.text.trim(),
                size: _sizeCtrl.text.trim().isEmpty
                    ? 'M'
                    : _sizeCtrl.text.trim(),
              );
        } else if (widget.onEditWithImage != null) {
          await widget.onEditWithImage!(
            id: edit.id,
            newImageBytes: _imageBytes,
            mimeType: _imageMimeType,
            title: name,
            category: _selectedCat,
            subCategory: _subCtrl.text.trim().isEmpty
                ? edit.subCategory
                : _subCtrl.text.trim(),
            colorName: _selectedColorName,
            colorHex: _selectedColorHex,
            season: _selectedSeason,
            occasion: _selectedOccasion,
            material: _matCtrl.text.trim().isEmpty
                ? 'پارچه'
                : _matCtrl.text.trim(),
            size: _sizeCtrl.text.trim().isEmpty ? 'M' : _sizeCtrl.text.trim(),
          );
        } else if (widget.onEdit != null) {
          final preservedUrls = <String>[];
          if (_imageBytes == null && _existingImageUrl.isNotEmpty) {
            preservedUrls.add(_existingImageUrl);
          }
          if (_angle2Bytes == null && _existingAngle2Url.isNotEmpty) {
            preservedUrls.add(_existingAngle2Url);
          }
          if (_angle3Bytes == null && _existingAngle3Url.isNotEmpty) {
            preservedUrls.add(_existingAngle3Url);
          }
          final updatedItem = edit.copyWith(
            title: name,
            category: _selectedCat,
            subCategory: _subCtrl.text.trim().isEmpty
                ? edit.subCategory
                : _subCtrl.text.trim(),
            colorName: _selectedColorName,
            colorHex: _selectedColorHex,
            season: _selectedSeason,
            occasion: _selectedOccasion,
            material: _matCtrl.text.trim().isEmpty
                ? 'پارچه'
                : _matCtrl.text.trim(),
            size: _sizeCtrl.text.trim().isEmpty ? 'M' : _sizeCtrl.text.trim(),
            aiGarmentZone: WardrobeItem.deriveGarmentZone(_selectedCat),
            imageUrls: preservedUrls.isNotEmpty
                ? preservedUrls
                : edit.imageUrls,
            updatedAt: DateTime.now(),
          );
          widget.onEdit!(updatedItem);
        }
        if (mounted) {
          AppToast.showSuccess(context, context.strings.wardItemUpdated);
          Navigator.of(context).pop();
        }
        return;
      }

      if (widget.onAddWithImages != null && _imageBytes != null) {
        final allImgs = [_imageBytes!, ...extraImages];
        final allMimes = [_imageMimeType, ...extraMimes];
        await widget.onAddWithImages!(
          images: allImgs,
          mimeTypes: allMimes,
          title: name,
          category: _selectedCat,
          subCategory: _subCtrl.text.trim().isEmpty
              ? 'عمومی'
              : _subCtrl.text.trim(),
          colorName: _selectedColorName,
          colorHex: _selectedColorHex,
          season: _selectedSeason,
          occasion: _selectedOccasion,
          material: _matCtrl.text.trim().isEmpty
              ? 'پارچه'
              : _matCtrl.text.trim(),
          size: _sizeCtrl.text.trim().isEmpty ? 'M' : _sizeCtrl.text.trim(),
        );
      } else if (widget.onAddWithImage != null && _imageBytes != null) {
        await widget.onAddWithImage!(
          imageBytes: _imageBytes!,
          mimeType: _imageMimeType,
          title: name,
          category: _selectedCat,
          subCategory: _subCtrl.text.trim().isEmpty
              ? 'عمومی'
              : _subCtrl.text.trim(),
          colorName: _selectedColorName,
          colorHex: _selectedColorHex,
          season: _selectedSeason,
          occasion: _selectedOccasion,
          material: _matCtrl.text.trim().isEmpty
              ? 'پارچه'
              : _matCtrl.text.trim(),
          size: _sizeCtrl.text.trim().isEmpty ? 'M' : _sizeCtrl.text.trim(),
        );
      } else if (widget.onAdd != null) {
        final newItem = WardrobeItem(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          title: name,
          category: _selectedCat,
          subCategory: _subCtrl.text.trim().isEmpty
              ? 'عمومی'
              : _subCtrl.text.trim(),
          colorName: _selectedColorName,
          colorHex: _selectedColorHex,
          season: _selectedSeason,
          occasion: _selectedOccasion,
          material: _matCtrl.text.trim().isEmpty
              ? 'پارچه'
              : _matCtrl.text.trim(),
          size: _sizeCtrl.text.trim().isEmpty ? 'M' : _sizeCtrl.text.trim(),
          isFavorite: false,
          isArchived: false,
          aiGarmentZone: WardrobeItem.deriveGarmentZone(_selectedCat),
        );
        widget.onAdd!(newItem);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      if (e is MediaPayloadTooLargeException) {
        AppToast.showError(context, context.strings.wardPayloadTooLarge);
      } else {
        AppToast.showError(context, context.strings.wardUploadError);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildExtraAngleSlot({
    required int slot,
    required Uint8List? bytes,
    required String existingUrl,
    required String label,
    required AppColors colors,
  }) {
    final hasImage = bytes != null || existingUrl.isNotEmpty;
    return Expanded(
      child: GestureDetector(
        onTap: _isSaving ? null : () => _showImageSourcePicker(context, slot),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: colors.sf,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: hasImage ? colors.pr : colors.bd,
              width: hasImage ? 1.5 : 0.8,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bytes != null)
                      Image.memory(bytes, fit: BoxFit.cover)
                    else
                      AppMediaImage(
                        existingUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 18,
                            color: colors.mu,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (slot == 1) {
                              _angle2Bytes = null;
                              _existingAngle2Url = '';
                            }
                            if (slot == 2) {
                              _angle3Bytes = null;
                              _existingAngle3Url = '';
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colors.sf.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: colors.tx,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 14,
                          color: colors.mu,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: colors.mu,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return AppBottomSheetShell(
      title: isEditMode
          ? strings.wardEditSheetTitle
          : strings.wardAddSheetTitle,
      bottomBar: AppButton(
        isFullWidth: true,
        icon: _isSaving
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.prt,
                ),
              )
            : null,
        text: _isSaving
            ? strings.wardSaving
            : (isEditMode
                  ? strings.wardSaveChanges
                  : strings.wardSaveInWardrobe),
        onPressed: _isSaving ? null : _submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mandatory Primary Image Upload Box with Live Preview
          GestureDetector(
            onTap: _isSaving ? null : () => _showImageSourcePicker(context, 0),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: colors.sf,
                borderRadius: AppRadius.rCard,
                border: Border.all(
                  color: _photoError
                      ? colors.orColor
                      : (_hasPhoto ? colors.ok : colors.bd),
                  width: _photoError || _hasPhoto ? 1.8 : 1.0,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _imageBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: colors.mu,
                            ),
                          ),
                        ),
                        // Overlay controls: Tap to change / Remove button
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _imageBytes = null;
                                if (!isEditMode || _existingImageUrl.isEmpty) {
                                  _photoError = true;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.sf.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: colors.tx,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.sf.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: colors.pr,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  strings.wardChangePhoto,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colors.pr,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : (isEditMode && _existingImageUrl.isNotEmpty)
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        AppMediaImage(
                          _existingImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: colors.mu,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.sf.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: colors.pr,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  strings.wardChangePhoto,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colors.pr,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 28,
                            color: _photoError ? colors.orColor : colors.pr,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.wardPrimaryPhoto,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _photoError ? colors.orColor : colors.tx,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (_photoError) ...[
            const SizedBox(height: 4),
            Text(
              strings.wardPhotoRequiredInline,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.orColor,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),

          // Optional Extra Angles Row (up to 3 total frames)
          Row(
            children: [
              _buildExtraAngleSlot(
                slot: 1,
                bytes: _angle2Bytes,
                existingUrl: _existingAngle2Url,
                label: strings.wardAngle2Photo,
                colors: colors,
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildExtraAngleSlot(
                slot: 2,
                bytes: _angle3Bytes,
                existingUrl: _existingAngle3Url,
                label: strings.wardAngle3Photo,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Item Name (Optional)
          AppTextField(
            label: strings.wardItemName,
            controller: _nameCtrl,
            placeholder: strings.wardItemNameHint,
          ),
          const SizedBox(height: AppSpacing.md),

          // 10 AI-Optimized Category Chips
          Text(
            strings.wardCategory,
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _catOptions.map((code) {
              return AppChip(
                label: strings.wardrobeCategoryName(code),
                isSelected: _selectedCat == code,
                onTap: () => setState(() => _selectedCat = code),
              );
            }).toList(),
          ),

          // Blue Capsule Helper Box for Selected Category
          if (strings.wardrobeCategoryHint(_selectedCat).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colors.inb,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colors.inColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: colors.inColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strings.wardrobeCategoryHint(_selectedCat),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: colors.inColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Color Selector
          Text(
            '${strings.wardSelectedColor}: ${strings.tr(_selectedColorName)}',
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _swatches.map((sw) {
              final isSel = _selectedColorHex == sw.$2;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorName = sw.$1;
                    _selectedColorHex = sw.$2;
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: sw.$3,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? colors.pr : colors.bd,
                      width: isSel ? 2.5 : 1,
                    ),
                  ),
                  child: isSel
                      ? Icon(
                          Icons.check,
                          size: 13,
                          color: sw.$2 == '#f4f4f2'
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Season & Occasion Rows
          Row(
            children: [
              Expanded(
                child: AppDropdown<String>(
                  label: strings.wardSeason,
                  value: _selectedSeason,
                  items: _seasons
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(strings.tr(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSeason = v);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppDropdown<String>(
                  label: strings.wardOccasion,
                  value: _selectedOccasion,
                  items: _occasions
                      .map(
                        (o) => DropdownMenuItem(
                          value: o,
                          child: Text(strings.tr(o)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedOccasion = v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
