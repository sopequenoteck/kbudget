import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/subscriptions/presentation/frequency_suffix.dart';
import 'package:k_budget/src/localization/app_localizations_en.dart';
import 'package:k_budget/src/localization/app_localizations_fr.dart';

void main() {
  final fr = AppLocalizationsFr();
  final en = AppLocalizationsEn();

  for (final (frequency, expectedFr, expectedEn) in [
    // Un abonnement hebdomadaire s'affichait « /an » dans la liste (KKS-401)
    (Frequency.hebdomadaire, '/sem', '/week'),
    (Frequency.mensuel, '/mois', '/month'),
    (Frequency.annuel, '/an', '/year'),
  ]) {
    test('should_return_period_suffix_when_frequency_is_${frequency.name}', () {
      expect(frequencySuffix(frequency, fr), expectedFr);
      expect(frequencySuffix(frequency, en), expectedEn);
    });
  }
}
