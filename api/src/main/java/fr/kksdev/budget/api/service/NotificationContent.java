package fr.kksdev.budget.api.service;

import java.util.Map;

/**
 * Contenu pret a passer a {@link NotificationService#createNotification} :
 * {@code title}/{@code message} anglais fixes par le serveur, {@code params}
 * les valeurs brutes que le client compose dans sa langue (KKS-397).
 */
public record NotificationContent(String title, String message, Map<String, String> params) {}
