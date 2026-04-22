export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  refreshToken: string;
  email: string;
  name: string;
  mustResetCredentials: boolean;
}

export interface FirstLoginResetRequest {
  email: string;
  password: string;
  displayName: string;
}
