package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CategoryRequest;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.enums.SystemCategoryKey;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CategoryService {

    // KKS-396 : noms anglais des categories systeme, ecrits par l'API a la
    // creation de l'utilisateur (principe VII, l'API ne traduit jamais).
    private static final String SUBSCRIPTION_CATEGORY_NAME = "Subscription";
    private static final String DEBT_CATEGORY_NAME = "Debt";
    private static final String TRANSFER_CATEGORY_NAME = "Transfer";
    private static final String ADJUSTMENT_CATEGORY_NAME = "Balance adjustment";

    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;

    @Transactional
    public CategoryResponse create(CategoryRequest request, UUID userId) {
        if (categoryRepository.existsByNomIgnoreCaseAndUserId(request.nom(), userId)) {
            throw new IllegalArgumentException("A category with this name already exists");
        }

        Category category = Category.builder()
                .nom(request.nom())
                .icone(request.icone())
                .couleur(request.couleur())
                .user(userRepository.getReferenceById(userId))
                .build();

        category = categoryRepository.save(category);
        log.info("Category created (categoryId={}, userId={})", category.getId(), userId);
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
            log.warn("Attempt to modify a system category (id={}, userId={})", id, userId);
            throw new IllegalArgumentException("System categories cannot be updated");
        }

        if (categoryRepository.existsByNomIgnoreCaseAndUserIdAndIdNot(request.nom(), userId, id)) {
            throw new IllegalArgumentException("A category with this name already exists");
        }

        category.setNom(request.nom());
        category.setIcone(request.icone());
        category.setCouleur(request.couleur());

        category = categoryRepository.save(category);
        log.info("Category updated (categoryId={})", category.getId());
        return toResponse(category);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        Category category = findByIdAndUser(id, userId);

        if (Boolean.TRUE.equals(category.getIsSystem())) {
            log.warn("Attempt to delete a system category (id={}, userId={})", id, userId);
            throw new IllegalArgumentException("System categories cannot be deleted");
        }

        categoryRepository.delete(category);
        log.info("Category deleted (categoryId={})", id);
    }

    @Transactional
    public void seedSystemCategories(User user) {
        try {
            Category abonnement = Category.builder()
                    .nom(SUBSCRIPTION_CATEGORY_NAME)
                    .icone("\uD83D\uDD04")
                    .couleur("#6366f1")
                    .isSystem(true)
                    .systemKey(SystemCategoryKey.SUBSCRIPTION)
                    .user(user)
                    .build();
            categoryRepository.save(abonnement);

            Category dette = Category.builder()
                    .nom(DEBT_CATEGORY_NAME)
                    .icone("\uD83D\uDCB0")
                    .couleur("#ef4444")
                    .isSystem(true)
                    .systemKey(SystemCategoryKey.DEBT)
                    .user(user)
                    .build();
            categoryRepository.save(dette);

            Category virement = Category.builder()
                    .nom(TRANSFER_CATEGORY_NAME)
                    .icone("\uD83D\uDD04")
                    .couleur("#8b5cf6")
                    .isSystem(true)
                    .systemKey(SystemCategoryKey.TRANSFER)
                    .user(user)
                    .build();
            categoryRepository.save(virement);

            log.info("System categories created (userId={})", user.getId());
        } catch (Exception e) {
            log.error("System categories seeding failed (userId={}): {}", user.getId(), e.getMessage());
            throw e;
        }
    }

    @Transactional
    public Category findOrCreateAdjustmentCategory(UUID userId) {
        Category existing = findSystemCategory(SystemCategoryKey.ADJUSTMENT, userId);
        if (existing != null) {
            return existing;
        }

        Category ajustement = Category.builder()
                .nom(ADJUSTMENT_CATEGORY_NAME)
                .icone("⚖️")
                .couleur("#6b7280")
                .isSystem(true)
                .systemKey(SystemCategoryKey.ADJUSTMENT)
                .user(userRepository.getReferenceById(userId))
                .build();
        ajustement = categoryRepository.save(ajustement);
        log.info("Adjustment system category created (userId={})", userId);
        return ajustement;
    }

    public List<CategoryResponse> getMostUsed(UUID userId, int days, int limit) {
        LocalDate since = LocalDate.now().minusDays(days);
        List<Object[]> rows = transactionRepository.findMostUsedCategories(userId, since, limit);
        return rows.stream()
                .map(row -> new CategoryResponse(
                        (UUID) row[0],
                        (String) row[1],
                        (String) row[2],
                        (String) row[3],
                        (Boolean) row[4],
                        (String) row[6]
                ))
                .toList();
    }

    public Category findSystemCategory(SystemCategoryKey key, UUID userId) {
        return categoryRepository.findByUserIdAndSystemKey(userId, key)
                .orElse(null);
    }

    private Category findByIdAndUser(UUID id, UUID userId) {
        return categoryRepository.findById(id)
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Category not found (id={}, userId={})", id, userId);
                    return new EntityNotFoundException("Category not found");
                });
    }

    private CategoryResponse toResponse(Category category) {
        return new CategoryResponse(
                category.getId(),
                category.getNom(),
                category.getIcone(),
                category.getCouleur(),
                Boolean.TRUE.equals(category.getIsSystem()),
                SystemCategoryKey.nameOf(category.getSystemKey())
        );
    }
}
