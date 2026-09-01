import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/utils/version_compare.dart';

void main() {
  group('compareVersions', () {
    test('should_returnZero_when_versionsAreEqual', () {
      expect(compareVersions('6.0.0', '6.0.0'), 0);
    });

    test('should_orderByMajor_when_majorsDiffer', () {
      expect(compareVersions('5.9.9', '6.0.0'), lessThan(0));
      expect(compareVersions('7.0.0', '6.9.9'), greaterThan(0));
    });

    test('should_orderByMinor_when_majorIsEqual', () {
      expect(compareVersions('6.1.0', '6.2.0'), lessThan(0));
    });

    test('should_orderByPatch_when_majorAndMinorAreEqual', () {
      expect(compareVersions('6.0.1', '6.0.2'), lessThan(0));
    });

    test('should_compareNumerically_when_segmentsHaveDifferentLengths', () {
      // "10" < "9" en comparaison de chaines : le piege que ce comparateur evite.
      expect(compareVersions('6.10.0', '6.9.0'), greaterThan(0));
    });

    test('should_ignoreBuildNumber_when_pubspecFormatIsUsed', () {
      // Le +1 de pubspec.yaml est un build number pour les stores, sans rapport
      // avec la compatibilite du contrat d'API.
      expect(compareVersions('6.0.0+1', '6.0.0'), 0);
      expect(compareVersions('6.0.0+42', '6.0.0+1'), 0);
    });

    test('should_ignorePrereleaseSuffix_when_present', () {
      expect(compareVersions('6.0.0-rc.1', '6.0.0'), 0);
    });

    test('should_treatMissingSegmentsAsZero_when_versionIsShort', () {
      expect(compareVersions('6', '6.0.0'), 0);
      expect(compareVersions('6.1', '6.0.0'), greaterThan(0));
    });
  });

  group('isOlderThan', () {
    test('should_returnTrue_when_strictlyOlder', () {
      expect(isOlderThan('5.4.0', '6.0.0'), isTrue);
    });

    test('should_returnFalse_when_equal', () {
      expect(isOlderThan('6.0.0', '6.0.0'), isFalse);
    });

    test('should_returnFalse_when_newer', () {
      expect(isOlderThan('6.1.0', '6.0.0'), isFalse);
    });
  });
}
