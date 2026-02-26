import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/category.dart';
import 'package:k_budget/src/domain/models/list_state.dart';
import 'package:k_budget/src/features/categories/application/category_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockCategoryRepository mockRepo;
  late ProviderContainer container;

  const cat1 = Category(
    id: '1',
    nom: 'Alimentation',
    icone: '🍕',
    couleur: '#FF0000',
  );
  const cat2 = Category(
    id: '2',
    nom: 'Transport',
    icone: '🚗',
    couleur: '#0000FF',
  );
  const systemCat = Category(
    id: 'sys1',
    nom: 'Non catégorisé',
    icone: '❓',
    couleur: '#999999',
    isSystem: true,
  );

  setUp(() {
    mockRepo = MockCategoryRepository();
    container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  CategoryNotifier notifier() =>
      container.read(categoryNotifierProvider.notifier);

  ListState<Category> state() => container.read(categoryNotifierProvider);

  group('CategoryNotifier', () {
    test('should_haveEmptyState_when_created', () {
      expect(state().items, isEmpty);
      expect(state().isLoading, false);
    });

    test('should_showItems_when_loadSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [cat2, cat1]);

      await notifier().loadItems();

      expect(state().items, hasLength(2));
      expect(state().items[0].nom, 'Alimentation');
      expect(state().items[1].nom, 'Transport');
    });

    test('should_showError_when_loadFails', () async {
      when(mockRepo.getAll()).thenThrow(Exception('Network error'));

      await notifier().loadItems();

      expect(state().error, contains('Impossible de charger'));
    });

    test('should_addItem_when_createSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [cat1]);
      await notifier().loadItems();

      when(mockRepo.create(any)).thenAnswer((_) async => cat2);
      await notifier().create(cat2);

      expect(state().items, hasLength(2));
    });

    test('should_updateItem_when_updateSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [cat1]);
      await notifier().loadItems();

      final updated = cat1.copyWith(nom: 'Courses');
      when(mockRepo.update(any)).thenAnswer((_) async => updated);
      await notifier().update(updated);

      expect(state().items.first.nom, 'Courses');
      expect(state().mutatingIds, isEmpty);
    });

    test('should_removeItem_when_deleteSucceeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [cat1, cat2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenAnswer((_) async {});
      await notifier().delete('1');

      expect(state().items, hasLength(1));
    });

    test('should_rollbackItem_when_deleteFails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [cat1]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenThrow(Exception('Server error'));
      await notifier().delete('1');

      expect(state().items, hasLength(1));
      expect(state().error, contains('Erreur lors de la suppression'));
    });

    test('should_refuseUpdate_when_categoryIsSystem', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [systemCat, cat1]);
      await notifier().loadItems();

      await notifier().update(systemCat.copyWith(nom: 'Renamed'));

      expect(state().error, contains('catégories système'));
      verifyNever(mockRepo.update(any));
    });

    test('should_refuseDelete_when_categoryIsSystem', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [systemCat, cat1]);
      await notifier().loadItems();

      await notifier().delete('sys1');

      expect(state().error, contains('catégories système'));
      expect(state().items, hasLength(2));
      verifyNever(mockRepo.delete(any));
    });

    test('should_allowUpdate_when_categoryIsNotSystem', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [cat1]);
      await notifier().loadItems();

      final updated = cat1.copyWith(nom: 'Courses');
      when(mockRepo.update(any)).thenAnswer((_) async => updated);
      await notifier().update(updated);

      expect(state().items.first.nom, 'Courses');
      verify(mockRepo.update(any)).called(1);
    });

    test('should_loadNextPage_when_loadMoreCalled', () async {
      final items = List.generate(
        25,
        (i) => Category(
          id: '$i',
          nom: 'Cat ${i.toString().padLeft(2, '0')}',
          icone: '📁',
          couleur: '#000000',
        ),
      );
      when(mockRepo.getAll()).thenAnswer((_) async => items);

      await notifier().loadItems();
      expect(state().items, hasLength(20));

      notifier().loadMore();
      expect(state().items, hasLength(25));
      expect(state().hasMore, false);
    });
  });
}
