package fr.kksdev.budget.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.enums.AccountType;
import fr.kksdev.budget.api.model.Account;
import fr.kksdev.budget.api.model.Transaction;
import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.AccountRepository;
import fr.kksdev.budget.api.repository.DebtRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import fr.kksdev.budget.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Deleting a debt over HTTP (KKS-427): its payments stay, unlinked and with the
 * label they had, instead of receiving a French suffix written by the API.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class DebtControllerIT {

    private static final String DEBT_BODY = """
            {"personne":"Alice","montant":100.00,"sens":"EMPRUNT","date":"2026-09-01"}""";

    @Autowired MockMvc mockMvc;
    @Autowired UserRepository userRepository;
    @Autowired AccountRepository accountRepository;
    @Autowired TransactionRepository transactionRepository;
    @Autowired DebtRepository debtRepository;
    @Autowired JwtUtil jwtUtil;

    private User user;
    private Account account;

    @BeforeEach
    void setUp() {
        user = userRepository.save(User.builder()
                .email("debt-" + UUID.randomUUID() + "@example.com")
                .password("unused")
                .name("Debt")
                .passwordResetRequired(false)
                .build());
        account = accountRepository.save(Account.builder()
                .nom("Compte " + UUID.randomUUID().toString().substring(0, 8))
                .type(AccountType.COURANT)
                .soldeInitial(BigDecimal.ZERO)
                .icone("🏦")
                .couleur("#000000")
                .user(user)
                .build());
    }

    @Test
    void should_keep_payments_unlinked_and_with_their_label_when_deleting_a_debt() throws Exception {
        String debtId = createDebt();
        UUID paymentId = repay(debtId, "40.00", "\"Virement Alice\"");
        UUID defaultLabelPaymentId = repay(debtId, "10.00", null);

        mockMvc.perform(delete("/v1/debts/" + debtId).header("Authorization", bearer()))
                .andExpect(status().isNoContent());

        assertThat(debtRepository.findById(UUID.fromString(debtId))).isEmpty();
        Transaction payment = transactionRepository.findById(paymentId).orElseThrow();
        assertThat(payment.getLibelle()).isEqualTo("Virement Alice");
        assertThat(payment.getDebt()).isNull();
        Transaction defaultLabelPayment = transactionRepository.findById(defaultLabelPaymentId).orElseThrow();
        assertThat(defaultLabelPayment.getLibelle()).isEqualTo("Repayment - Alice");
        assertThat(defaultLabelPayment.getDebt()).isNull();
    }

    @Test
    void should_return_404_and_keep_the_payments_when_another_user_deletes_the_debt() throws Exception {
        String debtId = createDebt();
        UUID paymentId = repay(debtId, "40.00", null);
        User other = userRepository.save(User.builder()
                .email("debt-other-" + UUID.randomUUID() + "@example.com")
                .password("unused")
                .name("Other")
                .passwordResetRequired(false)
                .build());

        mockMvc.perform(delete("/v1/debts/" + debtId)
                        .header("Authorization", "Bearer " + jwtUtil.generateToken(other.getEmail())))
                .andExpect(status().isNotFound());

        assertThat(debtRepository.findById(UUID.fromString(debtId))).isPresent();
        Transaction payment = transactionRepository.findById(paymentId).orElseThrow();
        assertThat(payment.getLibelle()).isEqualTo("Repayment - Alice");
        assertThat(payment.getDebt()).isNotNull();
    }

    private String createDebt() throws Exception {
        String body = mockMvc.perform(post("/v1/debts")
                        .header("Authorization", bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(DEBT_BODY))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return new ObjectMapper().readTree(body).get("id").asText();
    }

    private UUID repay(String debtId, String amount, String quotedLabel) throws Exception {
        String label = quotedLabel == null ? "" : ",\"libelle\":" + quotedLabel;
        mockMvc.perform(post("/v1/debts/" + debtId + "/repay")
                        .header("Authorization", bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"accountId\":\"" + account.getId() + "\",\"amount\":" + amount + label + "}"))
                .andExpect(status().isOk());
        BigDecimal expected = new BigDecimal(amount);
        return transactionRepository.findByDebtIdOrderByDateDesc(UUID.fromString(debtId)).stream()
                .filter(t -> t.getMontant().compareTo(expected) == 0)
                .findFirst().orElseThrow().getId();
    }

    private String bearer() {
        return "Bearer " + jwtUtil.generateToken(user.getEmail());
    }
}
