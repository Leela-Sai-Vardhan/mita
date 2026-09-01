import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mita/core/mitzy_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MitzyAssets asset resolution', () {
    setUp(() {
      // Deterministic: disable the debug out-of-season preview so seasonal
      // assertions like "June returns standard" hold.
      MitzyAssets.forceWinterPreview = false;
    });

    test('winter assets are bundled and resolve during winter', () async {
      final all = <String>{
        MitzyAssets.winterArc,
        MitzyAssets.variantPath('frosty'),
        MitzyAssets.variantPath('scarf'),
      };
      for (final path in all) {
        final bundle = await rootBundle.load(path);
        expect(bundle.lengthInBytes, greaterThan(0),
            reason: '$path should be bundled');
      }
    });

    test('standard banner is bundled', () async {
      final bundle = await rootBundle.load(MitzyAssets.standard);
      expect(bundle.lengthInBytes, greaterThan(0));
    });

    test('resolve returns winter arc during winter season', () async {
      final resolved = await MitzyAssets.resolve(DateTime(2026, 1, 10));
      expect(resolved, MitzyAssets.winterArc);
    });

    test('resolve returns standard banner outside winter season', () async {
      final resolved = await MitzyAssets.resolve(DateTime(2026, 6, 10));
      expect(resolved, MitzyAssets.standard);
    });
  });
}
