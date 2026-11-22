import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_text_field.dart';

class _PackageLicenseGroup {
  final String packageName;
  final List<LicenseEntry> entries;

  const _PackageLicenseGroup({
    required this.packageName,
    required this.entries,
  });
}

class OpenSourceLicensesSheet extends StatefulWidget {
  const OpenSourceLicensesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppModal.showSheet(
      context: context,
      child: const OpenSourceLicensesSheet(),
    );
  }

  @override
  State<OpenSourceLicensesSheet> createState() =>
      _OpenSourceLicensesSheetState();
}

class _OpenSourceLicensesSheetState extends State<OpenSourceLicensesSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<_PackageLicenseGroup> _packages = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLicenses() async {
    final Map<String, List<LicenseEntry>> packageMap = {};

    try {
      await for (final entry in LicenseRegistry.licenses) {
        for (final package in entry.packages) {
          packageMap.putIfAbsent(package, () => <LicenseEntry>[]).add(entry);
        }
      }
    } catch (_) {}

    final sortedKeys = packageMap.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (mounted) {
      setState(() {
        _packages = sortedKeys
            .map(
              (name) => _PackageLicenseGroup(
                packageName: name,
                entries: packageMap[name]!,
              ),
            )
            .toList();
        _isLoading = false;
      });
    }
  }

  void _showPackageDetail(BuildContext context, _PackageLicenseGroup group) {
    final colors = context.colors;
    final strings = context.strings;
    final count = group.entries.length;
    final formattedCount = strings.formatNumber(count);
    final countLabel =
        '$formattedCount ${count == 1 ? strings.aboutLicenseSingular : strings.aboutLicensesCount}';

    AppModal.showAppDialog(
      context: context,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          maxWidth: 430,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.pr.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 16,
                      color: colors.prt,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.tx,
                        ),
                      ),
                      Text(
                        countLabel,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          color: colors.mu,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: colors.mu),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: colors.bd, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: colors.bd.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < group.entries.length; i++) ...[
                        if (i > 0) ...[
                          const SizedBox(height: AppSpacing.md),
                          Divider(color: colors.bd, height: 16),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        for (final p in group.entries[i].paragraphs)
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: p.indent * 12.0,
                              bottom: AppSpacing.xs,
                            ),
                            child: Text(
                              p.text,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                color: colors.tx.withValues(alpha: 0.85),
                                height: 1.45,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              variant: AppButtonVariant.outline,
              isFullWidth: true,
              text: strings.aboutClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    final filtered = _searchQuery.isEmpty
        ? _packages
        : _packages
              .where(
                (p) => p.packageName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    return AppBottomSheetShell(
      title: strings.aboutLicensesTitle,
      titleLeading: FaIcon(
        FontAwesomeIcons.codeBranch,
        size: 16,
        color: colors.prt,
      ),
      scrollable: false,
      contentPadding: EdgeInsetsDirectional.zero,
      bottomBar: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: AppButton(
          variant: AppButtonVariant.outline,
          isFullWidth: true,
          text: strings.aboutClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: AppTextField(
                controller: _searchController,
                placeholder: strings.aboutSearchLicensesHint,
                prefix: Icon(Icons.search_rounded, size: 16, color: colors.mu),
                suffix: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 16,
                          color: colors.mu,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
              ),
            ),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.prt,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        strings.aboutLoadingLicenses,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: colors.mu,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 36,
                          color: colors.mu.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          strings.aboutNoLicensesFound,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            color: colors.mu,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return AppCard(
                      variant: AppCardVariant.surface,
                      onTap: () => _showPackageDetail(context, item),
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colors.pr.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 12,
                                color: colors.prt,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs + 2),
                          Expanded(
                            child: Text(
                              item.packageName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colors.tx,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          AppBadge(
                            variant: AppBadgeVariant.standard,
                            size: AppBadgeSize.sm,
                            child: Text(
                              strings.formatNumber(item.entries.length),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
