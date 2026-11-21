import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class KycImagePreviewDialog extends StatelessWidget {
  final String? imageUrl;
  final XFile? localFile;
  final String title;

  const KycImagePreviewDialog({
    super.key,
    this.imageUrl,
    this.localFile,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    String? imageUrl,
    XFile? localFile,
    required String title,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => KycImagePreviewDialog(
        imageUrl: imageUrl,
        localFile: localFile,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        decoration: BoxDecoration(
          color: colors.sf,
          borderRadius: AppRadius.rXl,
          border: Border.all(color: colors.bd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium(color: colors.tx),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Interactive Image Viewer
            Flexible(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Center(child: _buildImage(colors)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(AppColors colors) {
    if (localFile != null) {
      if (kIsWeb) {
        return Image.network(
          localFile!.path,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _errorPlaceholder(colors),
        );
      }
      return Image.file(
        File(localFile!.path),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _errorPlaceholder(colors),
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                  : null,
              color: colors.pr,
            ),
          );
        },
        errorBuilder: (_, _, _) => _errorPlaceholder(colors),
      );
    }

    return _errorPlaceholder(colors);
  }

  Widget _errorPlaceholder(AppColors colors) {
    return Container(
      height: 200,
      color: colors.bg,
      alignment: Alignment.center,
      child: FaIcon(FontAwesomeIcons.image, size: 40, color: colors.mu),
    );
  }
}
