import 'package:flutter/foundation.dart' show kDebugMode, kProfileMode;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mita/core/mitzy_assets.dart';
import 'package:mita/widgets/mitzy_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the resolved asset and floats during winter',
      (tester) async {
    MitzyAssets.forceWinterPreview = true;
    addTearDown(() => MitzyAssets.forceWinterPreview = true);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: MitzyAvatar(assetPath: MitzyAssets.standard)),
      ),
    );
    // Advance a quarter of the 3s loop so the float is at its full amplitude.
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.byType(Image), findsOneWidget);
    // MaterialApp inserts its own FractionalTranslations internally, so scope
    // the finder to the avatar. Its phase is 0.25 * 2*pi -> sin == 1 -> dy = +3%.
    final floatFinder = find.descendant(
      of: find.byType(MitzyAvatar),
      matching: find.byType(FractionalTranslation),
    );
    expect(floatFinder, findsOneWidget);
    final float = tester.widget<FractionalTranslation>(floatFinder);
    expect(float.translation.dy, closeTo(0.03, 0.001));
  });

  testWidgets('resolves seasonally when no asset path is given',
      (tester) async {
    MitzyAssets.forceWinterPreview = true;
    addTearDown(() => MitzyAssets.forceWinterPreview = true);

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: MitzyAvatar(width: 100, height: 100)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(Image), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MitzyAvatar),
        matching: find.byType(FractionalTranslation),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders statically out of season', (tester) async {
    MitzyAssets.forceWinterPreview = false;
    addTearDown(() => MitzyAssets.forceWinterPreview = kDebugMode || kProfileMode);

    // September is outside the Dec-Feb window, so no float is applied.
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: MitzyAvatar(assetPath: MitzyAssets.standard)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.byType(Image), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MitzyAvatar),
        matching: find.byType(FractionalTranslation),
      ),
      findsNothing,
    );
  });
}