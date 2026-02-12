package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.request.DebtRequest;
import fr.kksdev.budget.api.dto.response.DebtResponse;
import fr.kksdev.budget.api.enums.DebtType;
import fr.kksdev.budget.api.model.Debt;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.CategoryRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import fr.kksdev.budget.api.dto.response.CategoryResponse;
import fr.kksdev.budget.api.model.Category;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DebtServiceTest {

    @Mock
    private DebtRepository debtRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private CategoryService categoryService;

    @InjectMocks
    private DebtService debtService;

    private final UUID userId = UUID.randomUUID();
    private final UUID debtId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").build();
    }

    private Debt buildDebt(User user) {
        return Debt.builder()
                .id(debtId)
                .personne("Alice")
                .montant(new BigDecimal("100.00"))
                .sens(DebtType.EMPRUNT)
                .date(LocalDate.of(2026, 2, 1))
                .rembourse(false)
                .category(null)
                .user(user)
                .build();
    }

    @Test
    void should_create_debt_when_valid_request() {
        var user = buildUser();
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1), null, null);
        var saved = buildDebt(user);

        when(categoryService.findSystemCategoryByNom("Dette", userId)).thenReturn(null);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(debtRepository.save(any(Debt.class))).thenReturn(saved);

        DebtResponse response = debtService.create(request, userId);

        assertThat(response.id()).isEqualTo(debtId);
        assertThat(response.personne()).isEqualTo("Alice");
        assertThat(response.rembourse()).isFalse();
        verify(debtRepository).save(any(Debt.class));
    }

    @Test
    void should_assignSystemCategory_when_noCategoryProvided() {
        var user = buildUser();
        var systemCat = Category.builder()
                .id(UUID.randomUUID())
                .nom("Dette")
                .icone("\uD83D\uDCB0")
                .couleur("#ef4444")
                .isSystem(true)
                .user(user)
                .build();
        var saved = Debt.builder()
                .id(debtId)
                .personne("Alice")
                .montant(new BigDecimal("100.00"))
                .sens(DebtType.EMPRUNT)
                .date(LocalDate.of(2026, 2, 1))
                .rembourse(false)
                .category(systemCat)
                .user(user)
                .build();
        var request = new DebtRequest("Alice", new BigDecimal("100.00"),
                DebtType.EMPRUNT, LocalDate.of(2026, 2, 1), null, null);

        when(categoryService.findSystemCategoryByNom("Dette", userId)).thenReturn(systemCat);
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(debtRepository.save(any(Debt.class))).thenReturn(saved);

        DebtResponse response = debtService.create(request, userId);

        assertThat(response.category()).isNotNull();
        assertThat(response.category().nom()).isEqualTo("Dette");
        assertThat(response.category().isSystem()).isTrue();
    }

    @Test
    void should_return_all_debts_when_user_has_debts() {
        var user = buildUser();
        when(debtRepository.findByUserIdOrderByDateDesc(userId))
                .thenReturn(List.of(buildDebt(user)));

        List<DebtResponse> result = debtService.getAllByUser(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().personne()).isEqualTo("Alice");
    }

    @Test
    void should_return_only_unpaid_debts() {
        var user = buildUser();
        when(debtRepository.findByUserIdAndRembourseFalseOrderByDateDesc(userId))
                .thenReturn(List.of(buildDebt(user)));

        List<DebtResponse> result = debtService.getUnpaidByUser(userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().rembourse()).isFalse();
    }

    @Test
    void should_return_debt_when_found_and_owned() {
        var user = buildUser();
        when(debtRepository.findById(debtId)).thenReturn(Optional.of(buildDebt(user)));

        DebtResponse response = debtService.getById(debtId, userId);

        assertThat(response.id()).isEqualTo(debtId);
    }

    @Test
    void should_throw_when_debt_not_found() {
        when(debtRepository.findById(debtId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> debtService.getById(debtId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Dette non trouvée");
    }

    @Test
    void should_throw_when_debt_belongs_to_other_user() {
        var otherUser = User.builder().id(UUID.randomUUID()).email("other@mail.com").build();
        when(debtRepository.findById(debtId)).thenReturn(Optional.of(buildDebt(otherUser)));

        assertThatThrownBy(() -> debtService.getById(debtId, userId))
                .isInstanceOf(EntityNotFoundException.class);
    }

    @Test
    void should_update_debt_when_valid() {
        var user = buildUser();
        var existing = buildDebt(user);
        var request = new DebtRequest("Bob", new BigDecimal("200.00"),
                DebtType.PRET, LocalDate.of(2026, 2, 5), true, null);

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(existing));
        when(debtRepository.save(any(Debt.class))).thenReturn(existing);

        DebtResponse response = debtService.update(debtId, request, userId);

        assertThat(response).isNotNull();
        verify(debtRepository).save(existing);
    }

    @Test
    void should_delete_debt_when_found_and_owned() {
        var user = buildUser();
        var debt = buildDebt(user);

        when(debtRepository.findById(debtId)).thenReturn(Optional.of(debt));

        debtService.delete(debtId, userId);

        verify(debtRepository).delete(debt);
    }
}
