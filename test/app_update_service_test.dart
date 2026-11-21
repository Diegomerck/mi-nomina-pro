import 'package:flutter_test/flutter_test.dart';
import 'package:overtime_app/services/app_update_service.dart';

void main() {
  group('AppUpdateService Version Comparison Tests', () {
    test('Identifies newer remote patch version', () {
      expect(AppUpdateService.compareVersions('23.20.2', '23.20.1'), greaterThan(0));
    });

    test('Identifies newer remote minor version', () {
      expect(AppUpdateService.compareVersions('23.21.0', '23.20.1'), greaterThan(0));
    });

    test('Identifies newer remote major version', () {
      expect(AppUpdateService.compareVersions('24.0.0', '23.20.1'), greaterThan(0));
    });

    test('Identifies older remote version', () {
      expect(AppUpdateService.compareVersions('23.19.0', '23.20.1'), lessThan(0));
      expect(AppUpdateService.compareVersions('23.20.0', '23.20.1'), lessThan(0));
    });

    test('Identifies identical versions', () {
      expect(AppUpdateService.compareVersions('23.20.1', '23.20.1'), equals(0));
    });

    test('Handles v and V prefixes correctly', () {
      expect(AppUpdateService.compareVersions('v23.21.0', '23.20.1'), greaterThan(0));
      expect(AppUpdateService.compareVersions('V23.21.0', 'v23.21.0'), equals(0));
      expect(AppUpdateService.compareVersions('v23.20.1', '23.20.1'), equals(0));
    });

    test('Handles versions with different segment counts', () {
      expect(AppUpdateService.compareVersions('23.20.1', '23.20'), greaterThan(0));
      expect(AppUpdateService.compareVersions('23.20', '23.20.0'), equals(0));
      expect(AppUpdateService.compareVersions('23.20', '23.20.1'), lessThan(0));
    });

    test('Authoritative current version comparisons', () {
      const current = '23.20.4';
      expect(AppUpdateService.compareVersions('23.20.5', current), greaterThan(0));
      expect(AppUpdateService.compareVersions('23.21.0', current), greaterThan(0));
      expect(AppUpdateService.compareVersions('v23.20.4', current), equals(0));
      expect(AppUpdateService.compareVersions('23.20.4', current), equals(0));
      expect(AppUpdateService.compareVersions('23.20.3', current), lessThan(0));
      expect(AppUpdateService.compareVersions('23.20.1', current), lessThan(0));
      expect(AppUpdateService.compareVersions('23.19.0', current), lessThan(0));
    });
  });
}
