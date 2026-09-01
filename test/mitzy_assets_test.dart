import 'package:flutter_test/flutter_test.dart';
import 'package:mita/core/mitzy_assets.dart';

void main() {
  group('MitzyAssets.isWinterArcSeason', () {
    test('returns true for December', () {
      expect(MitzyAssets.isWinterArcSeason(DateTime(2025, 12, 15)), isTrue);
    });

    test('returns true for January', () {
      expect(MitzyAssets.isWinterArcSeason(DateTime(2026, 1, 1)), isTrue);
    });

    test('returns true for February (incl. leap end)', () {
      expect(MitzyAssets.isWinterArcSeason(DateTime(2026, 2, 28)), isTrue);
    });

    test('returns false for March', () {
      expect(MitzyAssets.isWinterArcSeason(DateTime(2026, 3, 1)), isFalse);
    });

    test('returns false for June / summer', () {
      expect(MitzyAssets.isWinterArcSeason(DateTime(2026, 6, 15)), isFalse);
    });

    test('returns false for November (month before winter)', () {
      expect(MitzyAssets.isWinterArcSeason(DateTime(2026, 11, 30)), isFalse);
    });
  });

  group('MitzyAssets constants', () {
    test('exposes the standard banner path', () {
      expect(MitzyAssets.standard, 'assets/images/mitzy_rate.png');
    });

    test('winter default is the cozy variant', () {
      expect(MitzyAssets.winterArc,
          'assets/images/mitzy_winter_arc_cozy.png');
    });

    test('lists the three delivered variants in order', () {
      expect(MitzyAssets.winterVariantKeys, ['cozy', 'frosty', 'scarf']);
    });

    test('variantPath resolves each delivered variant', () {
      expect(MitzyAssets.variantPath('cozy'),
          'assets/images/mitzy_winter_arc_cozy.png');
      expect(MitzyAssets.variantPath('frosty'),
          'assets/images/mitzy_winter_arc_frosty.png');
      expect(MitzyAssets.variantPath('scarf'),
          'assets/images/mitzy_winter_arc_scarf.png');
    });

    test('unknown variant falls back to the winter default', () {
      expect(MitzyAssets.variantPath('nope'), MitzyAssets.winterArc);
    });
  });
}
