/// Identifies one ayah in a surah (1-based indices).
class MushafAyahRef {
  const MushafAyahRef({
    required this.surahId,
    required this.ayahNumber,
  });

  final int surahId;
  final int ayahNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MushafAyahRef &&
          surahId == other.surahId &&
          ayahNumber == other.ayahNumber;

  @override
  int get hashCode => Object.hash(surahId, ayahNumber);

  @override
  String toString() => 'MushafAyahRef($surahId:$ayahNumber)';
}
