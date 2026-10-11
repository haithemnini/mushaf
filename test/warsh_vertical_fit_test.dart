import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/mushaf.dart';

void main() {
  group('WarshMushafLayout.verticalFit', () {
    const lineWidth = 335.0;
    const fontSize = 18.5;
    const maxHeight = 680.0;

    test('plain page keeps full chrome scale and leading', () {
      final fit = WarshMushafLayout.verticalFit(
        maxHeight: maxHeight,
        lineWidth: lineWidth,
        fontSize: fontSize,
        ayahLines: 16,
        surahHeaders: 0,
        basmalas: 0,
      );
      expect(fit.chromeScale, 1);
      expect(fit.lineHeight, WarshMushafLayout.lineHeight);
    });

    test('chrome pages never shrink headers', () {
      final fit = WarshMushafLayout.verticalFit(
        maxHeight: maxHeight,
        lineWidth: lineWidth,
        fontSize: fontSize,
        ayahLines: 13,
        surahHeaders: 2,
        basmalas: 2,
      );
      expect(fit.chromeScale, 1);
    });

    test('visual budget constants', () {
      expect(WarshMushafLayout.visualLinesPerPage, 16);
      expect(WarshMushafLayout.ayahLinesPerPage, 16);
    });
  });
}
