import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/api_client.dart';
import 'package:k_budget/src/data/repository_providers.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_state.dart';
import 'package:k_budget/src/utils/env_config.dart';
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

    test('should_pointApiClientsAtSavedUrl_when_onboardingCompleted',
        () async {
      String? storedUrl;
      when(mockRepo.getServerUrl()).thenAnswer((_) async => storedUrl);
      when(mockRepo.setServerUrl(any)).thenAnswer((invocation) async {
        storedUrl = invocation.positionalArguments.first as String;
      });
      when(mockRepo.setOnboardingCompleted(true)).thenAnswer((_) async {});
      // The app builds its clients at startup, before any URL is saved.
      final atStartup = await container.read(authenticatedDioProvider.future);
      final signInAtStartup =
          await container.read(authRepositoryProvider.future);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      notifier.setServerUrl('https://budget.example.com/api');
      await notifier.completeOnboarding();

      final publicClient = await container.read(apiClientProvider.future);
      final authenticated =
          await container.read(authenticatedDioProvider.future);
      expect(
        atStartup.options.baseUrl,
        EnvConfig.versionedUrl(EnvConfig.apiBaseUrl),
      );
      expect(
        publicClient.options.baseUrl,
        'https://budget.example.com/api/v1',
      );
      expect(
        authenticated.options.baseUrl,
        'https://budget.example.com/api/v1',
      );
      // Sign-in goes through the repository: it must be rebuilt as well.
      expect(
        await container.read(authRepositoryProvider.future),
        isNot(same(signInAtStartup)),
      );
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
