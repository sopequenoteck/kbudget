package fr.kksdev.budget.api.dto.response;

import java.util.UUID;

/**
 * Result of {@code POST /imports/detect} (KKS-440): the profile recognized
 * from the file, if any.
 *
 * @param recognized    whether a profile fits the file
 * @param profileSource {@code REGISTRY} or {@code CUSTOM}; {@code null} when not recognized
 * @param bankCode      bank of a {@code REGISTRY} profile; {@code null} for {@code CUSTOM} or when not recognized
 * @param profileName   name of the recognized profile; {@code null} when not recognized
 * @param accountSuffix last four digits of the account number read in the statement header
 *                      (KKS-384); {@code null} when the profile has no header or it is unreadable
 * @param suggestedAccountId the only active account of the authenticated user already imported
 *                      with this profile and this suffix (KKS-384); {@code null} when there is
 *                      none or more than one
 */
public record ImportDetectionResponse(
        boolean recognized,
        String profileSource,
        String bankCode,
        String profileName,
        String accountSuffix,
        UUID suggestedAccountId
) {

    public static ImportDetectionResponse notRecognized() {
        return new ImportDetectionResponse(false, null, null, null, null, null);
    }
}
