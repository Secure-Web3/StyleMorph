import 'package:country_state_city/country_state_city.dart' as csc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/iso_location_data.dart';

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
    String? countryCode,
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
          countryCode: countryCode,
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
  List<IsoCountry> _allCountries = [];
  List<IsoCountry> _filtered = [];

  @override
  void initState() {
    super.initState();
    _allCountries = IsoLocationData.countries;
    _filtered = _allCountries;
    _searchCtrl.addListener(_onSearchChanged);
    _loadWorldwideCountries();
  }

  Future<void> _loadWorldwideCountries() async {
    try {
      final worldwide = await csc.getAllCountries();
      if (!mounted || worldwide.isEmpty) return;

      final Map<String, IsoCountry> map = {
        for (final c in IsoLocationData.countries) c.code.toUpperCase(): c,
      };

      for (final w in worldwide) {
        final code = w.isoCode.toUpperCase();
        if (!map.containsKey(code)) {
          final cleanPhone = w.phoneCode.trim();
          final formattedPhone = cleanPhone.startsWith('+')
              ? cleanPhone
              : '+$cleanPhone';

          map[code] = IsoCountry(
            code: w.isoCode,
            flag: w.flag,
            dialCode: formattedPhone,
            subscriberLength: 10,
            nameEn: w.name,
            nameFa: w.name,
            nameAr: w.name,
            nameTr: w.name,
          );
        }
      }

      final list = map.values.toList()
        ..sort((a, b) => a.nameEn.compareTo(b.nameEn));

      if (mounted) {
        setState(() {
          _allCountries = list;
          _onSearchChanged();
        });
      }
    } catch (_) {
      // Fallback cleanly to built-in IsoLocationData
    }
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
        _filtered = _allCountries;
      } else {
        _filtered = _allCountries.where((c) {
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

  Future<void> _safePop([dynamic result]) async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    Navigator.of(context).pop(result);
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
                    onPressed: () => _safePop(),
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
                      c.nameEn,
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
                      c.code,
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
                    onTap: () => _safePop(c),
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
  List<IsoProvince> _allProvinces = [];
  List<IsoProvince> _filtered = [];

  @override
  void initState() {
    super.initState();
    _allProvinces = widget.country.provinces;
    _filtered = _allProvinces;
    _searchCtrl.addListener(_onSearchChanged);
    _loadWorldwideProvinces();
  }

  Future<void> _loadWorldwideProvinces() async {
    try {
      final worldwideStates = await csc.getStatesOfCountry(widget.country.code);
      if (!mounted || worldwideStates.isEmpty) return;

      final Map<String, IsoProvince> map = {
        for (final p in widget.country.provinces) p.code.toUpperCase(): p,
      };

      for (final s in worldwideStates) {
        final code = s.isoCode.toUpperCase();
        if (!map.containsKey(code)) {
          map[code] = IsoProvince(
            code: s.isoCode.isNotEmpty ? s.isoCode : s.name,
            nameEn: s.name,
            nameFa: s.name,
            nameAr: s.name,
            nameTr: s.name,
          );
        }
      }

      final list = map.values.toList()
        ..sort((a, b) => a.nameEn.compareTo(b.nameEn));

      if (mounted) {
        setState(() {
          _allProvinces = list;
          _onSearchChanged();
        });
      }
    } catch (_) {
      // Fallback cleanly
    }
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
        _filtered = _allProvinces;
      } else {
        _filtered = _allProvinces.where((p) {
          return p.nameEn.toLowerCase().contains(query) ||
              p.nameFa.toLowerCase().contains(query) ||
              p.nameAr.toLowerCase().contains(query) ||
              p.nameTr.toLowerCase().contains(query) ||
              p.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _safePop([dynamic result]) async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    Navigator.of(context).pop(result);
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
                    onPressed: () => _safePop(),
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
                      p.nameEn,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? colors.pr : colors.tx,
                      ),
                    ),
                    subtitle: p.code.isNotEmpty
                        ? Text(
                            p.code,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              color: colors.mu,
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? FaIcon(
                            FontAwesomeIcons.check,
                            size: 14,
                            color: colors.pr,
                          )
                        : null,
                    onTap: () => _safePop(p),
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
  final String? countryCode;
  final String? currentCity;
  final String title;
  final String localeCode;

  const _SearchableCityView({
    required this.province,
    this.countryCode,
    this.currentCity,
    required this.title,
    required this.localeCode,
  });

  @override
  State<_SearchableCityView> createState() => _SearchableCityViewState();
}

class _SearchableCityViewState extends State<_SearchableCityView> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<IsoCity> _allCities = [];
  List<IsoCity> _filtered = [];

  @override
  void initState() {
    super.initState();
    _allCities = widget.province.cities;
    _filtered = _allCities;
    _searchCtrl.addListener(_onSearchChanged);
    _loadWorldwideCities();
  }

  Future<void> _loadWorldwideCities() async {
    try {
      List<csc.City> cities = [];
      if (widget.countryCode != null && widget.countryCode!.isNotEmpty) {
        cities = await csc.getStateCities(
          widget.countryCode!,
          widget.province.code,
        );
        if (cities.isEmpty) {
          cities = await csc.getCountryCities(widget.countryCode!);
        }
      }

      if (!mounted || cities.isEmpty) return;

      final Set<String> existing = {
        for (final c in widget.province.cities) c.nameEn.toLowerCase(),
      };

      final List<IsoCity> additions = [];
      for (final c in cities) {
        if (!existing.contains(c.name.toLowerCase())) {
          additions.add(
            IsoCity(
              nameEn: c.name,
              nameFa: c.name,
              nameAr: c.name,
              nameTr: c.name,
            ),
          );
          existing.add(c.name.toLowerCase());
        }
      }

      final merged = [...widget.province.cities, ...additions];
      if (mounted) {
        setState(() {
          _allCities = merged;
          _onSearchChanged();
        });
      }
    } catch (_) {
      // Fallback cleanly
    }
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
        _filtered = _allCities;
      } else {
        _filtered = _allCities.where((c) {
          return c.nameEn.toLowerCase().contains(query) ||
              c.nameFa.toLowerCase().contains(query) ||
              c.nameAr.toLowerCase().contains(query) ||
              c.nameTr.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _safePop([dynamic result]) async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    Navigator.of(context).pop(result);
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
                    onPressed: () => _safePop(),
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
                onTap: () => _safePop(query),
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
                  final latinName = c.nameEn;
                  final isSelected =
                      widget.currentCity != null &&
                      (widget.currentCity?.toLowerCase() ==
                              c.nameEn.toLowerCase() ||
                          widget.currentCity == c.nameFa ||
                          widget.currentCity == c.nameAr ||
                          widget.currentCity == c.nameTr);

                  return ListTile(
                    title: Text(
                      latinName,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? colors.pr : colors.tx,
                      ),
                    ),
                    trailing: isSelected
                        ? FaIcon(
                            FontAwesomeIcons.check,
                            size: 14,
                            color: colors.pr,
                          )
                        : null,
                    onTap: () => _safePop(latinName),
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
