package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.TransactionRequest;
import fr.kksdev.budget.api.dto.TransactionResponse;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.TransactionRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;

    public TransactionResponse create(TransactionRequest request, User user) {
        Transaction transaction = Transaction.builder()
                .montant(request.montant())
                .libelle(request.libelle())
                .type(request.type())
                .date(request.date())
                .categorie(request.categorie())
                .note(request.note())
                .user(user)
                .build();

        transaction = transactionRepository.save(transaction);
        log.info("Transaction créée: {} pour user {}", transaction.getId(), user.getEmail());
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

    public TransactionResponse update(UUID id, TransactionRequest request, UUID userId) {
        Transaction transaction = findByIdAndUser(id, userId);

        transaction.setMontant(request.montant());
        transaction.setLibelle(request.libelle());
        transaction.setType(request.type());
        transaction.setDate(request.date());
        transaction.setCategorie(request.categorie());
        transaction.setNote(request.note());

        transaction = transactionRepository.save(transaction);
        log.info("Transaction mise à jour: {}", transaction.getId());
        return toResponse(transaction);
    }

    public void delete(UUID id, UUID userId) {
        Transaction transaction = findByIdAndUser(id, userId);
        transactionRepository.delete(transaction);
        log.info("Transaction supprimée: {}", id);
    }

    private Transaction findByIdAndUser(UUID id, UUID userId) {
        return transactionRepository.findById(id)
                .filter(t -> t.getUser().getId().equals(userId))
                .orElseThrow(() -> {
                    log.error("Transaction non trouvée: id={}, userId={}", id, userId);
                    return new EntityNotFoundException("Transaction non trouvée");
                });
    }

    private TransactionResponse toResponse(Transaction transaction) {
        return new TransactionResponse(
                transaction.getId(),
                transaction.getMontant(),
                transaction.getLibelle(),
                transaction.getType(),
                transaction.getDate(),
                transaction.getCategorie(),
                transaction.getNote()
        );
    }
}
