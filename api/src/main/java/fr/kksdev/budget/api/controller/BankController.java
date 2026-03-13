package fr.kksdev.budget.api.controller;

import fr.kksdev.budget.api.dto.response.BankResponse;
import fr.kksdev.budget.api.service.BankService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/banks")
@RequiredArgsConstructor
@Tag(name = "Banques", description = "Registre des banques supportées")
public class BankController {

    private final BankService bankService;

    @Operation(summary = "Lister les banques supportées")
    @GetMapping
    public ResponseEntity<List<BankResponse>> getAll() {
        return ResponseEntity.ok(bankService.getAllBanks());
    }
}
