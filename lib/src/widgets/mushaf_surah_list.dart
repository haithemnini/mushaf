import 'package:flutter/material.dart';

import '../models/mushaf_surah.dart';
import '../models/mushaf_surah_search_entry.dart';
import '../mushaf_bootstrap.dart';
import '../search/text_search_normalizer.dart';
import '../style/mushaf_style.dart';

typedef MushafSurahTap = void Function(MushafSurah surah);

/// Surah list with optional name search (no bundled translations).
class MushafSurahList extends StatefulWidget {
  const MushafSurahList({
    super.key,
    required this.onSurahTap,
    this.style,
    this.searchHint = 'Search surah…',
    this.emptyLabel = 'No surahs found',
  });

  final MushafSurahTap onSurahTap;
  final MushafStyle? style;
  final String searchHint;
  final String emptyLabel;

  @override
  State<MushafSurahList> createState() => _MushafSurahListState();
}

class _MushafSurahListState extends State<MushafSurahList> {
  List<MushafSurahSearchEntry> _all = const [];
  List<MushafSurahSearchEntry> _filtered = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await Mushaf.repository.getSurahSearchEntries();
    if (!mounted) return;
    result.when(
      success: (entries) {
        setState(() {
          _all = entries;
          _filtered = entries;
          _loading = false;
        });
      },
      failure: (message) {
        setState(() {
          _error = message;
          _loading = false;
        });
      },
    );
  }

  void _onQuery(String query) {
    final q = query.trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = _all;
        return;
      }
      final id = int.tryParse(q);
      final needle = TextSearchNormalizer.normalize(q);
      _filtered = _all.where((e) {
        if (id != null && e.surah.id == id) return true;
        return e.normalizedNameAr.contains(needle) ||
            e.normalizedNameEn.contains(needle);
      }).toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style ??
        theme.extension<MushafStyle>() ??
        MushafStyle.fromTheme(context);

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: style.accent));
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: _onQuery,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Text(widget.emptyLabel))
              : ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: style.accent.withValues(alpha: 0.15),
                  ),
                  itemBuilder: (context, index) {
                    final entry = _filtered[index];
                    final surah = entry.surah;
                    final title =
                        style.useArabicNames ? surah.nameAr : surah.nameEn;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: style.accentContainer.withValues(
                          alpha: 0.55,
                        ),
                        child: Text(
                          '${surah.id}',
                          style: TextStyle(
                            color: style.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: style.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        style.useArabicNames
                            ? '${surah.ayahs} آية · ${surah.revelationPlaceAr}'
                            : '${surah.ayahs} ayahs · ${surah.revelationPlaceEn}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: style.muted,
                        ),
                      ),
                      onTap: () => widget.onSurahTap(surah),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
