import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_state.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/display_locale.dart';
import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAppConfigRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAppConfigRepository();
    container = ProviderContainer(
      overrides: [
        displayLocaleOverride(),
        appConfigRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('OnboardingNotifier', () {
    test('should_have_initial_state_when_created', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);
      final state = container.read(onboardingNotifierProvider);

      expect(notifier, isNotNull);
      expect(state, const OnboardingState());
      expect(state.serverUrl, isNull);
      expect(state.isCompleted, false);
    });

    test('should_return_false_when_onboarding_not_completed', () async {
      when(mockRepo.isOnboardingCompleted()).thenAnswer((_) async => false);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      final result = await notifier.isOnboardingCompleted();

      expect(result, false);
      verify(mockRepo.isOnboardingCompleted()).called(1);
    });

    test('should_return_true_when_onboarding_completed', () async {
      when(mockRepo.isOnboardingCompleted()).thenAnswer((_) async => true);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      final result = await notifier.isOnboardingCompleted();

      expect(result, true);
    });

    test('should_update_server_url_when_setServerUrl_called', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);

      notifier.setServerUrl('https://budget.example.com/api');

      final state = container.read(onboardingNotifierProvider);
      expect(state.serverUrl, 'https://budget.example.com/api');
    });

    test('should_persist_server_url_when_completeOnboarding_called', () async {
      when(mockRepo.setServerUrl('https://budget.example.com/api'))
          .thenAnswer((_) async {});
      when(mockRepo.setOnboardingCompleted(true)).thenAnswer((_) async {});

      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setServerUrl('https://budget.example.com/api');
      await notifier.completeOnboarding();

      final state = container.read(onboardingNotifierProvider);
      expect(state.isCompleted, true);
      verify(mockRepo.setServerUrl('https://budget.example.com/api'))
          .called(1);
      verify(mockRepo.setOnboardingCompleted(true)).called(1);
    });

    test('should_not_complete_when_no_server_url_set', () async {
      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.completeOnboarding();

      final state = container.read(onboardingNotifierProvider);
      expect(state.isCompleted, false);
      verifyNever(mockRepo.setServerUrl(any));
      verifyNever(mockRepo.setOnboardingCompleted(any));
    });

    test('should_set_error_when_save_fails', () async {
      when(mockRepo.setServerUrl('https://budget.example.com/api'))
          .thenThrow(Exception('Storage error'));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setServerUrl('https://budget.example.com/api');
      await notifier.completeOnboarding();

      final state = container.read(onboardingNotifierProvider);
      expect(state.isCompleted, false);
      expect(state.isSaving, false);
      expect(state.error, contains('Erreur'));
    });
  });
}
