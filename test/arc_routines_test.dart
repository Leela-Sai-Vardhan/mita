import 'package:flutter_test/flutter_test.dart';
import 'package:mita/core/arc_routines.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArcRoutines.currentBucket', () {
    test('morning / midday / evening / night buckets', () {
      expect(ArcRoutines.currentBucket(DateTime(2026, 9, 4, 7, 30)), 'morning');
      expect(ArcRoutines.currentBucket(DateTime(2026, 9, 4, 13, 0)), 'midday');
      expect(ArcRoutines.currentBucket(DateTime(2026, 9, 4, 19, 0)), 'evening');
      expect(ArcRoutines.currentBucket(DateTime(2026, 9, 4, 2, 0)), 'any');
    });
  });

  group('ArcRoutines.catalog', () {
    test('default catalog is the curated trend list', () {
      final catalog = ArcRoutines.catalog();
      expect(catalog, isNotEmpty);
      // The habits that dominate the Winter Arc trend.
      expect(catalog.any((r) => r.title.contains('Train')), isTrue);
      expect(catalog.any((r) => r.title.contains('10k steps')), isTrue);
      expect(catalog.any((r) => r.title.contains('Read 10 pages')), isTrue);
      expect(catalog.any((r) => r.title.contains('protein')), isTrue);
    });

    test('every routine is binary-tagged with goal and bucket', () {
      for (final r in ArcRoutines.catalog()) {
        expect(r.title.isNotEmpty, isTrue, reason: 'empty title');
        expect(r.goal.isNotEmpty, isTrue, reason: 'no goal on ${r.title}');
        expect(
          ['morning', 'midday', 'evening', 'any'].contains(r.bucket),
          isTrue,
          reason: 'bad bucket ${r.bucket} on ${r.title}',
        );
      }
    });
  });

  group('ArcRoutines contract persistence (per season)', () {
    test('save and load round-trip', () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime(2026, 11, 10);
      final catalog = ArcRoutines.catalog();
      final pick = [
        catalog.first,
        catalog[5],
        catalog[10],
      ];
      await ArcRoutines.saveContract(pick, now);

      final loaded = await ArcRoutines.loadContract(now);
      expect(loaded, isNotNull);
      expect(loaded!.length, 3);
      expect(loaded.map((r) => r.title), pick.map((r) => r.title));
    });

    test('contract is capped at 3 non-negotiables', () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime(2026, 11, 10);
      final catalog = ArcRoutines.catalog().take(6).toList();
      await ArcRoutines.saveContract(catalog, now);

      final loaded = await ArcRoutines.loadContract(now);
      expect(loaded!.length, ArcRoutines.maxContractSize);
    });

    test('September and January share the same season contract', () async {
      SharedPreferences.setMockInitialValues({});
      final catalog = ArcRoutines.catalog();
      await ArcRoutines.saveContract([catalog.first], DateTime(2026, 9, 15));

      // January 2027 belongs to the 2026-2027 arc.
      final loaded = await ArcRoutines.loadContract(DateTime(2027, 1, 10));
      expect(loaded, isNotNull);
      expect(loaded!.first.title, catalog.first.title);
    });

    test('new season (next September) starts empty', () async {
      SharedPreferences.setMockInitialValues({});
      final catalog = ArcRoutines.catalog();
      await ArcRoutines.saveContract([catalog.first], DateTime(2026, 9, 15));

      final next = await ArcRoutines.loadContract(DateTime(2027, 9, 15));
      expect(next, isNull);
    });

    test('hasConfirmedContract detects season state', () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime(2026, 10, 1);
      expect(await ArcRoutines.hasConfirmedContract(now), isFalse);

      await ArcRoutines.saveContract(
          ArcRoutines.catalog().take(1).toList(), now);
      expect(await ArcRoutines.hasConfirmedContract(now), isTrue);
    });
  });

  group('ArcRoutines.contractToday (adherence)', () {
    test('counts contract items satisfied by completed tasks', () {
      final catalog = ArcRoutines.catalog();
      final train = catalog.firstWhere((r) => r.title.contains('Train'));
      final read = catalog.firstWhere((r) => r.title == 'Read 10 pages');

      final today = ArcRoutines.contractToday(
        [train, read],
        ['train (gym or home)', 'Something unrelated'],
      );
      expect(today.totalCount, 2);
      expect(today.doneCount, 1);
      expect(today.allDone, isFalse);
      expect(today.isDone(train), isTrue);
      expect(today.isDone(read), isFalse);
    });

    test('title matching is case/whitespace insensitive', () {
      final catalog = ArcRoutines.catalog();
      final read = catalog.firstWhere((r) => r.title == 'Read 10 pages');
      final today = ArcRoutines.contractToday(
        [read],
        ['  read  10   PAGES '],
      );
      expect(today.doneCount, 1);
    });

    test('empty contract yields empty today', () {
      final today = ArcRoutines.contractToday(null, ['Whatever']);
      expect(today.totalCount, 0);
      expect(today.allDone, isFalse);
    });
  });

  group('ArcRoutines.suggestions (offline recommender)', () {
    test('excludes contract items and today\'s tasks', () {
      final catalog = ArcRoutines.catalog();
      final contract = [catalog.first];
      final todayTitles = [catalog[3].title];

      final sugg = ArcRoutines.suggestions(
        contract: contract,
        todayTitles: todayTitles,
        goalKeys: const [],
        now: DateTime(2026, 9, 4, 8, 0),
        count: 10,
      );
      expect(sugg, isNotEmpty);
      for (final s in sugg) {
        expect(s.title, isNot(contract.first.title));
        expect(s.title, isNot(todayTitles.first));
      }
    });

    test('favors current time bucket in the morning', () {
      final sugg = ArcRoutines.suggestions(
        contract: null,
        todayTitles: const [],
        goalKeys: const [],
        now: DateTime(2026, 9, 4, 7, 0), // morning
        count: 5,
      );
      // Top pick should be a morning-bucket routine.
      expect(sugg.first.bucket, 'morning');
    });

    test('favors the evening bucket at night', () {
      final sugg = ArcRoutines.suggestions(
        contract: null,
        todayTitles: const [],
        goalKeys: const [],
        now: DateTime(2026, 9, 4, 20, 0), // evening
        count: 5,
      );
      expect(
        sugg.every((s) => s.bucket == 'evening' || s.bucket == 'any'),
        isTrue,
        reason: 'evening suggestions must not propose morning routines',
      );
    });

    test('goal alignment boosts matching routines', () {
      final sugg = ArcRoutines.suggestions(
        contract: null,
        todayTitles: const [],
        goalKeys: const ['fitness'],
        now: DateTime(2026, 9, 4, 7, 0),
        count: 3,
      );
      // With fitness goals set, morning fitness items should surface.
      expect(sugg.any((s) => s.goal == 'fitness'), isTrue);
    });

    test('respects the requested count', () {
      final sugg = ArcRoutines.suggestions(
        contract: null,
        todayTitles: const [],
        goalKeys: const [],
        now: DateTime(2026, 9, 4, 12, 0),
        count: 2,
      );
      expect(sugg.length, lessThanOrEqualTo(2));
    });
  });
}
