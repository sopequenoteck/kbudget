package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CategoryRequest;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.CategoryRepository;
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
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;

    @Transactional
    public CategoryResponse create(CategoryRequest request, UUID userId) {
        if (categoryRepository.existsByNomIgnoreCaseAndUserId(request.nom(), userId)) {
            throw new IllegalArgumentException("Une catégorie avec ce nom existe déjà");
        }

        Category category = Category.builder()
                .nom(request.nom())
                .icone(request.icone())
                .couleur(request.couleur())
                .user(userRepository.getReferenceById(userId))
                .build();

        category = categoryRepository.save(category);
        log.info("Catégorie créée: {} pour userId {}", category.getId(), userId);
        return toResponse(category);
    }

    public List<CategoryResponse> getAllByUser(UUID userId) {
        return categoryRepository.findByUserIdOrderByNomAsc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public CategoryResponse getById(UUID id, UUID userId) {
        Category category = findByIdAndUser(id, userId);
        return toResponse(category);
    }

    @Transactional
    public CategoryResponse update(UUID id, CategoryRequest request, UUID userId) {
        Category category = findByIdAndUser(id, userId);

        if (Boolean.TRUE.equals(category.getIsSystem())) {
            log.warn("Tentative de modification d'une catégorie système: id={}, userId={}", id, userId);
            throw new IllegalArgumentException("Les catégories système ne peuvent pas être modifiées");
        }

        if (categoryRepository.existsByNomIgnoreCaseAndUserIdAndIdNot(request.nom(), userId, id)) {
            throw new IllegalArgumentException("Une catégorie avec ce nom existe déjà");
        }

        category.setNom(request.nom());
        category.setIcone(request.icone());
        category.setCouleur(request.couleur());

        category = categoryRepository.save(category);
        log.info("Catégorie mise à jour: {}", category.getId());
        return toResponse(category);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        Category category = findByIdAndUser(id, userId);

        if (Boolean.TRUE.equals(category.getIsSystem())) {
            log.warn("Tentative de suppression d'une catégorie système: id={}, userId={}", id, userId);
            throw new IllegalArgumentException("Les catégories système ne peuvent pas être supprimées");
        }

        categoryRepository.delete(category);
        log.info("Catégorie supprimée: {}", id);
    }

    @Transactional
    public void seedSystemCategories(User user) {
        try {
            Category abonnement = Category.builder()
                    .nom("Abonnement")
                    .icone("\uD83D\uDD04")
                    .couleur("#6366f1")
                    .isSystem(true)
                    .user(user)
                    .build();
            categoryRepository.save(abonnement);

            Category dette = Category.builder()
                    .nom("Dette")
                    .icone("\uD83D\uDCB0")
                    .couleur("#ef4444")
                    .isSystem(true)
                    .user(user)
                    .build();
            categoryRepository.save(dette);

            Category virement = Category.builder()
                    .nom("Virement")
                    .icone("\uD83D\uDD04")
                    .couleur("#8b5cf6")
                    .isSystem(true)
                    .user(user)
                    .build();
            categoryRepository.save(virement);

            Category boutique = Category.builder()
                    .nom("Boutique")
                    .icone("🛍️")
                    .couleur("#f59e0b")
                    .isSystem(true)
                    .user(user)
                    .build();
            categoryRepository.save(boutique);

            log.info("Catégories système créées pour userId {}", user.getId());
        } catch (Exception e) {
            log.error("Échec du seeding des catégories système pour userId {}: {}", user.getId(), e.getMessage());
            throw e;
        }
    }

    @Transactional
    public Category findOrCreateAdjustmentCategory(UUID userId) {
        Category existing = findSystemCategoryByNom("Ajustement", userId);
        if (existing != null) {
            return existing;
        }

        Category ajustement = Category.builder()
                .nom("Ajustement")
                .icone("⚖️")
                .couleur("#6b7280")
                .isSystem(true)
                .user(userRepository.getReferenceById(userId))
                .build();
        ajustement = categoryRepository.save(ajustement);
        log.info("Catégorie système 'Ajustement' créée pour userId {}", userId);
        return ajustement;
    }

    @Transactional
    public Category findOrCreateShopCategory(UUID userId) {
        Category existing = findSystemCategoryByNom("Boutique", userId);
        if (existing != null) {
            return existing;
        }

        Category boutique = Category.builder()
                .nom("Boutique")
                .icone("🛍️")
                .couleur("#f59e0b")
                .isSystem(true)
                .user(userRepository.getReferenceById(userId))
                .build();
        boutique = categoryRepository.save(boutique);
        log.info("Catégorie système 'Boutique' créée pour userId {}", userId);
        return boutique;
    }

    public Category findSystemCategoryByNom(String nom, UUID userId) {
        return categoryRepository.findByNomIgnoreCaseAndUserId(nom, userId)
                .filter(c -> Boolean.TRUE.equals(c.getIsSystem()))
                .orElse(null);
    }

    private Category findByIdAndUser(UUID id, UUID userId) {
        return categoryRepository.findById(id)
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Catégorie non trouvée: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Catégorie non trouvée");
                });
    }

    private CategoryResponse toResponse(Category category) {
        return new CategoryResponse(
                category.getId(),
                category.getNom(),
                category.getIcone(),
                category.getCouleur(),
                Boolean.TRUE.equals(category.getIsSystem())
        );
    }
}
