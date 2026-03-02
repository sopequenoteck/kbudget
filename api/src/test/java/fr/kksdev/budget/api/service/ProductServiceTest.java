package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.ProductRequest;
import fr.kksdev.budget.api.dto.request.ProductUpdateRequest;
import fr.kksdev.budget.api.dto.request.RestockRequest;
import fr.kksdev.budget.api.dto.response.ProductResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.model.*;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.ProductRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProductServiceTest {

    @Mock
    private ProductRepository productRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PreferenceService preferenceService;

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private CategoryService categoryService;

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private ProductService productService;

    private final UUID userId = UUID.randomUUID();
    private final UUID productId = UUID.randomUUID();
    private final LocalDateTime now = LocalDateTime.now();

    private User user;
    private Product product;
    private Account shopAccount;
    private Category shopCategory;
    private UserPreference prefs;

    @BeforeEach
    void setUp() {
        user = User.builder().id(userId).email("test@mail.com").build();
        product = Product.builder()
                .id(productId)
                .nom("T-shirt")
                .description("Description")
                .icone("👕")
                .prixAchat(new BigDecimal("8.50"))
                .prixVente(new BigDecimal("15.00"))
                .stock(5)
                .totalVendu(3)
                .actif(true)
                .createdAt(now)
                .updatedAt(now)
                .user(user)
                .build();
        shopAccount = Account.builder()
                .id(UUID.randomUUID())
                .nom("Boutique")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🛍️")
                .couleur("#f59e0b")
                .currency(Currency.EUR)
                .actif(true)
                .user(user)
                .build();
        shopCategory = Category.builder()
                .id(UUID.randomUUID())
                .nom("Boutique")
                .icone("🛍️")
                .couleur("#f59e0b")
                .isSystem(true)
                .user(user)
                .build();
        prefs = UserPreference.builder()
                .id(UUID.randomUUID())
                .user(user)
                .enabledFeatures(List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP))
                .navOrder(List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP))
                .shopAccountId(shopAccount.getId())
                .includeShopInBalance(false)
                .build();
    }

    // === CRUD (feature 056) ===

    @Test
    void should_createProduct_when_shopEnabled() {
        var request = new ProductRequest(
                "T-shirt", "Description", "👕", null,
                new BigDecimal("8.50"), new BigDecimal("15.00"), 10
        );
        var saved = Product.builder()
                .id(productId).nom("T-shirt").description("Description").icone("👕")
                .prixAchat(new BigDecimal("8.50")).prixVente(new BigDecimal("15.00"))
                .stock(10).totalVendu(0).actif(true).createdAt(now).updatedAt(now).user(user)
                .build();

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(productRepository.save(any(Product.class))).thenReturn(saved);

        ProductResponse response = productService.create(request, userId);

        assertThat(response.id()).isEqualTo(productId);
        assertThat(response.nom()).isEqualTo("T-shirt");
        assertThat(response.actif()).isTrue();
        assertThat(response.totalVendu()).isZero();
        verify(productRepository).save(any(Product.class));
    }

    @Test
    void should_throwFeatureDisabled_when_shopNotEnabled() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(false);

        var request = new ProductRequest(
                "T-shirt", null, null, null,
                new BigDecimal("8.50"), new BigDecimal("15.00"), 10
        );

        assertThatThrownBy(() -> productService.create(request, userId))
                .isInstanceOf(FeatureDisabledException.class)
                .hasMessage("Fonctionnalité SHOP désactivée");
    }

    @Test
    void should_returnActiveProducts_when_listing() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findByUserIdAndActifTrueOrderByCreatedAtDesc(userId))
                .thenReturn(List.of(product));

        List<ProductResponse> result = productService.getAllByUser(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().nom()).isEqualTo("T-shirt");
        verify(productRepository).findByUserIdAndActifTrueOrderByCreatedAtDesc(userId);
    }

    @Test
    void should_returnProduct_when_ownerRequests() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));

        ProductResponse response = productService.getById(productId, userId);

        assertThat(response.id()).isEqualTo(productId);
        assertThat(response.nom()).isEqualTo("T-shirt");
    }

    @Test
    void should_throwNotFound_when_notOwner() {
        var otherUser = User.builder().id(UUID.randomUUID()).email("other@mail.com").build();
        var productOfOther = Product.builder()
                .id(productId).nom("T-shirt").prixAchat(new BigDecimal("8.50"))
                .prixVente(new BigDecimal("15.00")).stock(10).actif(true).user(otherUser).build();

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(productOfOther));

        assertThatThrownBy(() -> productService.getById(productId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Produit non trouvé");
    }

    @Test
    void should_updateAllFields_when_validUpdate() {
        var request = new ProductUpdateRequest(
                "T-shirt modifié", "Nouvelle description", "👕", "https://example.com/img.jpg",
                new BigDecimal("9.00"), new BigDecimal("18.00"), 20, false
        );

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));
        when(productRepository.save(any(Product.class))).thenReturn(product);

        productService.update(productId, request, userId);

        assertThat(product.getNom()).isEqualTo("T-shirt modifié");
        assertThat(product.getDescription()).isEqualTo("Nouvelle description");
        assertThat(product.getPrixAchat()).isEqualByComparingTo(new BigDecimal("9.00"));
        assertThat(product.getPrixVente()).isEqualByComparingTo(new BigDecimal("18.00"));
        assertThat(product.getStock()).isEqualTo(20);
        assertThat(product.getActif()).isFalse();
        assertThat(product.getImageUrl()).isEqualTo("https://example.com/img.jpg");
        verify(productRepository).save(product);
    }

    @Test
    void should_deleteProduct_when_ownerDeletes() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));

        productService.delete(productId, userId);

        verify(productRepository).delete(product);
    }

    // === sell (feature 057) ===

    @Test
    void should_sell_product_when_stock_available() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);
        when(accountRepository.findById(shopAccount.getId())).thenReturn(Optional.of(shopAccount));
        when(categoryService.findOrCreateShopCategory(userId)).thenReturn(shopCategory);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(i -> i.getArgument(0));
        when(productRepository.save(any(Product.class))).thenAnswer(i -> i.getArgument(0));

        ProductResponse response = productService.sell(productId, userId);

        assertThat(response.stock()).isEqualTo(4);
        assertThat(response.totalVendu()).isEqualTo(4);
        verify(transactionRepository).save(any(Transaction.class));
        verify(productRepository).save(any(Product.class));
    }

    @Test
    void should_throw_conflict_when_stock_zero() {
        product.setStock(0);

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));

        assertThatThrownBy(() -> productService.sell(productId, userId))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("Stock insuffisant");
    }

    @Test
    void should_throw_conflict_when_product_inactive_sell() {
        product.setActif(false);

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));

        assertThatThrownBy(() -> productService.sell(productId, userId))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("inactif");
    }

    @Test
    void should_throw_feature_disabled_when_shop_not_enabled_on_sell() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(false);

        assertThatThrownBy(() -> productService.sell(productId, userId))
                .isInstanceOf(FeatureDisabledException.class)
                .hasMessage("Fonctionnalité SHOP désactivée");
    }

    @Test
    void should_throw_not_found_when_product_not_found_on_sell() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> productService.sell(productId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Produit non trouvé");
    }

    @Test
    void should_sell_product_with_correct_transaction_type_and_libelle() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);
        when(accountRepository.findById(shopAccount.getId())).thenReturn(Optional.of(shopAccount));
        when(categoryService.findOrCreateShopCategory(userId)).thenReturn(shopCategory);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction saved = inv.getArgument(0);
            assertThat(saved.getType()).isEqualTo(TransactionType.RECETTE);
            assertThat(saved.getLibelle()).isEqualTo("Vente: T-shirt");
            assertThat(saved.getMontant()).isEqualByComparingTo(new BigDecimal("15.00"));
            return saved;
        });
        when(productRepository.save(any(Product.class))).thenAnswer(i -> i.getArgument(0));

        productService.sell(productId, userId);

        verify(transactionRepository).save(any(Transaction.class));
    }

    // === restock (feature 057) ===

    @Test
    void should_restock_product_when_active() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);
        when(accountRepository.findById(shopAccount.getId())).thenReturn(Optional.of(shopAccount));
        when(categoryService.findOrCreateShopCategory(userId)).thenReturn(shopCategory);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(i -> i.getArgument(0));
        when(productRepository.save(any(Product.class))).thenAnswer(i -> i.getArgument(0));

        ProductResponse response = productService.restock(productId, new RestockRequest(10), userId);

        assertThat(response.stock()).isEqualTo(15);
        verify(transactionRepository).save(any(Transaction.class));
        verify(productRepository).save(any(Product.class));
    }

    @Test
    void should_throw_conflict_when_product_inactive_restock() {
        product.setActif(false);

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));

        assertThatThrownBy(() -> productService.restock(productId, new RestockRequest(5), userId))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("inactif");
    }

    @Test
    void should_restock_with_correct_transaction_montant() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefs);
        when(accountRepository.findById(shopAccount.getId())).thenReturn(Optional.of(shopAccount));
        when(categoryService.findOrCreateShopCategory(userId)).thenReturn(shopCategory);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction saved = inv.getArgument(0);
            // prixAchat(8.50) * quantity(10) = 85.00
            assertThat(saved.getMontant()).isEqualByComparingTo(new BigDecimal("85.00"));
            assertThat(saved.getType()).isEqualTo(TransactionType.DEPENSE);
            assertThat(saved.getLibelle()).isEqualTo("Stock: T-shirt x10");
            return saved;
        });
        when(productRepository.save(any(Product.class))).thenAnswer(i -> i.getArgument(0));

        productService.restock(productId, new RestockRequest(10), userId);

        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void should_throw_feature_disabled_when_shop_not_enabled_on_restock() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(false);

        assertThatThrownBy(() -> productService.restock(productId, new RestockRequest(5), userId))
                .isInstanceOf(FeatureDisabledException.class)
                .hasMessage("Fonctionnalité SHOP désactivée");
    }

    // === shop account creation (feature 057) ===

    @Test
    void should_create_shop_account_on_first_operation_when_no_account_id() {
        UserPreference prefsNoShop = UserPreference.builder()
                .id(UUID.randomUUID())
                .user(user)
                .enabledFeatures(List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP))
                .navOrder(List.of(Feature.SUBSCRIPTIONS, Feature.DEBTS, Feature.SHOP))
                .shopAccountId(null)
                .includeShopInBalance(false)
                .build();

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));
        when(preferenceService.getOrCreatePreference(userId)).thenReturn(prefsNoShop);
        when(categoryService.findOrCreateShopCategory(userId)).thenReturn(shopCategory);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(accountRepository.save(any(Account.class))).thenReturn(shopAccount);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(i -> i.getArgument(0));
        when(productRepository.save(any(Product.class))).thenAnswer(i -> i.getArgument(0));

        productService.sell(productId, userId);

        verify(accountRepository).save(any(Account.class));
    }

    // === getSalesHistory (feature 057) ===

    @Test
    void should_return_only_recette_transactions_in_sales_history() {
        Transaction saleTx = Transaction.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("15.00"))
                .libelle("Vente: T-shirt")
                .type(TransactionType.RECETTE)
                .date(LocalDate.now())
                .product(product)
                .account(shopAccount)
                .category(shopCategory)
                .user(user)
                .build();
        Transaction restockTx = Transaction.builder()
                .id(UUID.randomUUID())
                .montant(new BigDecimal("85.00"))
                .libelle("Stock: T-shirt x10")
                .type(TransactionType.DEPENSE)
                .date(LocalDate.now())
                .product(product)
                .account(shopAccount)
                .category(shopCategory)
                .user(user)
                .build();

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));
        when(transactionRepository.findByProductIdAndUserIdOrderByDateDesc(productId, userId))
                .thenReturn(List.of(saleTx, restockTx));

        List<TransactionResponse> history = productService.getSalesHistory(productId, userId);

        assertThat(history).hasSize(1);
        assertThat(history.get(0).type()).isEqualTo(TransactionType.RECETTE);
        assertThat(history.get(0).libelle()).isEqualTo("Vente: T-shirt");
        assertThat(history.get(0).productId()).isEqualTo(productId);
        assertThat(history.get(0).productName()).isEqualTo("T-shirt");
    }

    @Test
    void should_return_empty_list_when_no_sales_history() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));
        when(transactionRepository.findByProductIdAndUserIdOrderByDateDesc(productId, userId))
                .thenReturn(List.of());

        List<TransactionResponse> history = productService.getSalesHistory(productId, userId);

        assertThat(history).isEmpty();
    }

    @Test
    void should_throw_not_found_when_product_not_found_on_sales_history() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> productService.getSalesHistory(productId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Produit non trouvé");
    }

    @Test
    void should_throw_feature_disabled_when_shop_not_enabled_on_sales_history() {
        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(false);

        assertThatThrownBy(() -> productService.getSalesHistory(productId, userId))
                .isInstanceOf(FeatureDisabledException.class)
                .hasMessage("Fonctionnalité SHOP désactivée");
    }

    @Test
    void should_throw_not_found_when_product_belongs_to_other_user_on_sales_history() {
        var otherUser = User.builder().id(UUID.randomUUID()).email("other@mail.com").build();
        var productOfOther = Product.builder()
                .id(productId).nom("T-shirt").prixAchat(new BigDecimal("8.50"))
                .prixVente(new BigDecimal("15.00")).stock(5).actif(true).user(otherUser).build();

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(productOfOther));

        assertThatThrownBy(() -> productService.getSalesHistory(productId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Produit non trouvé");
    }
}
