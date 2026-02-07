package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.DebtRequest;
import fr.kksdev.budget.api.dto.DebtResponse;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.DebtRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DebtService {

    private final DebtRepository debtRepository;

    public DebtResponse create(DebtRequest request, User user) {
        Debt debt = Debt.builder()
                .personne(request.personne())
                .montant(request.montant())
                .sens(request.sens())
                .date(request.date())
                .rembourse(request.rembourse() != null ? request.rembourse() : false)
                .user(user)
                .build();

        debt = debtRepository.save(debt);
        log.info("Dette créée: {} pour user {}", debt.getId(), user.getEmail());
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

    public DebtResponse update(UUID id, DebtRequest request, UUID userId) {
        Debt debt = findByIdAndUser(id, userId);

        debt.setPersonne(request.personne());
        debt.setMontant(request.montant());
        debt.setSens(request.sens());
        debt.setDate(request.date());
        if (request.rembourse() != null) {
            debt.setRembourse(request.rembourse());
        }

        debt = debtRepository.save(debt);
        log.info("Dette mise à jour: {}", debt.getId());
        return toResponse(debt);
    }

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

    private DebtResponse toResponse(Debt debt) {
        return new DebtResponse(
                debt.getId(),
                debt.getPersonne(),
                debt.getMontant(),
                debt.getSens(),
                debt.getDate(),
                debt.getRembourse()
        );
    }
}
