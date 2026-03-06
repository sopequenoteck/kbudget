package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.DebtRequest;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.dto.response.DebtResponse;
import fr.kksdev.budget.api.enums.Currency;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
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
public class DebtService {

    private final DebtRepository debtRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final CategoryService categoryService;
    private final PreferenceService preferenceService;

    @Transactional
    public DebtResponse create(DebtRequest request, UUID userId) {
        User user = userRepository.getReferenceById(userId);
        Currency currency = request.currency() != null ? request.currency()
                : preferenceService.getOrCreatePreference(userId).getCurrencies().get(0);

        Debt debt = Debt.builder()
                .personne(request.personne())
                .montant(request.montant())
                .sens(request.sens())
                .date(request.date())
                .rembourse(request.rembourse() != null ? request.rembourse() : false)
                .category(resolveCategory(request.categoryId(), userId))
                .currency(currency)
                .user(user)
                .build();

        debt = debtRepository.save(debt);
        log.info("Dette créée: {} pour userId {}", debt.getId(), userId);
        return toResponse(debt);
    }

    public List<DebtResponse> getAllByUser(UUID userId) {
        return debtRepository.findByUserIdOrderByDateDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public List<DebtResponse> getUnpaidByUser(UUID userId) {
        return debtRepository.findByUserIdAndRembourseFalseOrderByDateDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public DebtResponse getById(UUID id, UUID userId) {
        Debt debt = findByIdAndUser(id, userId);
        return toResponse(debt);
    }

    @Transactional
    public DebtResponse update(UUID id, DebtRequest request, UUID userId) {
        Debt debt = findByIdAndUser(id, userId);

        debt.setPersonne(request.personne());
        debt.setMontant(request.montant());
        debt.setSens(request.sens());
        debt.setDate(request.date());
        if (request.rembourse() != null) {
            debt.setRembourse(request.rembourse());
        }
        debt.setCategory(resolveCategory(request.categoryId(), userId));
        if (request.currency() != null) {
            debt.setCurrency(request.currency());
        }

        debt = debtRepository.save(debt);
        log.info("Dette mise à jour: {}", debt.getId());
        return toResponse(debt);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        Debt debt = findByIdAndUser(id, userId);
        debtRepository.delete(debt);
        log.info("Dette supprimée: {}", id);
    }

    private Debt findByIdAndUser(UUID id, UUID userId) {
        return debtRepository.findById(id)
                .filter(d -> d.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Dette non trouvée: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Dette non trouvée");
                });
    }

    private Category resolveCategory(UUID categoryId, UUID userId) {
        if (categoryId == null) {
            return categoryService.findSystemCategoryByNom("Dette", userId);
        }
        return categoryRepository.findById(categoryId)
                .filter(c -> c.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Catégorie non trouvée: id={}, userId={}", categoryId, userId);
                    return new EntityNotFoundException("Catégorie non trouvée");
                });
    }

    private CategoryResponse toCategoryResponse(Category category) {
        if (category == null) {
            return null;
        }
        return new CategoryResponse(
                category.getId(),
                category.getNom(),
                category.getIcone(),
                category.getCouleur(),
                Boolean.TRUE.equals(category.getIsSystem())
        );
    }

    private DebtResponse toResponse(Debt debt) {
        return new DebtResponse(
                debt.getId(),
                debt.getPersonne(),
                debt.getMontant(),
                debt.getSens(),
                debt.getDate(),
                debt.getRembourse(),
                toCategoryResponse(debt.getCategory()),
                debt.getCurrency().name()
        );
    }
}
