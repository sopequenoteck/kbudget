package fr.kksdev.budget.api.service;

import fr.kksdev.budget.api.dto.response.SubscriptionPaymentResponse;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.enums.Frequency;
import fr.kksdev.budget.api.enums.TransactionType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Subscription;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.SubscriptionRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SubscriptionPaymentServiceTest {

    @Mock
    private SubscriptionRepository subscriptionRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private BudgetService budgetService;

    @InjectMocks
    private SubscriptionPaymentService subscriptionPaymentService;

    private final UUID userId = UUID.randomUUID();
    private final UUID subscriptionId = UUID.randomUUID();
    private final UUID accountId = UUID.randomUUID();
    private final UUID transactionId = UUID.randomUUID();

    private User buildUser() {
        return User.builder().id(userId).email("test@mail.com").build();
    }

    private Account buildAccount() {
        return Account.builder()
                .id(accountId)
                .nom("Compte Principal")
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#3b82f6")
                .isDefault(true)
                .actif(true)
                .user(buildUser())
                .build();
    }

    private Subscription buildActiveMonthlySubscription(Account account) {
        return Subscription.builder()
                .id(subscriptionId)
                .nom("Netflix")
                .montant(new BigDecimal("13.99"))
                .frequence(Frequency.MENSUEL)
                .dateDebut(LocalDate.of(2026, 1, 1))
                .actif(true)
                .account(account)
                .user(buildUser())
                .build();
    }

    private Transaction buildSavedTransaction(Subscription sub, Account account) {
        return Transaction.builder()
                .id(transactionId)
                .montant(sub.getMontant())
                .libelle(sub.getNom())
                .type(TransactionType.DEPENSE)
                .date(LocalDate.now())
                .account(account)
                .subscription(sub)
                .user(buildUser())
                .build();
    }

    @Test
    void should_createTransaction_when_payMonthlySubscription() {
        var account = buildAccount();
        var sub = buildActiveMonthlySubscription(account);
        var saved = buildSavedTransaction(sub, account);

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(sub));
        when(userRepository.getReferenceById(userId)).thenReturn(buildUser());
        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        SubscriptionPaymentResponse response = subscriptionPaymentService.pay(subscriptionId, userId);

        assertThat(response.id()).isEqualTo(transactionId);
        assertThat(response.montant()).isEqualByComparingTo("13.99");
        assertThat(response.subscriptionName()).isEqualTo("Netflix");
        assertThat(response.accountName()).isEqualTo("Compte Principal");

        ArgumentCaptor<Transaction> captor = ArgumentCaptor.forClass(Transaction.class);
        verify(transactionRepository).save(captor.capture());
        assertThat(captor.getValue().getType()).isEqualTo(TransactionType.DEPENSE);
        assertThat(captor.getValue().getLibelle()).isEqualTo("Netflix");
        assertThat(captor.getValue().getMontant()).isEqualByComparingTo("13.99");
        assertThat(captor.getValue().getSubscription()).isEqualTo(sub);
    }

    @Test
    void should_createTransaction_when_payAnnualSubscription() {
        var account = buildAccount();
        var sub = Subscription.builder()
                .id(subscriptionId)
                .nom("iCloud+")
                .montant(new BigDecimal("28.99"))
                .frequence(Frequency.ANNUEL)
                .dateDebut(LocalDate.of(2026, 1, 1))
                .actif(true)
                .account(account)
                .user(buildUser())
                .build();
        var saved = buildSavedTransaction(sub, account);

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(sub));
        when(userRepository.getReferenceById(userId)).thenReturn(buildUser());
        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        SubscriptionPaymentResponse response = subscriptionPaymentService.pay(subscriptionId, userId);

        assertThat(response.montant()).isEqualByComparingTo("28.99");
        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void should_notModifyDateDebut_when_pay() {
        var account = buildAccount();
        var sub = buildActiveMonthlySubscription(account);
        LocalDate dateBefore = sub.getDateDebut();
        var saved = buildSavedTransaction(sub, account);

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(sub));
        when(userRepository.getReferenceById(userId)).thenReturn(buildUser());
        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        subscriptionPaymentService.pay(subscriptionId, userId);

        assertThat(sub.getDateDebut()).isEqualTo(dateBefore);
    }

    @Test
    void should_useSubscriptionAccount_when_accountPresent() {
        var account = buildAccount();
        var sub = buildActiveMonthlySubscription(account);
        var saved = buildSavedTransaction(sub, account);

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(sub));
        when(userRepository.getReferenceById(userId)).thenReturn(buildUser());
        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        SubscriptionPaymentResponse response = subscriptionPaymentService.pay(subscriptionId, userId);

        assertThat(response.accountName()).isEqualTo("Compte Principal");
        verify(accountRepository, never()).findByUserIdAndIsDefaultTrue(any());
    }

    @Test
    void should_useDefaultAccount_when_subscriptionAccountNull() {
        var user = buildUser();
        var defaultAccount = buildAccount();
        var sub = Subscription.builder()
                .id(subscriptionId)
                .nom("Netflix")
                .montant(new BigDecimal("13.99"))
                .frequence(Frequency.MENSUEL)
                .dateDebut(LocalDate.of(2026, 1, 1))
                .actif(true)
                .account(null)
                .user(user)
                .build();
        var saved = buildSavedTransaction(sub, defaultAccount);

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(sub));
        when(accountRepository.findByUserIdAndIsDefaultTrue(userId)).thenReturn(Optional.of(defaultAccount));
        when(userRepository.getReferenceById(userId)).thenReturn(user);
        when(transactionRepository.save(any(Transaction.class))).thenReturn(saved);

        SubscriptionPaymentResponse response = subscriptionPaymentService.pay(subscriptionId, userId);

        assertThat(response.accountName()).isEqualTo("Compte Principal");
        verify(accountRepository).findByUserIdAndIsDefaultTrue(userId);
    }

    @Test
    void should_throwException_when_subscriptionInactive() {
        var user = buildUser();
        var sub = Subscription.builder()
                .id(subscriptionId)
                .nom("Netflix")
                .montant(new BigDecimal("13.99"))
                .frequence(Frequency.MENSUEL)
                .dateDebut(LocalDate.of(2026, 1, 1))
                .actif(false)
                .user(user)
                .build();

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(sub));

        assertThatThrownBy(() -> subscriptionPaymentService.pay(subscriptionId, userId))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("L'abonnement est inactif");

        verify(transactionRepository, never()).save(any());
    }

    @Test
    void should_throwException_when_subscriptionNotFound() {
        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> subscriptionPaymentService.pay(subscriptionId, userId))
                .isInstanceOf(EntityNotFoundException.class)
                .hasMessage("Abonnement non trouvé");

        verify(transactionRepository, never()).save(any());
    }

    @Test
    void should_returnPayments_when_getPayments() {
        var account = buildAccount();
        var sub = buildActiveMonthlySubscription(account);
        var transaction = buildSavedTransaction(sub, account);

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(sub));
        when(transactionRepository.findBySubscriptionIdAndUserIdOrderByDateDesc(subscriptionId, userId))
                .thenReturn(List.of(transaction));

        List<SubscriptionPaymentResponse> result = subscriptionPaymentService.getPayments(subscriptionId, userId);

        assertThat(result).hasSize(1);
        assertThat(result.getFirst().id()).isEqualTo(transactionId);
        assertThat(result.getFirst().montant()).isEqualByComparingTo("13.99");
        assertThat(result.getFirst().subscriptionName()).isEqualTo("Netflix");
        assertThat(result.getFirst().accountName()).isEqualTo("Compte Principal");
    }

    @Test
    void should_returnZero_when_noPayments() {
        var account = buildAccount();
        var sub = buildActiveMonthlySubscription(account);

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(sub));
        when(transactionRepository.sumBySubscriptionIdAndUserId(subscriptionId, userId))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.countBySubscriptionIdAndUserId(subscriptionId, userId))
                .thenReturn(0L);

        Map<String, Object> result = subscriptionPaymentService.getTotalPaid(subscriptionId, userId);

        assertThat((BigDecimal) result.get("totalPaid")).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat((long) result.get("paymentCount")).isZero();
    }

    @Test
    void should_returnExactTotal_when_getTotalPaid() {
        var account = buildAccount();
        var sub = buildActiveMonthlySubscription(account);

        when(subscriptionRepository.findById(subscriptionId)).thenReturn(Optional.of(sub));
        when(transactionRepository.sumBySubscriptionIdAndUserId(subscriptionId, userId))
                .thenReturn(new BigDecimal("27.98"));
        when(transactionRepository.countBySubscriptionIdAndUserId(subscriptionId, userId))
                .thenReturn(2L);

        Map<String, Object> result = subscriptionPaymentService.getTotalPaid(subscriptionId, userId);

        assertThat(result.get("subscriptionId")).isEqualTo(subscriptionId);
        assertThat(result.get("subscriptionName")).isEqualTo("Netflix");
        assertThat((BigDecimal) result.get("totalPaid")).isEqualByComparingTo("27.98");
        assertThat((long) result.get("paymentCount")).isEqualTo(2L);
    }
}
