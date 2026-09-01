import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/remote/compatibility_provider.dart';
import 'package:k_budget/src/data/remote/compatibility_service.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../helpers/mocks.mocks.dart';

/// Service de test : compte ses appels pour verifier la memoisation.
class _CountingService implements CompatibilityService {
  _CountingService(this.result);

  final CompatibilityStatus result;
  int callCount = 0;

  @override
  Future<CompatibilityStatus> check({
    required String baseUrl,
    required String clientVersion,
  }) async {
    callCount++;
    return result;
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PackageInfo.setMockInitialValues(
      appName: 'k-budget',
      packageName: 'fr.kksdev.budget',
      version: '6.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  ProviderContainer containerWith(_CountingService service, MockAppConfigRepository repo) =>
      ProviderContainer(overrides: [
        compatibilityServiceProvider.overrideWithValue(service),
        appConfigRepositoryProvider.overrideWithValue(repo),
      ]);

  test('should_startWithNoVerdict_when_neverChecked', () {
    final repo = MockAppConfigRepository();
    when(repo.getServerUrl()).thenAnswer((_) async => 'https://host/api');
    final container = containerWith(
        _CountingService(const CompatibilityOffline()), repo);
    addTearDown(container.dispose);

    expect(container.read(compatibilityNotifierProvider), isNull);
  });

  test('should_storeVerdict_when_checked', () async {
    final repo = MockAppConfigRepository();
    when(repo.getServerUrl()).thenAnswer((_) async => 'https://host/api');
    final container = containerWith(
        _CountingService(const CompatibilityOffline()), repo);
    addTearDown(container.dispose);

    final status = await container
        .read(compatibilityNotifierProvider.notifier)
        .ensureChecked();

    expect(status, isA<CompatibilityOffline>());
    expect(container.read(compatibilityNotifierProvider), isA<CompatibilityOffline>());
  });

  test('should_checkOnlyOnce_when_calledRepeatedly', () async {
    // Le routeur consulte ce verdict a chaque redirection : refaire l'appel
    // reseau a chaque navigation ajouterait une latence sur chaque transition.
    final repo = MockAppConfigRepository();
    when(repo.getServerUrl()).thenAnswer((_) async => 'https://host/api');
    final service = _CountingService(const CompatibilityOffline());
    final container = containerWith(service, repo);
    addTearDown(container.dispose);

    final notifier = container.read(compatibilityNotifierProvider.notifier);
    await notifier.ensureChecked();
    await notifier.ensureChecked();
    await notifier.ensureChecked();

    expect(service.callCount, 1);
  });

  test('should_recheck_when_resetCalled', () async {
    // Apres un changement d'URL de serveur, le verdict connu ne vaut plus.
    final repo = MockAppConfigRepository();
    when(repo.getServerUrl()).thenAnswer((_) async => 'https://host/api');
    final service = _CountingService(const CompatibilityOffline());
    final container = containerWith(service, repo);
    addTearDown(container.dispose);

    final notifier = container.read(compatibilityNotifierProvider.notifier);
    await notifier.ensureChecked();
    notifier.reset();
    await notifier.ensureChecked();

    expect(service.callCount, 2);
    expect(container.read(compatibilityNotifierProvider), isNotNull);
  });

  test('should_clearVerdict_when_resetCalled', () async {
    final repo = MockAppConfigRepository();
    when(repo.getServerUrl()).thenAnswer((_) async => 'https://host/api');
    final container = containerWith(
        _CountingService(const CompatibilityOffline()), repo);
    addTearDown(container.dispose);

    final notifier = container.read(compatibilityNotifierProvider.notifier);
    await notifier.ensureChecked();
    expect(container.read(compatibilityNotifierProvider), isNotNull);

    notifier.reset();
    expect(container.read(compatibilityNotifierProvider), isNull);
  });
}
