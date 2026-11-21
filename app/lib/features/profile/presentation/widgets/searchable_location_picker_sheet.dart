import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/iso_location_data.dart';

class SearchableLocationPickerSheet {
  /// Opens a searchable country picker bottom sheet
  static Future<IsoCountry?> showCountryPicker(
    BuildContext context, {
    String? selectedCode,
    String? title,
  }) {
    final colors = context.colors;
    final strings = context.strings;
    final locale = Localizations.localeOf(context).languageCode;

    return showModalBottomSheet<IsoCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.sf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _SearchableCountryView(
          selectedCode: selectedCode,
          title: title ?? strings.idSelectCountry,
          localeCode: locale,
        );
      },
    );
  }

  /// Opens a searchable dial code / flag picker bottom sheet
  static Future<IsoCountry?> showDialCodePicker(
    BuildContext context, {
    String? selectedDialCode,
  }) {
    final colors = context.colors;
    final strings = context.strings;
    final locale = Localizations.localeOf(context).languageCode;

    return showModalBottomSheet<IsoCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.sf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _SearchableCountryView(
          selectedDialCode: selectedDialCode,
          title: strings.idSelectDialCode,
          localeCode: locale,
          showDialCodeHighlight: true,
        );
      },
    );
  }

  /// Opens a searchable province / state picker bottom sheet for the selected country
  static Future<IsoProvince?> showProvincePicker(
    BuildContext context, {
    required IsoCountry country,
    String? selectedCode,
  }) {
    final colors = context.colors;
    final strings = context.strings;
    final locale = Localizations.localeOf(context).languageCode;

    return showModalBottomSheet<IsoProvince>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.sf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _SearchableProvinceView(
          country: country,
          selectedCode: selectedCode,
          title: strings.idSelectProvince,
          localeCode: locale,
        );
      },
    );
  }

  /// Opens a searchable city picker bottom sheet for the selected province
  static Future<String?> showCityPicker(
    BuildContext context, {
    required IsoProvince province,
    String? currentCity,
  }) {
    final colors = context.colors;
    final strings = context.strings;
    final locale = Localizations.localeOf(context).languageCode;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.sf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _SearchableCityView(
          province: province,
          currentCity: currentCity,
          title: strings.idSelectCity,
          localeCode: locale,
        );
      },
    );
  }
}

class _SearchableCountryView extends StatefulWidget {
  final String? selectedCode;
  final String? selectedDialCode;
  final String title;
  final String localeCode;
  final bool showDialCodeHighlight;

  const _SearchableCountryView({
    this.selectedCode,
    this.selectedDialCode,
    required this.title,
    required this.localeCode,
    this.showDialCodeHighlight = false,
  });

  @override
  State<_SearchableCountryView> createState() => _SearchableCountryViewState();
}

class _SearchableCountryViewState extends State<_SearchableCountryView> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<IsoCountry> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = IsoLocationData.countries;
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = IsoLocationData.countries;
      } else {
        _filtered = IsoLocationData.countries.where((c) {
          return c.nameEn.toLowerCase().contains(query) ||
              c.nameFa.toLowerCase().contains(query) ||
              c.nameAr.toLowerCase().contains(query) ||
              c.nameTr.toLowerCase().contains(query) ||
              c.code.toLowerCase().contains(query) ||
              c.dialCode.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Handle Bar
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.bd,
                borderRadius: AppRadius.rFull,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Sheet Title & Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.tx,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: AppSearchField(
                controller: _searchCtrl,
                hintText: strings.idSearchPlaceholder,
              ),
            ),
            const Divider(height: 1),

            // Country List
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _filtered.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (ctx, index) {
                  final c = _filtered[index];
                  final isSelected = widget.selectedCode != null
                      ? (c.code.toUpperCase() ==
                            widget.selectedCode?.toUpperCase())
                      : (c.dialCode == widget.selectedDialCode);

                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(
                      c.localizedName(widget.localeCode),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? colors.pr : colors.tx,
                      ),
                    ),
                    subtitle: Text(
                      '${c.nameEn} (${c.code})',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        color: colors.mu,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.dialCode,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.mu,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: AppSpacing.xs),
                          FaIcon(
                            FontAwesomeIcons.check,
                            size: 14,
                            color: colors.pr,
                          ),
                        ],
                      ],
                    ),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchableProvinceView extends StatefulWidget {
  final IsoCountry country;
  final String? selectedCode;
  final String title;
  final String localeCode;

  const _SearchableProvinceView({
    required this.country,
    this.selectedCode,
    required this.title,
    required this.localeCode,
  });

  @override
  State<_SearchableProvinceView> createState() =>
      _SearchableProvinceViewState();
}

class _SearchableProvinceViewState extends State<_SearchableProvinceView> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<IsoProvince> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.country.provinces;
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.country.provinces;
      } else {
        _filtered = widget.country.provinces.where((p) {
          return p.nameEn.toLowerCase().contains(query) ||
              p.nameFa.toLowerCase().contains(query) ||
              p.nameAr.toLowerCase().contains(query) ||
              p.nameTr.toLowerCase().contains(query) ||
              p.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.bd,
                borderRadius: AppRadius.rFull,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.tx,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: AppSearchField(
                controller: _searchCtrl,
                hintText: strings.idSearchPlaceholder,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _filtered.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (ctx, index) {
                  final p = _filtered[index];
                  final isSelected =
                      widget.selectedCode != null &&
                      (p.code.toLowerCase() ==
                              widget.selectedCode?.toLowerCase() ||
                          p.nameEn.toLowerCase() ==
                              widget.selectedCode?.toLowerCase() ||
                          p.nameFa == widget.selectedCode);

                  return ListTile(
                    title: Text(
                      p.localizedName(widget.localeCode),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? colors.pr : colors.tx,
                      ),
                    ),
                    subtitle: Text(
                      p.nameEn,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        color: colors.mu,
                      ),
                    ),
                    trailing: isSelected
                        ? FaIcon(
                            FontAwesomeIcons.check,
                            size: 14,
                            color: colors.pr,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(p),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchableCityView extends StatefulWidget {
  final IsoProvince province;
  final String? currentCity;
  final String title;
  final String localeCode;

  const _SearchableCityView({
    required this.province,
    this.currentCity,
    required this.title,
    required this.localeCode,
  });

  @override
  State<_SearchableCityView> createState() => _SearchableCityViewState();
}

class _SearchableCityViewState extends State<_SearchableCityView> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<IsoCity> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.province.cities;
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.province.cities;
      } else {
        _filtered = widget.province.cities.where((c) {
          return c.nameEn.toLowerCase().contains(query) ||
              c.nameFa.toLowerCase().contains(query) ||
              c.nameAr.toLowerCase().contains(query) ||
              c.nameTr.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final query = _searchCtrl.text.trim();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.bd,
                borderRadius: AppRadius.rFull,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.tx,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: AppSearchField(
                controller: _searchCtrl,
                hintText: strings.idSearchPlaceholder,
              ),
            ),
            // Custom typed city option if query is not found
            if (query.isNotEmpty) ...[
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.plus,
                  size: 14,
                  color: colors.pr,
                ),
                title: Text(
                  '${strings.idUseCustomCity}: "$query"',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.pr,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(query),
              ),
              const Divider(height: 1),
            ],
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _filtered.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (ctx, index) {
                  final c = _filtered[index];
                  final localizedName = c.localizedName(widget.localeCode);
                  final isSelected =
                      widget.currentCity != null &&
                      (widget.currentCity == localizedName ||
                          widget.currentCity?.toLowerCase() ==
                              c.nameEn.toLowerCase());

                  return ListTile(
                    title: Text(
                      localizedName,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? colors.pr : colors.tx,
                      ),
                    ),
                    subtitle: Text(
                      c.nameEn,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        color: colors.mu,
                      ),
                    ),
                    trailing: isSelected
                        ? FaIcon(
                            FontAwesomeIcons.check,
                            size: 14,
                            color: colors.pr,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(localizedName),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
