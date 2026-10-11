import '../models/mushaf_ayah_ref.dart';
import '../models/mushaf_riwayah.dart';

/// Persists last-read position per riwayah.
abstract class MushafProgressStore {
  Future<MushafProgress?> load(MushafRiwayah riwayah);
  Future<void> save(MushafProgress progress);
}

class MushafProgress {
  const MushafProgress({
    required this.riwayah,
    required this.page,
    this.surahId,
  });

  final MushafRiwayah riwayah;
  final int page;
  final int? surahId;
}

/// Semantic ayah bookmark colors (not general UI tokens).
enum MushafBookmarkColor {
  red,
  yellow,
  green,
  blue;

  static const MushafBookmarkColor defaultColor = MushafBookmarkColor.red;

  static MushafBookmarkColor? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final value in MushafBookmarkColor.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Bookmark of a page or ayah.
abstract class MushafBookmarkStore {
  Future<List<MushafBookmark>> list({MushafRiwayah? riwayah});
  Future<void> add(MushafBookmark bookmark);
  Future<void> remove(MushafBookmark bookmark);

  /// Removes all bookmarks, or only those for [riwayah] when provided.
  Future<void> clear({MushafRiwayah? riwayah});
}

class MushafBookmark {
  const MushafBookmark({
    required this.riwayah,
    required this.page,
    this.surahId,
    this.ayahNumber,
    this.createdAt,
    this.color = MushafBookmarkColor.defaultColor,
  });

  final MushafRiwayah riwayah;
  final int page;
  final int? surahId;
  final int? ayahNumber;
  final DateTime? createdAt;
  final MushafBookmarkColor color;

  MushafAyahRef? get ayahRef {
    final surah = surahId;
    final ayah = ayahNumber;
    if (surah == null || ayah == null || surah < 1 || ayah < 1) {
      return null;
    }
    return MushafAyahRef(surahId: surah, ayahNumber: ayah);
  }

  Map<String, dynamic> toJson() {
    return {
      'riwayah': riwayah.name,
      'page': page,
      'surahId': surahId,
      'ayahNumber': ayahNumber,
      'createdAt': createdAt?.toIso8601String(),
      'color': color.name,
    };
  }

  factory MushafBookmark.fromJson(Map<String, dynamic> json) {
    return MushafBookmark(
      riwayah: MushafRiwayah.values.firstWhere(
        (value) => value.name == json['riwayah'],
        orElse: () => MushafRiwayah.hafs,
      ),
      page: json['page'] as int? ?? 1,
      surahId: json['surahId'] as int?,
      ayahNumber: json['ayahNumber'] as int?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      color: MushafBookmarkColor.tryParse(json['color'] as String?) ??
          MushafBookmarkColor.defaultColor,
    );
  }
}

/// In-memory progress (useful for demos / tests).
class MemoryMushafProgressStore implements MushafProgressStore {
  final Map<MushafRiwayah, MushafProgress> _data = {};

  @override
  Future<MushafProgress?> load(MushafRiwayah riwayah) async => _data[riwayah];

  @override
  Future<void> save(MushafProgress progress) async {
    _data[progress.riwayah] = progress;
  }
}

/// In-memory bookmarks.
class MemoryMushafBookmarkStore implements MushafBookmarkStore {
  final List<MushafBookmark> _items = [];

  @override
  Future<List<MushafBookmark>> list({MushafRiwayah? riwayah}) async {
    if (riwayah == null) return List.unmodifiable(_items);
    return _items.where((b) => b.riwayah == riwayah).toList(growable: false);
  }

  @override
  Future<void> add(MushafBookmark bookmark) async {
    _items.removeWhere((b) => _sameAyah(b, bookmark));
    _items.add(bookmark);
  }

  @override
  Future<void> remove(MushafBookmark bookmark) async {
    _items.removeWhere((b) => _sameAyah(b, bookmark));
  }

  @override
  Future<void> clear({MushafRiwayah? riwayah}) async {
    if (riwayah == null) {
      _items.clear();
      return;
    }
    _items.removeWhere((b) => b.riwayah == riwayah);
  }

  bool _sameAyah(MushafBookmark a, MushafBookmark b) {
    return a.riwayah == b.riwayah &&
        a.surahId == b.surahId &&
        a.ayahNumber == b.ayahNumber;
  }
}
