package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.ProductRequest;
import fr.kksdev.budget.api.dto.request.ProductUpdateRequest;
import fr.kksdev.budget.api.dto.response.ProductResponse;
import fr.kksdev.budget.api.enums.Feature;
import fr.kksdev.budget.api.exception.FeatureDisabledException;
import fr.kksdev.budget.api.model.Product;
import fr.kksdev.budget.api.repository.ProductRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ProductService {

    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final PreferenceService preferenceService;

    @Transactional
    public ProductResponse create(ProductRequest request, UUID userId) {
        checkShopEnabled(userId);
        Product product = Product.builder()
                .nom(request.nom())
                .description(request.description())
                .icone(request.icone())
                .imageUrl(request.imageUrl())
                .prixAchat(request.prixAchat())
                .prixVente(request.prixVente())
                .stock(request.stock())
                .actif(true)
                .totalVendu(0)
                .user(userRepository.getReferenceById(userId))
                .build();
        product = productRepository.save(product);
        log.info("Produit créé: {} pour userId {}", product.getId(), userId);
        return toResponse(product);
    }

    public List<ProductResponse> getAllByUser(UUID userId) {
        checkShopEnabled(userId);
        return productRepository.findByUserIdAndActifTrueOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public ProductResponse getById(UUID id, UUID userId) {
        checkShopEnabled(userId);
        Product product = findByIdAndUser(id, userId);
        return toResponse(product);
    }

    @Transactional
    public ProductResponse update(UUID id, ProductUpdateRequest request, UUID userId) {
        checkShopEnabled(userId);
        Product product = findByIdAndUser(id, userId);
        product.setNom(request.nom());
        product.setDescription(request.description());
        product.setIcone(request.icone());
        product.setImageUrl(request.imageUrl());
        product.setPrixAchat(request.prixAchat());
        product.setPrixVente(request.prixVente());
        product.setStock(request.stock());
        product.setActif(request.actif());
        product = productRepository.save(product);
        log.info("Produit mis à jour: {}", id);
        return toResponse(product);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        checkShopEnabled(userId);
        Product product = findByIdAndUser(id, userId);
        productRepository.delete(product);
        log.info("Produit supprimé: {}", id);
    }

    private void checkShopEnabled(UUID userId) {
        if (!preferenceService.isFeatureEnabled(userId, Feature.SHOP)) {
            throw new FeatureDisabledException("SHOP");
        }
    }

    private Product findByIdAndUser(UUID id, UUID userId) {
        return productRepository.findById(id)
                .filter(p -> p.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Produit non trouvé: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Produit non trouvé");
                });
    }

    private ProductResponse toResponse(Product product) {
        return new ProductResponse(
                product.getId(),
                product.getNom(),
                product.getDescription(),
                product.getIcone(),
                product.getImageUrl(),
                product.getPrixAchat(),
                product.getPrixVente(),
                product.getStock(),
                product.getTotalVendu(),
                product.getActif(),
                product.getCreatedAt(),
                product.getUpdatedAt()
        );
    }
}
