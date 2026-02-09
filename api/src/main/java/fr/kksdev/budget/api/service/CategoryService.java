package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.CategoryRequest;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;

    public CategoryResponse create(CategoryRequest request, UUID userId) {
        if (categoryRepository.existsByNomAndUserId(request.nom(), userId)) {
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

    public CategoryResponse update(UUID id, CategoryRequest request, UUID userId) {
        Category category = findByIdAndUser(id, userId);

        if (categoryRepository.existsByNomAndUserIdAndIdNot(request.nom(), userId, id)) {
            throw new IllegalArgumentException("Une catégorie avec ce nom existe déjà");
        }

        category.setNom(request.nom());
        category.setIcone(request.icone());
        category.setCouleur(request.couleur());

        category = categoryRepository.save(category);
        log.info("Catégorie mise à jour: {}", category.getId());
        return toResponse(category);
    }

    public void delete(UUID id, UUID userId) {
        Category category = findByIdAndUser(id, userId);
        categoryRepository.delete(category);
        log.info("Catégorie supprimée: {}", id);
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
                category.getCouleur()
        );
    }
}
