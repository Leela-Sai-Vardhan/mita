import 'package:flutter_test/flutter_test.dart';
import 'package:mita/services/app_update_service.dart';

void main() {
  group('AppUpdateService.forceUpdateRequired', () {
    test('999999 sentinel never forces when no newer build exists', () {
      // Regression: live config shipped force_update_from_build=999999 with
      // latest_build=11 on a build-11 install, trapping users in a
      // non-dismissable "Update available" dialog for a version that did
      // not exist.
      expect(
        AppUpdateService.forceUpdateRequired(
          currentBuild: 11,
          latestBuild: 11,
          forceFrom: 999999,
        ),
        isFalse,
      );
    });

    test('999999 sentinel does not force when latest is behind', () {
      expect(
        AppUpdateService.forceUpdateRequired(
          currentBuild: 11,
          latestBuild: 9,
          forceFrom: 999999,
        ),
        isFalse,
      );
    });

    test('does not force when force_from is null', () {
      expect(
        AppUpdateService.forceUpdateRequired(
          currentBuild: 11,
          latestBuild: 20,
          forceFrom: null,
        ),
        isFalse,
      );
    });

    test('zero disables forcing', () {
      expect(
        AppUpdateService.forceUpdateRequired(
          currentBuild: 11,
          latestBuild: 20,
          forceFrom: 0,
        ),
        isFalse,
      );
    });

    test('forces only when a newer build exists and build is below threshold',
        () {
      expect(
        AppUpdateService.forceUpdateRequired(
          currentBuild: 11,
          latestBuild: 20,
          forceFrom: 15,
        ),
        isTrue,
      );
    });

    test('does not force when newest build already installed', () {
      expect(
        AppUpdateService.forceUpdateRequired(
          currentBuild: 20,
          latestBuild: 20,
          forceFrom: 15,
        ),
        isFalse,
      );
    });

    test('does not force when build is at or above threshold', () {
      expect(
        AppUpdateService.forceUpdateRequired(
          currentBuild: 15,
          latestBuild: 20,
          forceFrom: 15,
        ),
        isFalse,
      );
    });
  });

  group('AppUpdateService.currentBuild', () {
    test('parses the build from AppTheme.appVersion', () {
      // AppTheme.appVersion is '2.0.0+11'.
      expect(AppUpdateService().currentBuild, 11);
    });
  });
}