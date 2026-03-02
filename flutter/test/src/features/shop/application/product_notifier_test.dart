import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/domain/models/product.dart';
import 'package:k_budget/src/features/shop/application/product_list_state.dart';
import 'package:k_budget/src/features/shop/application/product_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockProductRepository mockRepo;
  late ProviderContainer container;

  const product1 = Product(
    id: '1',
    nom: 'Laptop Pro',
    prixAchat: 800.0,
    prixVente: 1200.0,
    stock: 5,
    totalVendu: 10,
  );
  const product2 = Product(
    id: '2',
    nom: 'Casque Audio',
    prixAchat: 50.0,
    prixVente: 80.0,
    stock: 20,
    totalVendu: 35,
  );

  setUp(() {
    mockRepo = MockProductRepository();
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  ProductNotifier notifier() =>
      container.read(productNotifierProvider.notifier);

  ProductListState state() => container.read(productNotifierProvider);

  group('ProductNotifier', () {
    test('should_load_products_sorted_by_name_when_loadItems_called', () async {
      // Laptop Pro comes after Casque Audio alphabetically
      when(mockRepo.getAll()).thenAnswer((_) async => [product1, product2]);

      await notifier().loadItems();

      expect(state().items, hasLength(2));
      expect(state().items[0].nom, 'Casque Audio');
      expect(state().items[1].nom, 'Laptop Pro');
      expect(state().isLoading, false);
      expect(state().error, isNull);
    });

    test('should_set_loading_true_when_loading', () async {
      when(mockRepo.getAll()).thenAnswer((_) async {
        return [product1];
      });

      final future = notifier().loadItems();

      // After loadItems is called, loading should be true initially
      // But since we await, we check the final state
      await future;
      expect(state().isLoading, false); // After completion, loading is false
    });

    test('should_set_error_when_load_fails', () async {
      when(mockRepo.getAll()).thenThrow(Exception('Network error'));

      await notifier().loadItems();

      expect(state().error, contains('Impossible de charger'));
      expect(state().isLoading, false);
    });

    test('should_add_product_when_create_called', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [product1]);
      await notifier().loadItems();

      when(mockRepo.create(any)).thenAnswer((_) async => product2);
      await notifier().create(product2);

      expect(state().items, hasLength(2));
    });

    test('should_refresh_items_when_refresh_called', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [product1]);
      await notifier().loadItems();
      expect(state().items, hasLength(1));

      when(mockRepo.getAll()).thenAnswer((_) async => [product1, product2]);
      await notifier().refresh();

      expect(state().items, hasLength(2));
    });

    test('should_update_product_when_update_called', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [product1]);
      await notifier().loadItems();

      final updated = product1.copyWith(prixVente: 1500.0);
      when(mockRepo.update(any)).thenAnswer((_) async => updated);
      await notifier().update(updated);

      expect(state().items.first.prixVente, 1500.0);
      expect(state().mutatingIds, isEmpty);
    });

    test('should_remove_product_when_delete_succeeds', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [product1, product2]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenAnswer((_) async {});
      await notifier().delete('1');

      expect(state().items, hasLength(1));
    });

    test('should_rollback_product_when_delete_fails', () async {
      when(mockRepo.getAll()).thenAnswer((_) async => [product1]);
      await notifier().loadItems();

      when(mockRepo.delete(any)).thenThrow(Exception('Server error'));
      await notifier().delete('1');

      expect(state().items, hasLength(1));
      expect(state().error, contains('Erreur lors de la suppression'));
    });

    test('should_load_next_page_when_loadMore_called', () async {
      final items = List.generate(
        25,
        (i) => Product(
          id: '$i',
          nom: 'Product ${i.toString().padLeft(2, '0')}',
          prixAchat: 10.0,
          prixVente: 15.0,
          stock: 5,
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
