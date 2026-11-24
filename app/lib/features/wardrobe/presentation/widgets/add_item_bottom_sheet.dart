import 'dart:typed_data';
import 'package:flutter/material.dart';
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

class AddItemBottomSheet extends StatefulWidget {
  const AddItemBottomSheet({
    super.key,
    this.itemToEdit,
    this.onAdd,
    this.onAddWithImage,
    this.onEdit,
    this.onEditWithImage,
    this.initialImageBytes,
    this.initialMimeType,
  });

  final WardrobeItem? itemToEdit;
  final void Function(WardrobeItem)? onAdd;
  final Future<void> Function({
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

  String _selectedCat = 'cl';
  String _selectedSeason = 'همه';
  String _selectedOccasion = 'روزمره';
  String _selectedColorName = 'آبی';
  String _selectedColorHex = '#3b6ea5';

  Uint8List? _imageBytes;
  String _imageMimeType = 'image/jpeg';
  bool _photoError = false;
  bool _nameError = false;
  bool _isSaving = false;

  static const _catOptions = [
    ('cl', 'لباس'),
    ('sh', 'کفش'),
    ('bg', 'کیف'),
    ('jw', 'زیورآلات'),
    ('ac', 'اکسسوری'),
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

  bool get isEditMode => widget.itemToEdit != null;

  String get _existingImageUrl {
    final edit = widget.itemToEdit;
    if (edit == null) return '';
    return edit.originalUrl.isNotEmpty ? edit.originalUrl : edit.thumbUrl;
  }

  bool get _hasPhoto =>
      _imageBytes != null || (isEditMode && _existingImageUrl.isNotEmpty);

  @override
  void initState() {
    super.initState();
    final edit = widget.itemToEdit;
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

  Future<void> _pickImage(ImageSource source) async {
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
          _imageBytes = bytes;
          _imageMimeType = picked.mimeType ?? 'image/jpeg';
          _photoError = false;
        });
      }
    } catch (_) {}
  }

  void _showImageSourcePicker(BuildContext context) {
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
                  _pickImage(ImageSource.gallery);
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
                  _pickImage(ImageSource.camera);
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

    final name = _nameCtrl.text.trim();
    bool hasError = false;

    if (!_hasPhoto) {
      setState(() => _photoError = true);
      AppToast.showError(context, context.strings.wardPhotoRequired);
      hasError = true;
    }

    if (name.isEmpty) {
      setState(() => _nameError = true);
      AppToast.showError(context, context.strings.wardItemNameRequired);
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isSaving = true);

    try {
      if (isEditMode) {
        final edit = widget.itemToEdit!;
        if (widget.onEditWithImage != null) {
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

      if (widget.onAddWithImage != null) {
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
          // Mandatory Image Upload Box with Live Preview
          GestureDetector(
            onTap: _isSaving ? null : () => _showImageSourcePicker(context),
            child: Container(
              height: 120,
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
                            size: 32,
                            color: _photoError ? colors.orColor : colors.pr,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            strings.wardImgClick,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _photoError ? colors.orColor : colors.tx,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            strings.wardPhotoRequiredInline,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10,
                              color: _photoError ? colors.orColor : colors.mu,
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
          const SizedBox(height: AppSpacing.md),

          // Item Name
          AppTextField(
            label: strings.wardItemName,
            controller: _nameCtrl,
            placeholder: strings.wardItemNameHint,
            onChanged: (val) {
              if (_nameError && val.trim().isNotEmpty) {
                setState(() => _nameError = false);
              }
            },
          ),
          if (_nameError) ...[
            const SizedBox(height: 4),
            Text(
              strings.wardItemNameRequired,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.orColor,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Category Chips
          Text(
            strings.wardCategory,
            style: AppTypography.inputLabel(color: colors.tx),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _catOptions.map((opt) {
              return AppChip(
                label: strings.tr(opt.$2),
                isSelected: _selectedCat == opt.$1,
                onTap: () => setState(() => _selectedCat = opt.$1),
              );
            }).toList(),
          ),
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
