package fr.kksdev.budget.api.contract;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.junit.jupiter.api.Assertions.fail;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Non-regression du contrat d'API expose par springdoc (KKS-350).
 *
 * <p>Les regles 1 et 2 de {@code docs/api-compatibility.md} ne reposaient sur
 * aucun mecanisme automatique. Ce test capture une projection du schema
 * OpenAPI (champs de reponse, champs de requete obligatoires) dans un fichier
 * snapshot versionne, et compare la version courante a ce snapshot.
 *
 * <p><strong>Les deux sens de comparaison sont inverses, c'est voulu :</strong>
 * <ul>
 *   <li>RESPONSE : le snapshot doit rester inclus dans le contrat courant.
 *       Une ligne du snapshot absente du courant signifie qu'un champ a ete
 *       retire ou renomme (rupture, regle 1). Une ligne en plus dans le
 *       courant est un ajout legitime — un client ancien l'ignore — et passe
 *       en silence.</li>
 *   <li>REQUEST : le contrat courant doit rester inclus dans le snapshot.
 *       Une ligne du courant absente du snapshot signifie qu'un champ est
 *       devenu obligatoire alors qu'il ne l'etait pas (rupture, regle 2). Une
 *       ligne en moins est une contrainte levee, ce qui ne casse aucun client
 *       et passe en silence.</li>
 * </ul>
 * Additionner ne suffit pas pour l'un ni retirer pour l'autre : la direction
 * de l'inclusion depend de ce qu'un client ancien peut absorber sans casser,
 * pas de la taille du diff. Ne pas uniformiser les deux sens.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = {"springdoc.api-docs.enabled=true"})
class ApiContractIT {

    /**
     * Chemin relatif au module (le repertoire de travail du fork Surefire est
     * le basedir du module {@code api/}). Ecrire ici, jamais dans la copie de
     * {@code target/test-classes}, sinon la regeneration ne serait jamais vue
     * par git.
     */
    private static final Path SNAPSHOT_PATH = Path.of("src/test/resources/api-contract.txt");

    private static final List<String> HTTP_METHODS = List.of("get", "post", "put", "patch", "delete");
    private static final int MAX_DEPTH = 6;

    @Autowired
    private MockMvc mockMvc;

    @Test
    void should_match_snapshot_when_comparing_current_api_contract() throws Exception {
        String json = mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        JsonNode root = new ObjectMapper().readTree(json);
        JsonNode schemas = root.path("components").path("schemas");

        Set<String> currentResponses = new TreeSet<>();
        Set<String> currentRequests = new TreeSet<>();
        collectContract(root, schemas, currentResponses, currentRequests);

        if (Boolean.getBoolean("contract.update")) {
            writeSnapshot(currentResponses, currentRequests);
            return;
        }

        if (!Files.exists(SNAPSHOT_PATH)) {
            fail("Aucun snapshot trouve a " + SNAPSHOT_PATH.toAbsolutePath() + ". "
                    + "Genere le une premiere fois avec -Dcontract.update=true.");
        }

        Set<String> snapshotResponses = new TreeSet<>();
        Set<String> snapshotRequests = new TreeSet<>();
        readSnapshot(snapshotResponses, snapshotRequests);

        // RESPONSE : le snapshot doit etre inclus dans le courant.
        Set<String> missingResponses = new TreeSet<>(snapshotResponses);
        missingResponses.removeAll(currentResponses);

        // REQUEST : le courant doit etre inclus dans le snapshot.
        Set<String> newRequirements = new TreeSet<>(currentRequests);
        newRequirements.removeAll(snapshotRequests);

        if (!missingResponses.isEmpty() || !newRequirements.isEmpty()) {
            fail(buildFailureMessage(missingResponses, newRequirements));
        }
    }

    // ------------------------------------------------------------------
    // Extraction du contrat courant depuis le document OpenAPI
    // ------------------------------------------------------------------

    private void collectContract(JsonNode root, JsonNode schemas, Set<String> responseLines, Set<String> requestLines) {
        Iterator<Map.Entry<String, JsonNode>> pathEntries = root.path("paths").fields();
        while (pathEntries.hasNext()) {
            Map.Entry<String, JsonNode> pathEntry = pathEntries.next();
            String path = pathEntry.getKey();
            Iterator<Map.Entry<String, JsonNode>> methodEntries = pathEntry.getValue().fields();
            while (methodEntries.hasNext()) {
                Map.Entry<String, JsonNode> methodEntry = methodEntries.next();
                String method = methodEntry.getKey();
                if (!HTTP_METHODS.contains(method)) {
                    continue;
                }
                JsonNode operation = methodEntry.getValue();
                collectResponseLines(operation, schemas, method.toUpperCase(), path, responseLines);
                collectRequestLines(operation, schemas, method.toUpperCase(), path, requestLines);
            }
        }
    }

    private void collectResponseLines(JsonNode operation, JsonNode schemas, String method, String path, Set<String> out) {
        Iterator<Map.Entry<String, JsonNode>> responseEntries = operation.path("responses").fields();
        while (responseEntries.hasNext()) {
            Map.Entry<String, JsonNode> responseEntry = responseEntries.next();
            String code = responseEntry.getKey();
            Iterator<JsonNode> contentEntries = responseEntry.getValue().path("content").elements();
            while (contentEntries.hasNext()) {
                JsonNode schema = contentEntries.next().path("schema");
                Set<String> fields = new TreeSet<>();
                collectFields(schema, schemas, "", Set.of(), 0, fields);
                for (String field : fields) {
                    out.add("RESPONSE " + method + " " + path + " " + code + " " + field);
                }
            }
        }
    }

    /**
     * Descend recursivement dans un schema pour lister ses champs terminaux.
     *
     * <p>Un {@code $ref} est resolu vers {@code components.schemas}, un
     * tableau ajoute {@code []} au prefixe puis descend dans {@code items}, un
     * objet descend dans chacune de ses proprietes en pointant le chemin
     * (ex. {@code user.email}). {@code visited} coupe les cycles le long d'un
     * meme chemin de descente (un schema deja traverse sur CE chemin n'est pas
     * redescendu) ; {@code MAX_DEPTH} borne la profondeur en secours.
     *
     * <p>Une reponse racine sans propriete nommee (octet-stream, map libre
     * type {@code additionalProperties}) ne produit aucune ligne : ce n'est
     * pas un "champ" au sens de la regle 1, c'est le corps entier.
     */
    private void collectFields(JsonNode schema, JsonNode schemas, String prefix, Set<String> visited, int depth,
            Set<String> out) {
        if (schema == null || schema.isMissingNode() || depth > MAX_DEPTH) {
            return;
        }
        if (schema.has("$ref")) {
            String name = refName(schema.get("$ref").asText());
            if (visited.contains(name)) {
                return;
            }
            Set<String> nextVisited = new HashSet<>(visited);
            nextVisited.add(name);
            collectFields(schemas.path(name), schemas, prefix, nextVisited, depth + 1, out);
            return;
        }
        if (schema.has("oneOf") || schema.has("anyOf")) {
            for (JsonNode alt : schema.path("oneOf")) {
                collectFields(alt, schemas, prefix, visited, depth, out);
            }
            for (JsonNode alt : schema.path("anyOf")) {
                collectFields(alt, schemas, prefix, visited, depth, out);
            }
            return;
        }
        if ("array".equals(schema.path("type").asText(""))) {
            collectFields(schema.path("items"), schemas, prefix + "[]", visited, depth + 1, out);
            return;
        }
        JsonNode properties = schema.path("properties");
        if (properties.isObject() && properties.size() > 0) {
            Iterator<Map.Entry<String, JsonNode>> propEntries = properties.fields();
            while (propEntries.hasNext()) {
                Map.Entry<String, JsonNode> prop = propEntries.next();
                String childPrefix = prefix.isEmpty() ? prop.getKey() : prefix + "." + prop.getKey();
                collectFields(prop.getValue(), schemas, childPrefix, visited, depth + 1, out);
            }
            return;
        }
        if (prefix.isEmpty()) {
            return;
        }
        out.add(prefix + ": " + schemaType(schema));
    }

    private String schemaType(JsonNode schema) {
        JsonNode typeNode = schema.path("type");
        if (typeNode.isTextual()) {
            return typeNode.asText();
        }
        if (typeNode.isArray()) {
            List<String> values = new java.util.ArrayList<>();
            typeNode.forEach(n -> values.add(n.asText()));
            return String.join("|", values);
        }
        return "object";
    }

    private void collectRequestLines(JsonNode operation, JsonNode schemas, String method, String path, Set<String> out) {
        Iterator<JsonNode> bodyContents = operation.path("requestBody").path("content").elements();
        while (bodyContents.hasNext()) {
            JsonNode resolved = resolveRef(bodyContents.next().path("schema"), schemas);
            for (JsonNode requiredField : resolved.path("required")) {
                out.add("REQUEST " + method + " " + path + " " + requiredField.asText());
            }
        }

        // Les parametres de chemin sont obligatoires par nature (les suivre
        // n'ajoute que du bruit) ; seul "query" est un vrai signal de rupture.
        for (JsonNode param : operation.path("parameters")) {
            if ("query".equals(param.path("in").asText()) && param.path("required").asBoolean(false)) {
                out.add("REQUEST " + method + " " + path + " ?" + param.path("name").asText());
            }
        }
    }

    private JsonNode resolveRef(JsonNode schema, JsonNode schemas) {
        JsonNode current = schema;
        Set<String> visited = new HashSet<>();
        while (current.has("$ref")) {
            String name = refName(current.get("$ref").asText());
            if (!visited.add(name)) {
                break;
            }
            current = schemas.path(name);
        }
        return current;
    }

    private String refName(String ref) {
        return ref.substring(ref.lastIndexOf('/') + 1);
    }

    // ------------------------------------------------------------------
    // Snapshot : lecture, ecriture, message d'echec
    // ------------------------------------------------------------------

    private void readSnapshot(Set<String> responseLines, Set<String> requestLines) {
        try {
            for (String line : Files.readAllLines(SNAPSHOT_PATH, StandardCharsets.UTF_8)) {
                if (line.startsWith("RESPONSE ")) {
                    responseLines.add(line);
                } else if (line.startsWith("REQUEST ")) {
                    requestLines.add(line);
                }
            }
        } catch (IOException e) {
            throw new UncheckedIOException("Lecture du snapshot impossible : " + SNAPSHOT_PATH.toAbsolutePath(), e);
        }
    }

    private void writeSnapshot(Set<String> responseLines, Set<String> requestLines) {
        StringBuilder content = new StringBuilder();
        content.append("# RESPONSE\n");
        for (String line : responseLines) {
            content.append(line).append('\n');
        }
        content.append("\n# REQUEST\n");
        for (String line : requestLines) {
            content.append(line).append('\n');
        }
        try {
            Files.writeString(SNAPSHOT_PATH, content.toString(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new UncheckedIOException("Ecriture du snapshot impossible : " + SNAPSHOT_PATH.toAbsolutePath(), e);
        }
    }

    private String buildFailureMessage(Set<String> missingResponses, Set<String> newRequirements) {
        StringBuilder message = new StringBuilder();
        if (!missingResponses.isEmpty()) {
            message.append(missingResponses.size())
                    .append(" champ(s) de reponse ont disparu du contrat :\n");
            missingResponses.forEach(line -> message.append("  ").append(line).append('\n'));
            message.append('\n');
        }
        if (!newRequirements.isEmpty()) {
            message.append(newRequirements.size())
                    .append(" nouvelle(s) contrainte(s) de requete sont apparues (un champ devient obligatoire) :\n");
            newRequirements.forEach(line -> message.append("  ").append(line).append('\n'));
            message.append('\n');
        }
        message.append("Si la rupture est assumee (regle 6 de docs/api-compatibility.md), regenere le\n")
                .append("snapshot puis relis le diff avant de committer :\n")
                .append("  JAVA_HOME=<jdk21> mvn -pl api test -Dtest=ApiContractIT -Dcontract.update=true\n");
        return message.toString();
    }
}
