package fr.kksdev.budget.api.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum AccountType {
    COURANT("🏦", "#3b82f6"),
    EPARGNE("🐷", "#22c55e"),
    ESPECES("💵", "#f59e0b");

    private final String defaultIcone;
    private final String defaultCouleur;
}
