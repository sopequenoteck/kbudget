import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/auth/application/pin_hashing.dart';

void main() {
  group('generatePinSalt', () {
    test('should_return32HexCharacters_when_generated', () {
      final salt = generatePinSalt();

      expect(salt, matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('should_returnDifferentSalts_when_generatedTwice', () {
      expect(generatePinSalt(), isNot(generatePinSalt()));
    });

    test('should_beReproducible_when_randomIsSeeded', () {
      expect(
        generatePinSalt(random: Random(1)),
        generatePinSalt(random: Random(1)),
      );
    });
  });

  group('hashPin', () {
    test('should_returnSameHash_when_saltAndPinAreSame', () {
      expect(hashPin('aa', '1234'), hashPin('aa', '1234'));
    });

    test('should_returnDifferentHashes_when_saltsDiffer', () {
      expect(hashPin('aa', '1234'), isNot(hashPin('bb', '1234')));
    });

    test('should_returnDifferentHashes_when_pinsDiffer', () {
      expect(hashPin('aa', '1234'), isNot(hashPin('aa', '1235')));
    });

    test('should_beSha256OfSaltThenPin_when_hashed', () {
      // sha256("abc"): the salt "ab" followed by the pin "c".
      expect(
        hashPin('ab', 'c'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });
  });

  group('constantTimeEquals', () {
    test('should_returnTrue_when_stringsAreEqual', () {
      expect(constantTimeEquals('abcd', 'abcd'), isTrue);
    });

    test('should_returnTrue_when_bothAreEmpty', () {
      expect(constantTimeEquals('', ''), isTrue);
    });

    test('should_returnFalse_when_lastCharacterDiffers', () {
      expect(constantTimeEquals('abcd', 'abce'), isFalse);
    });

    test('should_returnFalse_when_firstCharacterDiffers', () {
      expect(constantTimeEquals('abcd', 'bbcd'), isFalse);
    });

    test('should_returnFalse_when_lengthsDiffer', () {
      expect(constantTimeEquals('abc', 'abcd'), isFalse);
      expect(constantTimeEquals('abcd', 'abc'), isFalse);
    });

    test('should_returnFalse_when_oneIsEmpty', () {
      expect(constantTimeEquals('', 'a'), isFalse);
    });
  });
}
