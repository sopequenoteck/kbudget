package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.RestockRequest;
import fr.kksdev.budget.api.dto.response.ProductResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.exception.ConflictException;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.ProductService;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProductController.class)
@Import(SecurityConfig.class)
class ProductSalesIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private ProductService productService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    private static final String BEARER_TOKEN = "Bearer test-token";
    private final UUID userId = UUID.randomUUID();
    private final UUID productId = UUID.randomUUID();
    private final LocalDateTime now = LocalDateTime.now();

    @BeforeEach
    void setUp() {
        var testUser = User.builder().id(userId).email("test@mail.com").name("Test").build();
        when(jwtUtil.isTokenValid("test-token")).thenReturn(true);
        when(jwtUtil.extractEmail("test-token")).thenReturn("test@mail.com");
        when(userRepository.findByEmail("test@mail.com")).thenReturn(Optional.of(testUser));
    }

    private ProductResponse buildProductResponse(int stock, int totalVendu) {
        return new ProductResponse(
                productId, "Bracelet", "Description", "📿", null,
                new BigDecimal("8.00"), new BigDecimal("15.00"),
                stock, totalVendu, true, now, now
        );
    }

    // === POST /products/{id}/sell ===

    @Test
    void should_sell_product_when_stock_available() throws Exception {
        when(productService.sell(productId, userId)).thenReturn(buildProductResponse(4, 6));

        mockMvc.perform(post("/products/{id}/sell", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.stock").value(4))
                .andExpect(jsonPath("$.totalVendu").value(6));
    }

    @Test
    void should_return_409_when_stock_is_zero() throws Exception {
        when(productService.sell(productId, userId))
                .thenThrow(new ConflictException("Stock insuffisant pour le produit Bracelet"));

        mockMvc.perform(post("/products/{id}/sell", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Stock insuffisant pour le produit Bracelet"));
    }

    @Test
    void should_return_409_when_product_inactive_sell() throws Exception {
        when(productService.sell(productId, userId))
                .thenThrow(new ConflictException("Le produit Bracelet est inactif"));

        mockMvc.perform(post("/products/{id}/sell", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Le produit Bracelet est inactif"));
    }

    @Test
    void should_return_404_when_product_not_found_on_sell() throws Exception {
        var randomId = UUID.randomUUID();
        when(productService.sell(randomId, userId))
                .thenThrow(new EntityNotFoundException("Produit non trouvé"));

        mockMvc.perform(post("/products/{id}/sell", randomId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Produit non trouvé"));
    }

    @Test
    void should_return_403_when_shop_feature_disabled_on_sell() throws Exception {
        when(productService.sell(productId, userId))
                .thenThrow(new FeatureDisabledException("SHOP"));

        mockMvc.perform(post("/products/{id}/sell", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Fonctionnalité SHOP désactivée"));
    }

    @Test
    void should_return_401_when_no_token_on_sell() throws Exception {
        mockMvc.perform(post("/products/{id}/sell", productId))
                .andExpect(status().isUnauthorized());
    }

    // === POST /products/{id}/restock ===

    @Test
    void should_restock_product_when_active() throws Exception {
        when(productService.restock(eq(productId), any(RestockRequest.class), eq(userId)))
                .thenReturn(buildProductResponse(15, 5));

        mockMvc.perform(post("/products/{id}/restock", productId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"quantity\": 10}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.stock").value(15));
    }

    @Test
    void should_return_400_when_quantity_zero() throws Exception {
        mockMvc.perform(post("/products/{id}/restock", productId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"quantity\": 0}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_quantity_negative() throws Exception {
        mockMvc.perform(post("/products/{id}/restock", productId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"quantity\": -5}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_400_when_quantity_null() throws Exception {
        mockMvc.perform(post("/products/{id}/restock", productId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void should_return_409_when_product_inactive_restock() throws Exception {
        when(productService.restock(eq(productId), any(RestockRequest.class), eq(userId)))
                .thenThrow(new ConflictException("Le produit Bracelet est inactif"));

        mockMvc.perform(post("/products/{id}/restock", productId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"quantity\": 5}"))
                .andExpect(status().isConflict());
    }

    @Test
    void should_return_404_when_product_not_found_on_restock() throws Exception {
        var randomId = UUID.randomUUID();
        when(productService.restock(eq(randomId), any(RestockRequest.class), eq(userId)))
                .thenThrow(new EntityNotFoundException("Produit non trouvé"));

        mockMvc.perform(post("/products/{id}/restock", randomId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"quantity\": 5}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void should_return_401_when_no_token_on_restock() throws Exception {
        mockMvc.perform(post("/products/{id}/restock", productId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"quantity\": 5}"))
                .andExpect(status().isUnauthorized());
    }

    // === GET /products/{id}/sales ===

    @Test
    void should_return_sales_history_ordered_by_date_desc() throws Exception {
        var tx1 = new TransactionResponse(
                UUID.randomUUID(), new BigDecimal("15.00"), "Vente: Bracelet",
                TransactionType.RECETTE, LocalDate.of(2026, 2, 28),
                null, null, null, null, productId, "Bracelet"
        );
        var tx2 = new TransactionResponse(
                UUID.randomUUID(), new BigDecimal("15.00"), "Vente: Bracelet",
                TransactionType.RECETTE, LocalDate.of(2026, 2, 27),
                null, null, null, null, productId, "Bracelet"
        );
        when(productService.getSalesHistory(productId, userId)).thenReturn(List.of(tx1, tx2));

        mockMvc.perform(get("/products/{id}/sales", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].type").value("RECETTE"))
                .andExpect(jsonPath("$[0].productId").value(productId.toString()))
                .andExpect(jsonPath("$[0].productName").value("Bracelet"))
                .andExpect(jsonPath("$[0].libelle").value("Vente: Bracelet"));
    }

    @Test
    void should_return_empty_list_when_no_sales() throws Exception {
        when(productService.getSalesHistory(productId, userId)).thenReturn(List.of());

        mockMvc.perform(get("/products/{id}/sales", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void should_return_404_when_product_not_found_on_sales() throws Exception {
        var randomId = UUID.randomUUID();
        when(productService.getSalesHistory(randomId, userId))
                .thenThrow(new EntityNotFoundException("Produit non trouvé"));

        mockMvc.perform(get("/products/{id}/sales", randomId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Produit non trouvé"));
    }

    @Test
    void should_return_404_when_product_belongs_to_other_user() throws Exception {
        when(productService.getSalesHistory(productId, userId))
                .thenThrow(new EntityNotFoundException("Produit non trouvé"));

        mockMvc.perform(get("/products/{id}/sales", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound());
    }

    @Test
    void should_return_403_when_shop_feature_disabled_on_sales() throws Exception {
        when(productService.getSalesHistory(productId, userId))
                .thenThrow(new FeatureDisabledException("SHOP"));

        mockMvc.perform(get("/products/{id}/sales", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Fonctionnalité SHOP désactivée"));
    }

    @Test
    void should_return_401_when_no_token_on_sales() throws Exception {
        mockMvc.perform(get("/products/{id}/sales", productId))
                .andExpect(status().isUnauthorized());
    }
}
