package fr.kksdev.budget.api.dto.response;

/**
 * Result of {@code POST /imports/detect} (KKS-440): the profile recognized
 * from the file, if any.
 *
 * @param recognized    whether a profile fits the file
 * @param profileSource {@code REGISTRY} or {@code CUSTOM}; {@code null} when not recognized
 * @param bankCode      bank of a {@code REGISTRY} profile; {@code null} for {@code CUSTOM} or when not recognized
 * @param profileName   name of the recognized profile; {@code null} when not recognized
 */
public record ImportDetectionResponse(
        boolean recognized,
        String profileSource,
        String bankCode,
        String profileName
) {

    public static ImportDetectionResponse notRecognized() {
        return new ImportDetectionResponse(false, null, null, null);
    }
}
