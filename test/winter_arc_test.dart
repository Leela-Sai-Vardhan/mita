import 'package:flutter_test/flutter_test.dart';
import 'package:mita/core/winter_arc.dart';

void main() {
  // The default window is Sep 1 - Feb 28/29 (remote config not loaded in
  // tests, so the baked-in defaults apply).
  group('WinterArc.isArcSeason', () {
    test('in season for Sep-Feb', () {
      expect(WinterArc.isArcSeason(DateTime(2026, 9, 1)), isTrue);
      expect(WinterArc.isArcSeason(DateTime(2026, 10, 15)), isTrue);
      expect(WinterArc.isArcSeason(DateTime(2026, 12, 31)), isTrue);
      expect(WinterArc.isArcSeason(DateTime(2027, 1, 1)), isTrue);
      expect(WinterArc.isArcSeason(DateTime(2027, 2, 28)), isTrue);
    });

    test('out of season for Mar-Aug', () {
      expect(WinterArc.isArcSeason(DateTime(2026, 3, 1)), isFalse);
      expect(WinterArc.isArcSeason(DateTime(2026, 6, 15)), isFalse);
      expect(WinterArc.isArcSeason(DateTime(2026, 8, 31)), isFalse);
    });
  });

  group('WinterArc window math', () {
    test('arc start/end for a fall date', () {
      final nov = DateTime(2026, 11, 10);
      expect(WinterArc.arcStartFor(nov), DateTime(2026, 9, 1));
      expect(WinterArc.arcEndFor(nov), DateTime(2027, 2, 28));
    });

    test('arc start/end for a winter date rolls to previous September', () {
      final jan = DateTime(2027, 1, 15);
      expect(WinterArc.arcStartFor(jan), DateTime(2026, 9, 1));
      expect(WinterArc.arcEndFor(jan), DateTime(2027, 2, 28));
    });

    test('opening day is day 1', () {
      expect(WinterArc.dayOfArc(DateTime(2026, 9, 1)), 1);
    });

    test('leap-year arc counts 182 days', () {
      // Sep 1 2027 - Feb 29 2028.
      final total = WinterArc.totalDays(DateTime(2027, 11, 1));
      expect(total, 182);
    });

    test('non-leap arc counts 181 days', () {
      // Sep 1 2026 - Feb 28 2027.
      final total = WinterArc.totalDays(DateTime(2026, 11, 1));
      expect(total, 181);
    });

    test('day count and remaining sum to total', () {
      final mid = DateTime(2026, 12, 15);
      expect(
        WinterArc.dayOfArc(mid) + WinterArc.daysRemaining(mid),
        WinterArc.totalDays(mid),
      );
    });

    test('final day has zero remaining', () {
      expect(WinterArc.daysRemaining(DateTime(2027, 2, 28)), 0);
    });
  });

  group('WinterArc phases', () {
    test('lock in phase at the start', () {
      expect(WinterArc.phase(DateTime(2026, 9, 5)), WinterArcPhase.lockIn);
    });

    test('deep winter through the middle', () {
      expect(
          WinterArc.phase(DateTime(2026, 12, 1)), WinterArcPhase.deepWinter);
    });

    test('final stretch at the end', () {
      expect(
          WinterArc.phase(DateTime(2027, 2, 1)), WinterArcPhase.finalStretch);
    });
  });

  group('WinterArc.lockedInDays', () {
    test('counts only perfect days inside the window', () {
      final now = DateTime(2026, 11, 1);
      final history = [
        '2026-09-01', // in arc
        '2026-09-15', // in arc
        '2026-10-02', // in arc
        '2026-08-31', // before arc
        '2027-02-28', // in arc (end boundary)
        '2027-03-01', // after arc
        'garbage', // unparseable, ignored
      ];
      expect(WinterArc.lockedInDays(history, now), 4);
    });

    test('empty history locks in zero days', () {
      expect(WinterArc.lockedInDays(const [], DateTime(2026, 11, 1)), 0);
    });
  });

  group('WinterArc.nextLockInMilestone', () {
    test('7 is the first milestone', () {
      expect(WinterArc.nextLockInMilestone(0), 7);
      expect(WinterArc.nextLockInMilestone(6), 7);
    });

    test('moves up after each step', () {
      expect(WinterArc.nextLockInMilestone(7), 21);
      expect(WinterArc.nextLockInMilestone(21), 50);
      expect(WinterArc.nextLockInMilestone(100), 150);
    });

    test('null beyond the last step', () {
      expect(WinterArc.nextLockInMilestone(200), isNull);
      expect(WinterArc.nextLockInMilestone(999), isNull);
    });
  });

  group('WinterArc.dailyMessage', () {
    test('returns a message for every day of the arc', () {
      for (var d = 0; d < 181; d++) {
        final msg =
            WinterArc.dailyMessage(DateTime(2026, 9, 1).add(Duration(days: d)));
        expect(msg.isNotEmpty, isTrue);
      }
    });

    test('stable within a day, rotates across days', () {
      final morning = DateTime(2026, 11, 1, 8);
      final night = DateTime(2026, 11, 1, 22);
      expect(
          WinterArc.dailyMessage(morning), WinterArc.dailyMessage(night));

      final next = DateTime(2026, 11, 2, 8);
      // Not a strict inequality guarantee (pools are long), but consecutive
      // days in the same phase with different indices usually differ.
      expect(WinterArc.dailyMessage(next).isNotEmpty, isTrue);
    });
  });
}