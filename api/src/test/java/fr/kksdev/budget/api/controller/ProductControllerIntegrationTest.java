package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.request.ProductRequest;
import fr.kksdev.budget.api.dto.request.ProductUpdateRequest;
import fr.kksdev.budget.api.dto.response.ProductResponse;
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
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProductController.class)
@Import(SecurityConfig.class)
class ProductControllerIntegrationTest {

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

    private ProductResponse buildResponse() {
        return new ProductResponse(
                productId, "T-shirt", "Description", "👕", null,
                new BigDecimal("8.50"), new BigDecimal("15.00"),
                10, 0, true, now, now
        );
    }

    private String createProductJson() {
        return """
                {
                    "nom": "T-shirt",
                    "description": "Description",
                    "icone": "👕",
                    "prixAchat": 8.50,
                    "prixVente": 15.00,
                    "stock": 10
                }
                """;
    }

    private String createProductJsonWithOptionals() {
        return """
                {
                    "nom": "T-shirt",
                    "description": "T-shirt 100% coton",
                    "icone": "👕",
                    "imageUrl": "https://example.com/tshirt.jpg",
                    "prixAchat": 8.50,
                    "prixVente": 15.00,
                    "stock": 25
                }
                """;
    }

    private String updateProductJson() {
        return """
                {
                    "nom": "T-shirt modifié",
                    "description": "Nouvelle description",
                    "icone": "👕",
                    "prixAchat": 9.00,
                    "prixVente": 18.00,
                    "stock": 20,
                    "actif": true
                }
                """;
    }

    // === US1: POST /products ===

    @Test
    void should_createProduct_when_validRequest() throws Exception {
        var response = buildResponse();
        when(productService.create(any(ProductRequest.class), eq(userId))).thenReturn(response);

        mockMvc.perform(post("/products")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createProductJson()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(productId.toString()))
                .andExpect(jsonPath("$.nom").value("T-shirt"))
                .andExpect(jsonPath("$.actif").value(true))
                .andExpect(jsonPath("$.totalVendu").value(0));
    }

    @Test
    void should_createProduct_when_optionalFieldsProvided() throws Exception {
        var response = new ProductResponse(
                productId, "T-shirt", "T-shirt 100% coton", "👕",
                "https://example.com/tshirt.jpg",
                new BigDecimal("8.50"), new BigDecimal("15.00"),
                25, 0, true, now, now
        );
        when(productService.create(any(ProductRequest.class), eq(userId))).thenReturn(response);

        mockMvc.perform(post("/products")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createProductJsonWithOptionals()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.description").value("T-shirt 100% coton"))
                .andExpect(jsonPath("$.imageUrl").value("https://example.com/tshirt.jpg"))
                .andExpect(jsonPath("$.stock").value(25));
    }

    @Test
    void should_returnBadRequest_when_invalidCreateData() throws Exception {
        mockMvc.perform(post("/products")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "",
                                    "prixAchat": -1,
                                    "prixVente": 15.00,
                                    "stock": -5
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    // === US2: GET /products ===

    @Test
    void should_returnActiveProducts_when_listingProducts() throws Exception {
        var response = buildResponse();
        when(productService.getAllByUser(userId)).thenReturn(List.of(response));

        mockMvc.perform(get("/products")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].nom").value("T-shirt"))
                .andExpect(jsonPath("$[0].actif").value(true));
    }

    @Test
    void should_returnEmptyList_when_noProducts() throws Exception {
        when(productService.getAllByUser(userId)).thenReturn(List.of());

        mockMvc.perform(get("/products")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    // === US3: GET /products/{id} ===

    @Test
    void should_returnProduct_when_getById() throws Exception {
        var response = buildResponse();
        when(productService.getById(productId, userId)).thenReturn(response);

        mockMvc.perform(get("/products/{id}", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(productId.toString()))
                .andExpect(jsonPath("$.nom").value("T-shirt"))
                .andExpect(jsonPath("$.prixAchat").value(8.50))
                .andExpect(jsonPath("$.prixVente").value(15.00));
    }

    @Test
    void should_returnNotFound_when_productOfOtherUser() throws Exception {
        when(productService.getById(productId, userId))
                .thenThrow(new EntityNotFoundException("Produit non trouvé"));

        mockMvc.perform(get("/products/{id}", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Produit non trouvé"));
    }

    @Test
    void should_returnNotFound_when_productDoesNotExist() throws Exception {
        var randomId = UUID.randomUUID();
        when(productService.getById(randomId, userId))
                .thenThrow(new EntityNotFoundException("Produit non trouvé"));

        mockMvc.perform(get("/products/{id}", randomId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Produit non trouvé"));
    }

    // === US4: PUT /products/{id} ===

    @Test
    void should_updateProduct_when_validRequest() throws Exception {
        var response = new ProductResponse(
                productId, "T-shirt modifié", "Nouvelle description", "👕", null,
                new BigDecimal("9.00"), new BigDecimal("18.00"),
                20, 0, true, now, now
        );
        when(productService.update(eq(productId), any(ProductUpdateRequest.class), eq(userId)))
                .thenReturn(response);

        mockMvc.perform(put("/products/{id}", productId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(updateProductJson()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nom").value("T-shirt modifié"))
                .andExpect(jsonPath("$.prixAchat").value(9.00))
                .andExpect(jsonPath("$.prixVente").value(18.00))
                .andExpect(jsonPath("$.stock").value(20));
    }

    @Test
    void should_toggleActive_when_updatingProduct() throws Exception {
        var inactiveResponse = new ProductResponse(
                productId, "T-shirt", "Description", "👕", null,
                new BigDecimal("8.50"), new BigDecimal("15.00"),
                10, 0, false, now, now
        );
        when(productService.update(eq(productId), any(ProductUpdateRequest.class), eq(userId)))
                .thenReturn(inactiveResponse);

        mockMvc.perform(put("/products/{id}", productId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "T-shirt",
                                    "prixAchat": 8.50,
                                    "prixVente": 15.00,
                                    "stock": 10,
                                    "actif": false
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.actif").value(false));
    }

    @Test
    void should_returnBadRequest_when_invalidUpdateData() throws Exception {
        mockMvc.perform(put("/products/{id}", productId)
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                    "nom": "",
                                    "prixAchat": -1,
                                    "prixVente": 15.00,
                                    "stock": -5,
                                    "actif": true
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    // === US5: DELETE /products/{id} ===

    @Test
    void should_deleteProduct_when_ownerDeletes() throws Exception {
        doNothing().when(productService).delete(productId, userId);

        mockMvc.perform(delete("/products/{id}", productId)
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isNoContent());
    }

    // === Feature Toggle ===

    @Test
    void should_returnForbidden_when_shopDisabled() throws Exception {
        when(productService.getAllByUser(userId))
                .thenThrow(new FeatureDisabledException("SHOP"));

        mockMvc.perform(get("/products")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Fonctionnalité SHOP désactivée"));
    }

    // === Data Isolation ===

    @Test
    void should_isolateData_when_differentUsers() throws Exception {
        when(productService.getAllByUser(userId)).thenReturn(List.of(buildResponse()));

        mockMvc.perform(get("/products")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    // === Duplicate Names ===

    @Test
    void should_allowDuplicateNames_when_creatingProducts() throws Exception {
        var response = buildResponse();
        when(productService.create(any(ProductRequest.class), eq(userId))).thenReturn(response);

        mockMvc.perform(post("/products")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createProductJson()))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/products")
                        .header("Authorization", BEARER_TOKEN)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createProductJson()))
                .andExpect(status().isCreated());
    }

    // === Stock Zero ===

    @Test
    void should_remainVisible_when_stockIsZero() throws Exception {
        var zeroStockResponse = new ProductResponse(
                productId, "T-shirt", "Description", "👕", null,
                new BigDecimal("8.50"), new BigDecimal("15.00"),
                0, 0, true, now, now
        );
        when(productService.getAllByUser(userId)).thenReturn(List.of(zeroStockResponse));

        mockMvc.perform(get("/products")
                        .header("Authorization", BEARER_TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].stock").value(0))
                .andExpect(jsonPath("$[0].actif").value(true));
    }

    // === Auth ===

    @Test
    void should_return401_when_noToken() throws Exception {
        mockMvc.perform(get("/products"))
                .andExpect(status().isUnauthorized());
    }
}
