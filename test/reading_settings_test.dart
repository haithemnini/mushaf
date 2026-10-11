import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf.dart';

void main() {
  test('reading settings copyWith keeps unspecified fields', () {
    const settings = MushafReadingSettings();
    final next = settings.copyWith(
      pageDesign: MushafPageDesign.book,
      tajweedEnabled: true,
    );
    expect(next.pageDesign, MushafPageDesign.book);
    expect(next.tajweedEnabled, isTrue);
    expect(next.scrollDirection, MushafScrollDirection.horizontal);
    expect(next.pageNavMode, MushafPageNavMode.strip);
    expect(next.showClock, isFalse);
  });

  test('Hafs juz follows the Madinah 604 page starts', () {
    expect(hafsJuzForPage(1), 1);
    expect(hafsJuzForPage(21), 1);
    expect(hafsJuzForPage(22), 2);
    expect(hafsJuzForPage(582), 30);
    expect(hafsJuzForPage(604), 30);
  });

  test('spread window is wide and landscape', () {
    expect(mushafSpreadWindow(const Size(900, 500)), isTrue);
    expect(mushafSpreadWindow(const Size(390, 844)), isFalse);
    expect(mushafSpreadWindow(const Size(900, 1200)), isFalse);
  });
}
