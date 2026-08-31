package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.config.AdminEmailResolver;
import fr.kksdev.budget.api.config.JwtUtil;
import fr.kksdev.budget.api.config.SecurityConfig;
import fr.kksdev.budget.api.dto.response.BankResponse;
import fr.kksdev.budget.api.repository.UserRepository;
import fr.kksdev.budget.api.service.BankService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.ArrayList;
import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(BankController.class)
@Import(SecurityConfig.class)
class BankControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private BankService bankService;

    @MockitoBean
    private JwtUtil jwtUtil;

    @MockitoBean
    private UserRepository userRepository;

    @MockitoBean
    private AdminEmailResolver adminEmailResolver;

    @Test
    void should_returnAllBanks_when_getRequest() throws Exception {
        List<BankResponse> banks = buildBankList(29);
        when(bankService.getAllBanks()).thenReturn(banks);

        mockMvc.perform(get("/v1/banks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(29));
    }

    @Test
    void should_returnBankWithAllFields_when_getRequest() throws Exception {
        var bank = new BankResponse("BNP", "BNP Paribas", "FR", "#00915a", "/api/bank-logos/bnp.svg");
        when(bankService.getAllBanks()).thenReturn(List.of(bank));

        mockMvc.perform(get("/v1/banks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].code").value("BNP"))
                .andExpect(jsonPath("$[0].name").value("BNP Paribas"))
                .andExpect(jsonPath("$[0].country").value("FR"))
                .andExpect(jsonPath("$[0].brandColor").value("#00915a"))
                .andExpect(jsonPath("$[0].logoUrl").value("/api/bank-logos/bnp.svg"));
    }

    @Test
    void should_beAccessibleWithoutAuth() throws Exception {
        when(bankService.getAllBanks()).thenReturn(List.of());

        mockMvc.perform(get("/v1/banks"))
                .andExpect(status().isOk());
    }

    private List<BankResponse> buildBankList(int count) {
        List<BankResponse> banks = new ArrayList<>();
        for (int i = 0; i < count; i++) {
            banks.add(new BankResponse("BANK_" + i, "Bank " + i, "FR", "#000000", "/api/bank-logos/bank" + i + ".svg"));
        }
        return banks;
    }
}
