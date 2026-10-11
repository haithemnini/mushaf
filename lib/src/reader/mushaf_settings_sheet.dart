import 'package:flutter/material.dart';

import 'mushaf_reading_settings.dart';

/// Reading options: scroll, book frame, landscape spread, clock, tajweed, page picker.
class MushafSettingsSheet {
  const MushafSettingsSheet._();

  static Future<void> show({
    required BuildContext context,
    required MushafReadingSettings settings,
    required bool showTajweed,
    required ValueChanged<MushafReadingSettings> onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _SheetHost(
            settings: settings,
            showTajweed: showTajweed,
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

class _SheetHost extends StatefulWidget {
  const _SheetHost({
    required this.settings,
    required this.showTajweed,
    required this.onChanged,
  });

  final MushafReadingSettings settings;
  final bool showTajweed;
  final ValueChanged<MushafReadingSettings> onChanged;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  late MushafReadingSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _update(MushafReadingSettings next) {
    setState(() => _settings = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final settings = _settings;

    return Material(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: colors.outline, borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'إعدادات القراءة',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'تنطبق على حفص وورش.',
                style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 20),
              _Section(title: 'التمرير', icon: Icons.swap_horiz),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _Choice(
                    icon: Icons.swap_horiz,
                    title: 'أفقي',
                    selected: settings.scrollDirection == MushafScrollDirection.horizontal,
                    onTap: () => _update(settings.copyWith(scrollDirection: MushafScrollDirection.horizontal)),
                  ),
                  _Choice(
                    icon: Icons.swap_vert,
                    title: 'عمودي',
                    selected: settings.scrollDirection == MushafScrollDirection.vertical,
                    onTap: () => _update(settings.copyWith(scrollDirection: MushafScrollDirection.vertical)),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(title: 'التصميم', icon: Icons.menu_book_outlined),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _Choice(
                    icon: Icons.fullscreen,
                    title: 'ملء الشاشة',
                    selected: settings.pageDesign == MushafPageDesign.fullscreen,
                    onTap: () => _update(settings.copyWith(pageDesign: MushafPageDesign.fullscreen)),
                  ),
                  _Choice(
                    icon: Icons.menu_book_outlined,
                    title: 'الكتاب',
                    selected: settings.pageDesign == MushafPageDesign.book,
                    onTap: () => _update(settings.copyWith(pageDesign: MushafPageDesign.book)),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(title: 'الوضع الأفقي', icon: Icons.splitscreen),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _Choice(
                    icon: Icons.crop_portrait,
                    title: 'صفحة واحدة',
                    selected: settings.landscapeLayout == MushafLandscapeLayout.single,
                    onTap: () => _update(settings.copyWith(landscapeLayout: MushafLandscapeLayout.single)),
                  ),
                  _Choice(
                    icon: Icons.menu_book,
                    title: 'صفحتان',
                    selected: settings.landscapeLayout == MushafLandscapeLayout.doublePage,
                    onTap: () => _update(settings.copyWith(landscapeLayout: MushafLandscapeLayout.doublePage)),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(title: 'المظهر', icon: Icons.tune),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _SwitchTile(
                    icon: Icons.schedule,
                    title: 'الساعة',
                    subtitle: 'تظهر في ملء الشاشة عند إخفاء الشريط',
                    value: settings.showClock,
                    onChanged: (value) => _update(settings.copyWith(showClock: value)),
                  ),
                  if (widget.showTajweed)
                    _SwitchTile(
                      icon: Icons.format_color_text,
                      title: 'التجويد',
                      value: settings.tajweedEnabled,
                      onChanged: (value) => _update(settings.copyWith(tajweedEnabled: value)),
                    ),
                  _SwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'خلفية سوداء',
                    subtitle: 'في الوضع الليلي',
                    value: settings.blackBackground,
                    onChanged: (value) => _update(settings.copyWith(blackBackground: value)),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(title: 'التنقل بين الصفحات', icon: Icons.view_week_outlined),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _Choice(
                    icon: Icons.view_week_outlined,
                    title: 'شريط الصفحات',
                    selected: settings.pageNavMode == MushafPageNavMode.strip,
                    onTap: () => _update(settings.copyWith(pageNavMode: MushafPageNavMode.strip)),
                  ),
                  _Choice(
                    icon: Icons.linear_scale,
                    title: 'المنزلق',
                    selected: settings.pageNavMode == MushafPageNavMode.scrub,
                    onTap: () => _update(settings.copyWith(pageNavMode: MushafPageNavMode.scrub)),
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: colors.onSurface),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: selected ? colors.primary : colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: colors.onSurface,
                ),
              ),
            ),
            if (selected) Icon(Icons.check, size: 20, color: colors.primary),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsetsDirectional.only(start: 16, end: 8, top: 4, bottom: 4),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyMedium?.copyWith(color: colors.onSurface)),
                if (subtitle != null)
                  Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
