export interface UserInfo {
  name: string;
  email: string;
  defaultCurrency?: string;
  isAdmin?: boolean;
  mustResetCredentials: boolean;
}

export interface AdminUser {
  id: string;
  email: string;
  displayName: string;
  createdAt: string;
  disabledAt: string | null;
  isAdmin: boolean;
}
