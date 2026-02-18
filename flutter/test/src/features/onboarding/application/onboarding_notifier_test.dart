import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_state.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAppConfigRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAppConfigRepository();
    container = ProviderContainer(
      overrides: [
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
      expect(state.selectedMode, isNull);
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

    test('should_update_selected_mode_when_selectMode_called', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);

      notifier.selectMode(DataMode.local);

      final state = container.read(onboardingNotifierProvider);
      expect(state.selectedMode, DataMode.local);
    });

    test('should_update_server_url_when_setServerUrl_called', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);

      notifier.setServerUrl('https://budget.example.com/api');

      final state = container.read(onboardingNotifierProvider);
      expect(state.serverUrl, 'https://budget.example.com/api');
    });

    test('should_persist_local_mode_when_completeOnboarding_called', () async {
      when(mockRepo.setDataMode(DataMode.local)).thenAnswer((_) async {});
      when(mockRepo.setOnboardingCompleted(true)).thenAnswer((_) async {});

      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.selectMode(DataMode.local);
      await notifier.completeOnboarding();

      final state = container.read(onboardingNotifierProvider);
      expect(state.isCompleted, true);
      verify(mockRepo.setDataMode(DataMode.local)).called(1);
      verify(mockRepo.setOnboardingCompleted(true)).called(1);
    });

    test(
        'should_persist_server_mode_and_url_when_completeOnboarding_called_with_server',
        () async {
      when(mockRepo.setDataMode(DataMode.server)).thenAnswer((_) async {});
      when(mockRepo.setServerUrl('https://budget.example.com/api'))
          .thenAnswer((_) async {});
      when(mockRepo.setOnboardingCompleted(true)).thenAnswer((_) async {});

      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.selectMode(DataMode.server);
      notifier.setServerUrl('https://budget.example.com/api');
      await notifier.completeOnboarding();

      final state = container.read(onboardingNotifierProvider);
      expect(state.isCompleted, true);
      verify(mockRepo.setDataMode(DataMode.server)).called(1);
      verify(mockRepo.setServerUrl('https://budget.example.com/api'))
          .called(1);
      verify(mockRepo.setOnboardingCompleted(true)).called(1);
    });

    test('should_not_complete_when_no_mode_selected', () async {
      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.completeOnboarding();

      final state = container.read(onboardingNotifierProvider);
      expect(state.isCompleted, false);
      verifyNever(mockRepo.setDataMode(any));
    });

    test('should_set_error_when_save_fails', () async {
      when(mockRepo.setDataMode(DataMode.local))
          .thenThrow(Exception('Storage error'));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.selectMode(DataMode.local);
      await notifier.completeOnboarding();

      final state = container.read(onboardingNotifierProvider);
      expect(state.isCompleted, false);
      expect(state.isSaving, false);
      expect(state.error, contains('Erreur'));
    });

    test('should_clear_error_when_mode_selected', () {
      final notifier = container.read(onboardingNotifierProvider.notifier);

      // Simulate an error state by selecting and then selecting again
      notifier.selectMode(DataMode.local);
      final state = container.read(onboardingNotifierProvider);
      expect(state.error, isNull);
    });
  });
}
