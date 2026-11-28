import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/digit_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';

/// Legacy section model retained for backwards compatibility.
class LegalDocSection {
  final String title;
  final String content;

  const LegalDocSection({required this.title, required this.content});
}

/// Upgraded Legal Documents Modal Sheet (Version 2.0).
/// Features a layered UI: Top Summary Card + 3 Segmented Tabs + Collapsible Accordions.
class LegalDocModalSheet extends StatefulWidget {
  final String? title;
  final FaIconData? icon;
  final int initialTab;
  final bool previewOnly;
  final List<LegalDocSection>? customSections;

  const LegalDocModalSheet({
    super.key,
    this.title,
    this.icon,
    this.initialTab = 0,
    this.previewOnly = false,
    this.customSections,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    FaIconData? icon,
    int initialTab = 0,
    bool previewOnly = false,
    List<LegalDocSection>? sections,
  }) {
    return AppModal.showSheet(
      context: context,
      child: LegalDocModalSheet(
        title: title,
        icon: icon,
        initialTab: initialTab,
        previewOnly: previewOnly,
        customSections: sections,
      ),
    );
  }

  static void showTerms(BuildContext context, {bool previewOnly = false}) {
    show(
      context,
      initialTab: 0,
      previewOnly: previewOnly,
      title: context.strings.aboutTermsTitle,
      icon: FontAwesomeIcons.fileContract,
    );
  }

  static void showPrivacy(BuildContext context, {bool previewOnly = false}) {
    show(
      context,
      initialTab: 1,
      previewOnly: previewOnly,
      title: context.strings.aboutPrivacyTitle,
      icon: FontAwesomeIcons.shieldHalved,
    );
  }

  static void showLegalInfo(BuildContext context, {bool previewOnly = false}) {
    show(
      context,
      initialTab: 2,
      previewOnly: previewOnly,
      title: context.strings.legalTabLegalInfo,
      icon: FontAwesomeIcons.buildingColumns,
    );
  }

  static List<LegalDocSection> getTermsSections(String localeCode) {
    final clauses = LegalDocumentV2.getTermsClauses(localeCode);
    return clauses
        .map(
          (c) => LegalDocSection(
            title:
                '${DigitFormatter.localizeDigits(c.number.toString(), localeCode)}. ${c.title}',
            content: c.body,
          ),
        )
        .toList();
  }

  static List<LegalDocSection> getPrivacySections(String localeCode) {
    final clauses = LegalDocumentV2.getPrivacyClauses(localeCode);
    return clauses
        .map(
          (c) => LegalDocSection(
            title:
                '${DigitFormatter.localizeDigits(c.number.toString(), localeCode)}. ${c.title}',
            content: c.body,
          ),
        )
        .toList();
  }

  @override
  State<LegalDocModalSheet> createState() => _LegalDocModalSheetState();
}

class _LegalDocModalSheetState extends State<LegalDocModalSheet> {
  late int _selectedTab;
  final Set<int> _expandedTermsIndices = {};
  final Set<int> _expandedPrivacyIndices = {};
  bool _summaryExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 2);
  }

  void _toggleAllClauses(int totalCount, bool isTerms) {
    final set = isTerms ? _expandedTermsIndices : _expandedPrivacyIndices;
    setState(() {
      if (set.length == totalCount) {
        set.clear();
      } else {
        set.clear();
        for (int i = 0; i < totalCount; i++) {
          set.add(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    final displayTitle = widget.title ?? strings.aboutContractModalTitle;
    final displayIcon = widget.icon ?? FontAwesomeIcons.fileContract;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
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
              // Drag Handle
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

              // Header Bar
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    FaIcon(displayIcon, size: 16, color: colors.prt),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        displayTitle,
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
                    ),
                  ],
                ),
              ),
              Divider(color: colors.bd, height: 1.0),

              // Segmented Tabs Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: _buildSegmentedTabs(colors, strings),
              ),

              // Scrollable Body
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  children: [
                    // Doc Modal: Always-Visible Summary Card (7 Key Points)
                    _buildSummaryCard(colors, strings),
                    const SizedBox(height: AppSpacing.md),

                    // Layer 3: Active Tab Content (Collapsible Accordions or Impressum)
                    if (_selectedTab == 0)
                      _buildClausesTab(
                        context,
                        colors,
                        strings,
                        LegalDocumentV2.getTermsClauses(strings.localeCode),
                        isTerms: true,
                      )
                    else if (_selectedTab == 1)
                      _buildClausesTab(
                        context,
                        colors,
                        strings,
                        LegalDocumentV2.getPrivacyClauses(strings.localeCode),
                        isTerms: false,
                      )
                    else
                      _buildLegalInfoTab(colors, strings),
                  ],
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

  Widget _buildSegmentedTabs(AppColors colors, AppStrings strings) {
    return Container(
      decoration: BoxDecoration(
        color: colors.pr.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.bd, width: 1.0),
      ),
      padding: const EdgeInsets.all(3.0),
      child: Row(
        children: [
          Expanded(
            child: _buildTabPill(
              title: strings.legalTabTerms,
              isSelected: _selectedTab == 0,
              colors: colors,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          Expanded(
            child: _buildTabPill(
              title: strings.legalTabPrivacy,
              isSelected: _selectedTab == 1,
              colors: colors,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
          Expanded(
            child: _buildTabPill(
              title: strings.legalTabLegalInfo,
              isSelected: _selectedTab == 2,
              colors: colors,
              onTap: () => setState(() => _selectedTab = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required String title,
    required bool isSelected,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected ? colors.pr : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.pr.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? colors.sf : colors.mu,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AppColors colors, AppStrings strings) {
    final keyPoints = LegalDocumentV2.getKeyPoints(strings.localeCode);

    return AppCard(
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      borderColor: colors.pr.withValues(alpha: 0.35),
      borderWidth: 1.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _summaryExpanded = !_summaryExpanded),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 16, color: colors.pr),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    strings.legalSummaryTitle,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.pr,
                    ),
                  ),
                ),
                Icon(
                  _summaryExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: colors.mu,
                ),
              ],
            ),
          ),
          if (_summaryExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: colors.bd, height: 1.0),
            const SizedBox(height: AppSpacing.sm),
            ...keyPoints.map(
              (kp) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 13,
                        color: colors.ok,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11.5,
                            color: colors.tx,
                            height: 1.45,
                          ),
                          children: [
                            TextSpan(
                              text: '${kp.headline}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: kp.detail,
                              style: TextStyle(
                                color: colors.mu,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClausesTab(
    BuildContext context,
    AppColors colors,
    AppStrings strings,
    List<LegalClause> clauses, {
    required bool isTerms,
  }) {
    final expandedSet = isTerms
        ? _expandedTermsIndices
        : _expandedPrivacyIndices;
    final isAllExpanded = expandedSet.length == clauses.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls Row: Count + Expand/Collapse All Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${DigitFormatter.localizeDigits(clauses.length.toString(), strings.localeCode)} ${isTerms ? strings.legalTabTerms : strings.legalTabPrivacy}',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.mu,
              ),
            ),
            TextButton.icon(
              onPressed: () => _toggleAllClauses(clauses.length, isTerms),
              icon: Icon(
                isAllExpanded
                    ? Icons.unfold_less_rounded
                    : Icons.unfold_more_rounded,
                size: 15,
                color: colors.pr,
              ),
              label: Text(
                isAllExpanded
                    ? strings.legalCollapseAll
                    : strings.legalExpandAll,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.pr,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Accordion Cards List
        ...clauses.asMap().entries.map((entry) {
          final index = entry.key;
          final clause = entry.value;
          final isExpanded = expandedSet.contains(index);

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          expandedSet.remove(index);
                        } else {
                          expandedSet.add(index);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Localized Number Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.pr.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            DigitFormatter.localizeDigits(
                              '${clause.number}.',
                              strings.localeCode,
                            ),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.pr,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),

                        // Title + 1-Line Short Summary
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clause.title,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.tx,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                clause.shortSummary,
                                maxLines: isExpanded ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: colors.mu,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),

                        // Chevron Icon
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: colors.mu,
                        ),
                      ],
                    ),
                  ),

                  // Expanded Body Text
                  if (isExpanded) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Divider(color: colors.bd, height: 1.0),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      clause.body,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colors.tx,
                        height: 1.55,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLegalInfoTab(AppColors colors, AppStrings strings) {
    final entries = LegalDocumentV2.getLegalInfoEntries(strings.localeCode);
    final disputeNotice = LegalDocumentV2.getDisputeResolutionNotice(
      strings.localeCode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Provider Details Table Card
        AppCard(
          variant: AppCardVariant.surface,
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.buildingColumns,
                    size: 14,
                    color: colors.pr,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      strings.legalTabLegalInfo,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.tx,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Divider(color: colors.bd, height: 1.0),
              const SizedBox(height: AppSpacing.sm),
              ...entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          e.label,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.mu,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
        const SizedBox(height: AppSpacing.md),

        // Dispute Resolution Notice Card
        AppCard(
          variant: AppCardVariant.surface,
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          borderColor: colors.pr.withValues(alpha: 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel_rounded, size: 15, color: colors.pr),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      strings.legalDisputeResolutionTitle,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.tx,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                disputeNotice,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: colors.mu,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full interactive agreement modal sheet displaying the complete layered v2.0 text
/// with 3 pinned bottom controls (Signature Checkbox, Confirm & Sign Button, Cancel Button)
/// or an Electronic Audit Receipt if already accepted.
class FullContractModalSheet extends StatefulWidget {
  final Future<void> Function()? onSign;
  final bool isReadOnlyAudit;
  final bool previewOnly;
  final LegalConsentAudit? audit;
  final int initialTab;

  const FullContractModalSheet({
    super.key,
    this.onSign,
    this.isReadOnlyAudit = false,
    this.previewOnly = false,
    this.audit,
    this.initialTab = 0,
  });

  static Future<bool?> show(
    BuildContext context, {
    Future<void> Function()? onSign,
    bool isReadOnlyAudit = false,
    bool previewOnly = false,
    LegalConsentAudit? audit,
    int initialTab = 0,
  }) {
    return AppModal.showSheet<bool>(
      context: context,
      child: FullContractModalSheet(
        onSign: onSign,
        isReadOnlyAudit: isReadOnlyAudit,
        previewOnly: previewOnly,
        audit: audit,
        initialTab: initialTab,
      ),
    );
  }

  @override
  State<FullContractModalSheet> createState() => _FullContractModalSheetState();
}

class _FullContractModalSheetState extends State<FullContractModalSheet> {
  bool _agreed = false;
  bool _isSigning = false;
  late int _selectedTab;
  final Set<int> _expandedTermsIndices = {};
  final Set<int> _expandedPrivacyIndices = {};
  bool _summaryExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 2);
  }

  void _toggleAllClauses(int totalCount, bool isTerms) {
    final set = isTerms ? _expandedTermsIndices : _expandedPrivacyIndices;
    setState(() {
      if (set.length == totalCount) {
        set.clear();
      } else {
        set.clear();
        for (int i = 0; i < totalCount; i++) {
          set.add(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
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
              // Drag Handle
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

              // Header Bar
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.fileContract,
                      size: 16,
                      color: colors.prt,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        strings.aboutContractModalTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.moduleTitle(color: colors.tx),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSigning
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colors.mu,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.xs),
                    ),
                  ],
                ),
              ),
              Divider(color: colors.bd, height: 1.0),

              // Segmented Tabs Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: _buildSegmentedTabs(colors, strings),
              ),

              // Scrollable Legal Contract
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  children: [
                    if (!widget.previewOnly && widget.isReadOnlyAudit) ...[
                      _buildAuditReceiptCard(context, colors, strings),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Layer 1: Always-Visible Summary Card (7 Key Points)
                    _buildSummaryCard(colors, strings),
                    const SizedBox(height: AppSpacing.md),

                    // Layer 3: Active Tab Content
                    if (_selectedTab == 0)
                      _buildClausesTab(
                        context,
                        colors,
                        strings,
                        LegalDocumentV2.getTermsClauses(strings.localeCode),
                        isTerms: true,
                      )
                    else if (_selectedTab == 1)
                      _buildClausesTab(
                        context,
                        colors,
                        strings,
                        LegalDocumentV2.getPrivacyClauses(strings.localeCode),
                        isTerms: false,
                      )
                    else
                      _buildLegalInfoTab(colors, strings),
                  ],
                ),
              ),

              // Pinned Bottom Controls (Close Button if previewOnly or audit, else Checkbox & Sign)
              Divider(color: colors.bd, height: 1.0),
              if (widget.previewOnly || widget.isReadOnlyAudit)
                Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: AppButton(
                    key: const Key('contract_audit_close_button'),
                    variant: AppButtonVariant.primary,
                    isFullWidth: true,
                    text: strings.aboutClose,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Control 1: Electronic Signature Consent Checkbox (13+ & v2.0)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            key: const Key('agreement_checkbox'),
                            value: _agreed,
                            activeColor: colors.pr,
                            onChanged: _isSigning
                                ? null
                                : (val) {
                                    setState(() => _agreed = val ?? false);
                                  },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isSigning
                                  ? null
                                  : () {
                                      setState(() => _agreed = !_agreed);
                                    },
                              child: Text(
                                strings.aboutAgreementCheckbox,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.tx,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Control 2: Confirm & Sign Button
                      AppButton(
                        key: const Key('agreement_sign_button'),
                        variant: AppButtonVariant.primary,
                        isFullWidth: true,
                        icon: _isSigning
                            ? null
                            : const Icon(Icons.draw_rounded, size: 16),
                        text: _isSigning ? null : strings.aboutAgreementSignBtn,
                        onPressed:
                            (_agreed && !_isSigning && widget.onSign != null)
                            ? () async {
                                setState(() => _isSigning = true);
                                try {
                                  await widget.onSign!();
                                  if (context.mounted) {
                                    Navigator.of(context).pop(true);
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSigning = false);
                                  }
                                }
                              }
                            : null,
                        child: _isSigning
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.sf,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Control 3: Close / Cancel Button
                      AppButton(
                        key: const Key('agreement_cancel_button'),
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.sm,
                        isFullWidth: true,
                        text: strings.aboutCancelSignBtn,
                        onPressed: _isSigning
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs(AppColors colors, AppStrings strings) {
    return Container(
      decoration: BoxDecoration(
        color: colors.pr.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.bd, width: 1.0),
      ),
      padding: const EdgeInsets.all(3.0),
      child: Row(
        children: [
          Expanded(
            child: _buildTabPill(
              title: strings.legalTabTerms,
              isSelected: _selectedTab == 0,
              colors: colors,
              onTap: () => setState(() => _selectedTab = 0),
            ),
          ),
          Expanded(
            child: _buildTabPill(
              title: strings.legalTabPrivacy,
              isSelected: _selectedTab == 1,
              colors: colors,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ),
          Expanded(
            child: _buildTabPill(
              title: strings.legalTabLegalInfo,
              isSelected: _selectedTab == 2,
              colors: colors,
              onTap: () => setState(() => _selectedTab = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required String title,
    required bool isSelected,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected ? colors.pr : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.pr.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? colors.sf : colors.mu,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AppColors colors, AppStrings strings) {
    final keyPoints = LegalDocumentV2.getKeyPoints(strings.localeCode);

    return AppCard(
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      borderColor: colors.pr.withValues(alpha: 0.35),
      borderWidth: 1.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _summaryExpanded = !_summaryExpanded),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 16, color: colors.pr),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    strings.legalSummaryTitle,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.pr,
                    ),
                  ),
                ),
                Icon(
                  _summaryExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: colors.mu,
                ),
              ],
            ),
          ),
          if (_summaryExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: colors.bd, height: 1.0),
            const SizedBox(height: AppSpacing.sm),
            ...keyPoints.map(
              (kp) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 13,
                        color: colors.ok,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11.5,
                            color: colors.tx,
                            height: 1.45,
                          ),
                          children: [
                            TextSpan(
                              text: '${kp.headline}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: kp.detail,
                              style: TextStyle(
                                color: colors.mu,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClausesTab(
    BuildContext context,
    AppColors colors,
    AppStrings strings,
    List<LegalClause> clauses, {
    required bool isTerms,
  }) {
    final expandedSet = isTerms
        ? _expandedTermsIndices
        : _expandedPrivacyIndices;
    final isAllExpanded = expandedSet.length == clauses.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls Row: Count + Expand/Collapse All Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${DigitFormatter.localizeDigits(clauses.length.toString(), strings.localeCode)} ${isTerms ? strings.legalTabTerms : strings.legalTabPrivacy}',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.mu,
              ),
            ),
            TextButton.icon(
              onPressed: () => _toggleAllClauses(clauses.length, isTerms),
              icon: Icon(
                isAllExpanded
                    ? Icons.unfold_less_rounded
                    : Icons.unfold_more_rounded,
                size: 15,
                color: colors.pr,
              ),
              label: Text(
                isAllExpanded
                    ? strings.legalCollapseAll
                    : strings.legalExpandAll,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.pr,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Accordion Cards List
        ...clauses.asMap().entries.map((entry) {
          final index = entry.key;
          final clause = entry.value;
          final isExpanded = expandedSet.contains(index);

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              variant: AppCardVariant.surface,
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          expandedSet.remove(index);
                        } else {
                          expandedSet.add(index);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Localized Number Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.pr.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            DigitFormatter.localizeDigits(
                              '${clause.number}.',
                              strings.localeCode,
                            ),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.pr,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),

                        // Title + 1-Line Short Summary
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clause.title,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.tx,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                clause.shortSummary,
                                maxLines: isExpanded ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: colors.mu,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),

                        // Chevron Icon
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: colors.mu,
                        ),
                      ],
                    ),
                  ),

                  // Expanded Body Text
                  if (isExpanded) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Divider(color: colors.bd, height: 1.0),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      clause.body,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colors.tx,
                        height: 1.55,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLegalInfoTab(AppColors colors, AppStrings strings) {
    final entries = LegalDocumentV2.getLegalInfoEntries(strings.localeCode);
    final disputeNotice = LegalDocumentV2.getDisputeResolutionNotice(
      strings.localeCode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Provider Details Table Card
        AppCard(
          variant: AppCardVariant.surface,
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.buildingColumns,
                    size: 14,
                    color: colors.pr,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      strings.legalTabLegalInfo,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.tx,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Divider(color: colors.bd, height: 1.0),
              const SizedBox(height: AppSpacing.sm),
              ...entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          e.label,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.mu,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
        const SizedBox(height: AppSpacing.md),

        // Dispute Resolution Notice Card
        AppCard(
          variant: AppCardVariant.surface,
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          borderColor: colors.pr.withValues(alpha: 0.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel_rounded, size: 15, color: colors.pr),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      strings.legalDisputeResolutionTitle,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.tx,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                disputeNotice,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: colors.mu,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditReceiptCard(
    BuildContext context,
    AppColors colors,
    AppStrings strings,
  ) {
    final audit = widget.audit;
    final acceptedAt = audit?.acceptedAt;
    final dateStr = acceptedAt != null
        ? '${acceptedAt.year}-${acceptedAt.month.toString().padLeft(2, '0')}-${acceptedAt.day.toString().padLeft(2, '0')} ${acceptedAt.hour.toString().padLeft(2, '0')}:${acceptedAt.minute.toString().padLeft(2, '0')} UTC'
        : strings.aboutAuditNotRecorded;
    final localizedDate = DigitFormatter.localizeDigits(
      dateStr,
      strings.localeCode,
    );

    final signerName =
        (audit?.signerName != null && audit!.signerName.isNotEmpty)
        ? audit.signerName
        : strings.aboutAuditNotRecorded;
    final signerEmail =
        (audit?.signerEmail != null && audit!.signerEmail.isNotEmpty)
        ? audit.signerEmail
        : strings.aboutAuditNotRecorded;
    final signerUid = (audit?.signerUid != null && audit!.signerUid.isNotEmpty)
        ? audit.signerUid
        : strings.aboutAuditNotRecorded;

    final rawVer =
        (audit?.contractVersion != null && audit!.contractVersion.isNotEmpty)
        ? audit.contractVersion
        : LegalDocumentV2.version;
    final cleanVer = rawVer.startsWith('v') ? rawVer : 'v$rawVer';
    final versionStr = DigitFormatter.localizeDigits(
      cleanVer,
      strings.localeCode,
    );

    final rawHash = audit?.documentHash;
    final hashDisplay = (rawHash != null && rawHash.isNotEmpty)
        ? rawHash
        : strings.aboutAuditHashLegacy;

    final ipLoc = [
      if (audit?.ipAddress != null && audit!.ipAddress!.isNotEmpty)
        audit.ipAddress!,
      if (audit?.ipLocation != null && audit!.ipLocation!.isNotEmpty)
        audit.ipLocation!,
    ].join(' · ');
    final ipDisplay = ipLoc.isNotEmpty
        ? DigitFormatter.localizeDigits(ipLoc, strings.localeCode)
        : strings.aboutAuditNotRecorded;

    final deviceDisplay =
        (audit?.deviceInfo != null && audit!.deviceInfo!.isNotEmpty)
        ? audit.deviceInfo!
        : strings.aboutAuditNotRecorded;

    return AppCard(
      key: const Key('contract_audit_receipt_card'),
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      borderColor: colors.ok.withValues(alpha: 0.5),
      borderWidth: 1.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Verification Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_rounded, size: 16, color: colors.ok),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      strings.aboutAuditReceiptTitle,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.tx,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.ok.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: colors.ok.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: colors.ok,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      strings.aboutAuditVerifiedBadge,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.ok,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: colors.bd.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Key Audit Details
          _buildAuditRow(strings.aboutAuditSignedAt, localizedDate, colors),
          const SizedBox(height: 4),
          _buildAuditRow(strings.aboutAuditSignerName, signerName, colors),
          const SizedBox(height: 4),
          _buildAuditRow(strings.aboutAuditSignerEmail, signerEmail, colors),
          const SizedBox(height: 4),
          _buildAuditRow(strings.aboutAuditSignerUid, signerUid, colors),
          const SizedBox(height: 4),
          _buildAuditRow(strings.aboutAuditContractVer, versionStr, colors),
          const SizedBox(height: 4),
          _buildAuditRow(
            strings.aboutAuditDocHash,
            hashDisplay,
            colors,
            isMonospace: rawHash != null && rawHash.isNotEmpty,
          ),
          const SizedBox(height: 4),
          _buildAuditRow(strings.aboutAuditIpLoc, ipDisplay, colors),
          const SizedBox(height: 4),
          _buildAuditRow(strings.aboutAuditDevice, deviceDisplay, colors),
        ],
      ),
    );
  }

  Widget _buildAuditRow(
    String label,
    String value,
    AppColors colors, {
    bool isMonospace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: colors.mu,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: isMonospace ? 'monospace' : 'Vazirmatn',
              fontSize: isMonospace ? 9.5 : 10.5,
              fontWeight: FontWeight.w600,
              color: colors.tx,
            ),
          ),
        ),
      ],
    );
  }
}
