package fr.kksdev.budget.api.contract;

import fr.kksdev.budget.api.config.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;
import java.util.TreeSet;

import static org.junit.jupiter.api.Assertions.fail;

/**
 * Inventaire versionne des {@link ExceptionHandler} de
 * {@link GlobalExceptionHandler} (KKS-357).
 *
 * <p>Chaque code d'erreur servi est deja verifie par un test : ceux du
 * handler par {@code GlobalExceptionHandlerTest}, les quatre emis hors du
 * handler par {@code ApiSecurityErrorHandlersTest},
 * {@code AdminAuthorizationFilterTest},
 * {@code PasswordResetRequiredFilterTest} et {@code RateLimitIT}. Ce que ces
 * tests ne peuvent pas faire, c'est signaler ce qu'ils ne couvrent pas : ce
 * sont des listes tenues a la main, et rien n'oblige un handler nouvellement
 * ajoute a y entrer. Un code d'erreur peut donc naitre, partir en production
 * et arriver chez les clients sans qu'aucun test ne devienne rouge.
 *
 * <p>D'ou l'inventaire : le snapshot est versionne, donc tout mouvement passe
 * par un diff relu en revue. Le garde-fou n'est pas le test, c'est le diff —
 * meme raisonnement que {@code ApiContractIT}.
 *
 * <p><strong>La comparaison est stricte dans les deux sens, contrairement a
 * {@code ApiContractIT} :</strong>
 * <ul>
 *   <li>un handler <em>retire</em> fait retomber son exception sur
 *       {@code handleGeneric}, donc sur un {@code 500 INTERNAL_ERROR} au lieu
 *       du code specialise que le client attendait ;</li>
 *   <li>un handler <em>ajoute</em> sert un code que personne n'a encore vu.
 *       C'est precisement ce qu'on veut faire remarquer, alors qu'un champ de
 *       reponse ajoute, lui, est absorbe sans bruit par un client ancien.</li>
 * </ul>
 * L'inclusion a sens unique d'{@code ApiContractIT} repond a une autre
 * question — ce qu'un client ancien encaisse. Ici la question est : qu'est-ce
 * qui a bouge sans qu'on le voie. Ne pas aligner les deux.
 *
 * <p>Les emetteurs hors handler ({@code ApiAuthenticationEntryPoint},
 * {@code ApiAccessDeniedHandler}, {@code AdminAuthorizationFilter},
 * {@code RateLimitFilter}, {@code PasswordResetRequiredFilter}) passent par
 * {@code ApiErrorWriter} et non par une methode annotee : ils restent hors de
 * cet inventaire.
 */
class ExceptionHandlerInventoryTest {

    /**
     * Chemin relatif au module : le repertoire de travail du fork Surefire est
     * le basedir de {@code api/}. Ecrire ici, jamais dans la copie de
     * {@code target/test-classes}, sinon la regeneration echapperait a git.
     */
    private static final Path SNAPSHOT_PATH = Path.of("src/test/resources/api-error-handlers.txt");

    @Test
    void should_match_snapshot_when_listing_declared_exception_handlers() {
        Set<String> current = collectHandlers();

        if (Boolean.getBoolean("contract.update")) {
            writeSnapshot(current);
            return;
        }

        if (!Files.exists(SNAPSHOT_PATH)) {
            fail("Aucun snapshot trouve a " + SNAPSHOT_PATH.toAbsolutePath()
                    + ". Genere le une premiere fois avec -Dcontract.update=true.");
        }

        Set<String> snapshot = readSnapshot();

        Set<String> removed = new TreeSet<>(snapshot);
        removed.removeAll(current);

        Set<String> added = new TreeSet<>(current);
        added.removeAll(snapshot);

        if (!removed.isEmpty() || !added.isEmpty()) {
            fail(buildFailureMessage(removed, added));
        }
    }

    private Set<String> collectHandlers() {
        Set<String> lines = new TreeSet<>();
        for (Method method : GlobalExceptionHandler.class.getDeclaredMethods()) {
            ExceptionHandler annotation = method.getAnnotation(ExceptionHandler.class);
            if (annotation == null) {
                continue;
            }
            for (Class<? extends Throwable> handled : handledTypes(annotation, method)) {
                lines.add(handled.getSimpleName() + " -> " + method.getName());
            }
        }
        return lines;
    }

    /**
     * {@code @ExceptionHandler} sans valeur explicite se lit sur les types des
     * parametres de la methode — les deux formes existent dans le projet.
     */
    private Class<? extends Throwable>[] handledTypes(ExceptionHandler annotation, Method method) {
        if (annotation.value().length > 0) {
            return annotation.value();
        }
        @SuppressWarnings("unchecked")
        Class<? extends Throwable>[] parameters = (Class<? extends Throwable>[]) method.getParameterTypes();
        return parameters;
    }

    private Set<String> readSnapshot() {
        try {
            Set<String> lines = new TreeSet<>();
            for (String line : Files.readAllLines(SNAPSHOT_PATH, StandardCharsets.UTF_8)) {
                if (!line.isBlank() && !line.startsWith("#")) {
                    lines.add(line);
                }
            }
            return lines;
        } catch (IOException e) {
            throw new UncheckedIOException("Lecture du snapshot impossible : " + SNAPSHOT_PATH.toAbsolutePath(), e);
        }
    }

    private void writeSnapshot(Set<String> lines) {
        StringBuilder content = new StringBuilder(
                "# Handlers declares par GlobalExceptionHandler (KKS-357).\n"
                        + "# Regenerer : cd api && mvn test -Dtest=ExceptionHandlerInventoryTest -Dcontract.update=true\n");
        lines.forEach(line -> content.append(line).append('\n'));
        try {
            Files.writeString(SNAPSHOT_PATH, content.toString(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException("Ecriture du snapshot impossible : " + SNAPSHOT_PATH.toAbsolutePath(), e);
        }
    }

    private String buildFailureMessage(Set<String> removed, Set<String> added) {
        StringBuilder message = new StringBuilder();
        if (!removed.isEmpty()) {
            message.append(removed.size()).append(" handler(s) ont disparu — leur exception retombe desormais sur ")
                    .append("handleGeneric, donc sur un 500 INTERNAL_ERROR :\n");
            removed.forEach(line -> message.append("  ").append(line).append('\n'));
            message.append('\n');
        }
        if (!added.isEmpty()) {
            message.append(added.size()).append(" handler(s) sont apparus. Verifie que le code d'erreur servi est ")
                    .append("teste, puis documente dans docs/api-errors.md :\n");
            added.forEach(line -> message.append("  ").append(line).append('\n'));
            message.append('\n');
        }
        message.append("Si le changement est voulu, regenere l'inventaire puis relis le diff :\n")
                .append("  cd api && JAVA_HOME=<jdk21> mvn test -Dtest=ExceptionHandlerInventoryTest -Dcontract.update=true\n");
        return message.toString();
    }
}
