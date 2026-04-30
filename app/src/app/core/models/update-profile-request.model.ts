// Self-service profile fields ONLY. Email is admin-managed (cf. KKS-235 §FR-007).
// Do not add fields that require admin authorization.
export interface UpdateProfileRequest {
  name: string;
}
