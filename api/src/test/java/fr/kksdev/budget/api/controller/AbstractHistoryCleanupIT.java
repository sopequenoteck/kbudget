package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.model.User;
import fr.kksdev.budget.api.repository.CategoryRuleRepository;
import fr.kksdev.budget.api.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.ApplicationContext;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

/** Wiring shared by the integration tests of the history cleanup (KKS-387): fixtures, a user, HTTP helpers. */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
abstract class AbstractHistoryCleanupIT {

    @Autowired MockMvc mockMvc;
    @Autowired ApplicationContext context;
    @Autowired CategoryRuleRepository categoryRuleRepository;
    @Autowired TransactionRepository transactionRepository;

    HistoryCleanupTestData data;
    User user;

    @BeforeEach
    void createFixturesAndUser() {
        data = new HistoryCleanupTestData(context);
        user = data.user();
    }

    ResultActions read(String path) throws Exception {
        return mockMvc.perform(get(path).header("Authorization", data.bearer(user)));
    }

    ResultActions postJson(String path, String body) throws Exception {
        return mockMvc.perform(post(path)
                .header("Authorization", data.bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }
}
