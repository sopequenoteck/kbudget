package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.response.CurrencyInfo;
import fr.kksdev.budget.api.enums.Currency;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;

@RestController
@RequestMapping("/currencies")
@Tag(name = "Devises", description = "Liste des devises supportées")
public class CurrencyController {

    @Operation(summary = "Lister les devises supportées")
    @GetMapping
    public ResponseEntity<List<CurrencyInfo>> getAll() {
        List<CurrencyInfo> currencies = Arrays.stream(Currency.values())
                .map(c -> new CurrencyInfo(c.name(), c.getSymbol(), c.getDisplayName(), c.getDecimalPlaces()))
                .sorted((a, b) -> a.code().compareTo(b.code()))
                .toList();
        return ResponseEntity.ok(currencies);
    }
}
