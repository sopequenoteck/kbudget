import { Injectable, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { Observable, catchError, firstValueFrom, of, tap, throwError } from 'rxjs';

import { ApiService } from './api';
import { AuthResponse, LoginRequest } from '../models/auth.model';
import { UserInfo } from '../models/user.model';
import { DevLogger } from './dev-logger';

const STORAGE_TOKEN_KEY = 'budget_token';
const STORAGE_REFRESH_TOKEN_KEY = 'budget_refresh_token';
const STORAGE_USER_KEY = 'budget_user';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private readonly apiService = inject(ApiService);
  private readonly router = inject(Router);
  private readonly logger = inject(DevLogger);

  readonly currentUser = signal<UserInfo | null>(null);
  readonly isAuthenticated = computed(() => this.currentUser() !== null);
  readonly isAdmin = computed(() => this.currentUser()?.isAdmin ?? false);

  constructor() {
    this.restoreSession();
  }

  getToken(): string | null {
    try {
      const token = localStorage.getItem(STORAGE_TOKEN_KEY);
      if (!token || this.isTokenExpired(token)) {
        return null;
      }
      return token;
    } catch {
      this.logger.error('localStorage indisponible');
      return null;
    }
  }

  getRefreshToken(): string | null {
    try {
      return localStorage.getItem(STORAGE_REFRESH_TOKEN_KEY);
    } catch {
      this.logger.error('localStorage indisponible');
      return null;
    }
  }

  login(credentials: LoginRequest): Observable<AuthResponse> {
    return this.apiService.post<AuthResponse>('/auth/login', credentials).pipe(
      tap((response) => this.saveAuth(response)),
      catchError((error) => throwError(() => this.mapAuthError(error))),
    );
  }

  refreshAccessToken(): Observable<AuthResponse> {
    const refreshToken = this.getRefreshToken();
    if (!refreshToken) {
      return throwError(
        () => new HttpErrorResponse({ status: 401, statusText: 'No refresh token' }),
      );
    }
    return this.apiService
      .post<AuthResponse>('/auth/refresh', { refreshToken })
      .pipe(tap((response) => this.saveAuth(response)));
  }

  saveAuthResponse(response: AuthResponse): void {
    this.saveAuth(response);
  }

  patchUserInfo(patch: Partial<UserInfo>): void {
    const current = this.currentUser();
    if (current) {
      this.currentUser.set({ ...current, ...patch });
    }
  }

  logout(): void {
    const refreshToken = this.getRefreshToken();
    if (refreshToken) {
      firstValueFrom(
        this.apiService.post('/auth/logout', { refreshToken }).pipe(catchError(() => of(null))),
      );
    }
    this.clearAuth();
    this.router.navigate(['/auth']);
  }

  private restoreSession(): void {
    try {
      const token = localStorage.getItem(STORAGE_TOKEN_KEY);

      if (token && !this.isTokenExpired(token)) {
        const userJson = localStorage.getItem(STORAGE_USER_KEY);
        if (!userJson) {
          this.clearAuth();
          return;
        }
        try {
          const user: UserInfo = JSON.parse(userJson);
          this.currentUser.set(user);
        } catch {
          this.logger.error('budget_user corrompu');
          this.clearAuth();
        }
        return;
      }

      const refreshToken = this.getRefreshToken();
      if (refreshToken) {
        this.logger.error('restoreSession: access token expiré, tentative de refresh');
        this.refreshAccessToken().subscribe({
          error: () => {
            this.clearAuth();
          },
        });
        return;
      }

      if (token) {
        this.clearAuth();
      }
    } catch {
      this.logger.error('localStorage indisponible');
    }
  }

  private saveAuth(response: AuthResponse): void {
    try {
      localStorage.setItem(STORAGE_TOKEN_KEY, response.token);
      localStorage.setItem(STORAGE_REFRESH_TOKEN_KEY, response.refreshToken);
      localStorage.setItem(
        STORAGE_USER_KEY,
        JSON.stringify({ name: response.name, email: response.email }),
      );
    } catch {
      this.logger.error('localStorage indisponible');
    }
    this.currentUser.set({ name: response.name, email: response.email });
  }

  private clearAuth(): void {
    try {
      localStorage.removeItem(STORAGE_TOKEN_KEY);
      localStorage.removeItem(STORAGE_REFRESH_TOKEN_KEY);
      localStorage.removeItem(STORAGE_USER_KEY);
    } catch {
      this.logger.error('localStorage indisponible');
    }
    this.currentUser.set(null);
  }

  private decodeToken(token: string): Record<string, unknown> | null {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) {
        return null;
      }
      const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      return JSON.parse(atob(payload));
    } catch {
      this.logger.error('Token corrompu');
      return null;
    }
  }

  private isTokenExpired(token: string): boolean {
    const payload = this.decodeToken(token);
    if (!payload || typeof payload['exp'] !== 'number') {
      return true;
    }
    return payload['exp'] < Date.now() / 1000;
  }

  private mapAuthError(error: HttpErrorResponse): string {
    if (error.status === 400) {
      return error.error?.message ?? 'Une erreur est survenue';
    }
    if (error.status === 0) {
      this.logger.error('Erreur réseau', error);
      return 'Impossible de contacter le serveur';
    }
    return 'Une erreur est survenue';
  }
}
