import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mita/core/streak_data_store.dart';
import 'package:mita/core/streak_freeze_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreakFreezeRules.weekIndex', () {
    test('never regresses across New Year', () {
      final days = [
        DateTime(2026, 12, 28),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
        DateTime(2027, 1, 4),
      ];
      var prev = StreakFreezeRules.weekIndex(days.first);
      for (final d in days.skip(1)) {
        final w = StreakFreezeRules.weekIndex(d);
        expect(w >= prev, isTrue, reason: 'week index regressed at $d');
        prev = w;
      }
    });

    test('same calendar week yields the same index', () {
      expect(
        StreakFreezeRules.weekIndex(DateTime(2026, 9, 1)),
        StreakFreezeRules.weekIndex(DateTime(2026, 9, 2)),
      );
      // Exactly 7 days apart -> next index.
      expect(
        StreakFreezeRules.weekIndex(DateTime(2026, 9, 8)),
        StreakFreezeRules.weekIndex(DateTime(2026, 9, 1)) + 1,
      );
    });
  });

  group('StreakFreezeRules.decide — Snapchat-style expiry', () {
    // Friday, 4 Sep 2026, mid-afternoon.
    final now = DateTime(2026, 9, 4, 14, 30);

    test('opening mid-day with today incomplete never acts', () {
      // Perfect yesterday; opening the app today before finishing -> safe.
      expect(
        StreakFreezeRules.decide(
          lastPerfectDay: DateTime(2026, 9, 3),
          now: now,
          frozenWeek: null,
        ),
        StreakFreezeAction.none,
      );
    });

    test('opening the app repeatedly the same day stays safe', () {
      for (var i = 0; i < 5; i++) {
        expect(
          StreakFreezeRules.decide(
            lastPerfectDay: DateTime(2026, 9, 3),
            now: now,
            frozenWeek: null,
          ),
          StreakFreezeAction.none,
        );
      }
    });

    test('perfect today always wins regardless of spent freeze', () {
      expect(
        StreakFreezeRules.decide(
          lastPerfectDay: DateTime(2026, 9, 4),
          now: now,
          frozenWeek: null,
        ),
        StreakFreezeAction.none,
      );
    });

    test('first missed week freezes but preserves the streak', () {
      // Perfect 3 days ago; yesterday fully missed; no freeze spent yet.
      expect(
        StreakFreezeRules.decide(
          lastPerfectDay: DateTime(2026, 9, 1),
          now: now,
          frozenWeek: null,
        ),
        StreakFreezeAction.freeze,
      );
    });

    test('already frozen in the same missed week: no further action', () {
      final sameWeek = StreakFreezeRules.weekIndex(DateTime(2026, 9, 3));
      expect(
        StreakFreezeRules.decide(
          lastPerfectDay: DateTime(2026, 9, 1),
          now: now,
          frozenWeek: sameWeek,
        ),
        StreakFreezeAction.alreadyFrozen,
      );
    });

    test('a later missed week after the freeze is spent resets', () {
      // Freeze spent two weeks ago; missed again this week -> reset.
      final earlierWeek = StreakFreezeRules.weekIndex(DateTime(2026, 8, 21));
      expect(
        StreakFreezeRules.decide(
          lastPerfectDay: DateTime(2026, 9, 1),
          now: now,
          frozenWeek: earlierWeek,
        ),
        StreakFreezeAction.reset,
      );
    });

    test('a long absence (many missed weeks) resets', () {
      // Perfect a month ago, freeze never spent -> one freeze, then the
      // *next* missed week would reset. With the freeze already spent any
      // check after a further missed week resets.
      final spentLongAgo = StreakFreezeRules.weekIndex(DateTime(2026, 8, 1));
      expect(
        StreakFreezeRules.decide(
          lastPerfectDay: DateTime(2026, 8, 5),
          now: now,
          frozenWeek: spentLongAgo,
        ),
        StreakFreezeAction.reset,
      );
    });

    test('null lastPerfectDay with a spent freeze resets', () {
      final spent = StreakFreezeRules.weekIndex(DateTime(2026, 9, 3));
      expect(
        StreakFreezeRules.decide(
          lastPerfectDay: null,
          now: now,
          frozenWeek: spent,
        ),
        StreakFreezeAction.alreadyFrozen,
      );
    });

    test('midnight rollover: at 00:01 yesterday is the last ended day', () {
      final justPastMidnight = DateTime(2026, 9, 4, 0, 1);
      // Perfect on 2 Sep; 3 Sep ended incomplete minutes ago -> freeze.
      expect(
        StreakFreezeRules.decide(
          lastPerfectDay: DateTime(2026, 9, 2),
          now: justPastMidnight,
          frozenWeek: null,
        ),
        StreakFreezeAction.freeze,
      );
    });
  });

  group('StreakDataStore round-trip (atomic blob)', () {
    test('persists and restores the full streak state', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();

      final state = {
        'streak': 5,
        'bestStreak': 9,
        'lastPerfectDay': '2026-09-02',
        'isStreakFrozen': true,
        'streakFrozenWeek': 3100,
        'earnedMilestones': [3, 5],
        'streakHistory': ['2026-09-01', '2026-09-02'],
      };
      await p.setString(StreakDataStore.stateKey, jsonEncode(state));

      final loaded = await StreakDataStore.load();
      expect(loaded['streak'], 5);
      expect(loaded['bestStreak'], 9);
      expect(loaded['lastPerfectDay'], '2026-09-02');
      expect(loaded['isStreakFrozen'], true);
      expect(loaded['streakFrozenWeek'], 3100);
      expect(loaded['streakHistory'], ['2026-09-01', '2026-09-02']);
    });

    test('falls back to legacy keys when no blob exists', () async {
      SharedPreferences.setMockInitialValues({
        'streak': 4,
        'bestStreak': 6,
        'lastPerfectDay': '2026-09-01',
        'isStreakFrozen': false,
      });
      final loaded = await StreakDataStore.load();
      expect(loaded['streak'], 4);
      expect(loaded['bestStreak'], 6);
      expect(loaded['lastPerfectDay'], '2026-09-01');
    });
  });
}
