package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.TransactionRequest;
import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.dto.response.MonthlySummaryResponse;
import fr.kksdev.budget.api.dto.response.TransactionResponse;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Category;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;

    @Transactional
    public TransactionResponse create(TransactionRequest request, UUID userId) {
        Transaction transaction = Transaction.builder()
                .montant(request.montant())
                .libelle(request.libelle())
                .type(request.type())
                .date(request.date())
                .category(resolveCategory(request.categoryId(), userId))
                .note(request.note())
                .user(userRepository.getReferenceById(userId))
                .build();

        transaction = transactionRepository.save(transaction);
        log.info("Transaction créée: {} pour userId {}", transaction.getId(), userId);
        return toResponse(transaction);
    }

    public List<TransactionResponse> getAllByUser(UUID userId) {
        return transactionRepository.findByUserIdOrderByDateDesc(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public TransactionResponse getById(UUID id, UUID userId) {
        Transaction transaction = findByIdAndUser(id, userId);
        return toResponse(transaction);
    }

    @Transactional
    public TransactionResponse update(UUID id, TransactionRequest request, UUID userId) {
        Transaction transaction = findByIdAndUser(id, userId);

        transaction.setMontant(request.montant());
        transaction.setLibelle(request.libelle());
        transaction.setType(request.type());
        transaction.setDate(request.date());
        transaction.setCategory(resolveCategory(request.categoryId(), userId));
        transaction.setNote(request.note());

        transaction = transactionRepository.save(transaction);
        log.info("Transaction mise à jour: {}", transaction.getId());
        return toResponse(transaction);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        Transaction transaction = findByIdAndUser(id, userId);
        transactionRepository.delete(transaction);
        log.info("Transaction supprimée: {}", id);
    }

    public MonthlySummaryResponse getMonthlySummary(int month, int year, UUID userId) {
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate from = yearMonth.atDay(1);
        LocalDate to = yearMonth.atEndOfMonth();

        List<Transaction> transactions = transactionRepository
                .findByUserIdAndDateBetweenOrderByDateDesc(userId, from, to);

        BigDecimal totalRecettes = transactions.stream()
                .filter(t -> t.getType() == TransactionType.RECETTE)
                .map(Transaction::getMontant)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalDepenses = transactions.stream()
                .filter(t -> t.getType() == TransactionType.DEPENSE)
                .map(Transaction::getMontant)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        log.info("Bilan mensuel {}/{} pour userId={}: recettes={}, dépenses={}",
                month, year, userId, totalRecettes, totalDepenses);

        return new MonthlySummaryResponse(month, year, totalRecettes, totalDepenses,
                totalRecettes.subtract(totalDepenses));
    }

    private Transaction findByIdAndUser(UUID id, UUID userId) {
        return transactionRepository.findById(id)
                .filter(t -> t.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Transaction non trouvée: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Transaction non trouvée");
                });
    }

    private Category resolveCategory(UUID categoryId, UUID userId) {
        if (categoryId == null) {
            return null;
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

    private TransactionResponse toResponse(Transaction transaction) {
        return new TransactionResponse(
                transaction.getId(),
                transaction.getMontant(),
                transaction.getLibelle(),
                transaction.getType(),
                transaction.getDate(),
                toCategoryResponse(transaction.getCategory()),
                transaction.getNote()
        );
    }
}
