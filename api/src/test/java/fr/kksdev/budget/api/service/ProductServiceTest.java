package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.ProductRequest;
import fr.kksdev.budget.api.dto.request.ProductUpdateRequest;
import fr.kksdev.budget.api.dto.response.ProductResponse;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.model.Product;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.ProductRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
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

    @InjectMocks
    private ProductService productService;

    private final UUID userId = UUID.randomUUID();
    private final UUID productId = UUID.randomUUID();
    private final LocalDateTime now = LocalDateTime.now();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").build();
    }

    private Product buildProduct(User user) {
        return Product.builder()
                .id(productId)
                .nom("T-shirt")
                .description("Description")
                .icone("👕")
                .prixAchat(new BigDecimal("8.50"))
                .prixVente(new BigDecimal("15.00"))
                .stock(10)
                .totalVendu(0)
                .actif(true)
                .createdAt(now)
                .updatedAt(now)
                .user(user)
                .build();
    }

    @Test
    void should_createProduct_when_shopEnabled() {
        var user = buildUser();
        var request = new ProductRequest(
                "T-shirt", "Description", "👕", null,
                new BigDecimal("8.50"), new BigDecimal("15.00"), 10
        );
        var saved = buildProduct(user);

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
        var user = buildUser();
        var product = buildProduct(user);

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
        var user = buildUser();
        var product = buildProduct(user);

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));

        ProductResponse response = productService.getById(productId, userId);

        assertThat(response.id()).isEqualTo(productId);
        assertThat(response.nom()).isEqualTo("T-shirt");
    }

    @Test
    void should_throwNotFound_when_notOwner() {
        var otherUser = User.builder().id(UUID.randomUUID()).email("other@mail.com").build();
        var product = buildProduct(otherUser);

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));

        assertThatThrownBy(() -> productService.getById(productId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Produit non trouvé");
    }

    @Test
    void should_updateAllFields_when_validUpdate() {
        var user = buildUser();
        var product = buildProduct(user);
        var request = new ProductUpdateRequest(
                "T-shirt modifié", "Nouvelle description", "👕", "https://example.com/img.jpg",
                new BigDecimal("9.00"), new BigDecimal("18.00"), 20, false
        );

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));
        when(productRepository.save(any(Product.class))).thenReturn(product);

        ProductResponse response = productService.update(productId, request, userId);

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
        var user = buildUser();
        var product = buildProduct(user);

        when(preferenceService.isFeatureEnabled(userId, Feature.SHOP)).thenReturn(true);
        when(productRepository.findById(productId)).thenReturn(Optional.of(product));

        productService.delete(productId, userId);

        verify(productRepository).delete(product);
    }
}
