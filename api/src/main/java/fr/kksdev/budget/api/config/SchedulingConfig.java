package fr.kksdev.budget.api.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Taches planifiees de l'application (rappels de dettes, notifications,
 * nettoyage des brouillons d'import).
 *
 * <p>Desactivables par {@code app.scheduling.enabled=false}, ce que font les
 * tests. La raison n'est pas la performance : {@code checkDebtReminders} a un
 * {@code fixedDelay} sans {@code initialDelay}, donc s'execute des le demarrage
 * du contexte, et sa requete lit {@code debts} et {@code users} d'un cote quand
 * un test fait {@code TRUNCATE TABLE users CASCADE} de l'autre. Les deux
 * verrouillent les memes tables dans des ordres opposes — PostgreSQL detecte un
 * interblocage et le test echoue, au hasard du calendrier (KKS-356).
 */
@Configuration
@EnableScheduling
@ConditionalOnProperty(name = "app.scheduling.enabled", havingValue = "true", matchIfMissing = true)
public class SchedulingConfig {
}
