import { Injectable, computed, inject, isDevMode, signal } from '@angular/core';
import { Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { Observable, catchError, tap, throwError } from 'rxjs';

import { ApiService } from './api';
import { AuthResponse, LoginRequest, RegisterRequest } from '../models/auth.model';
import { UserInfo } from '../models/user.model';

const STORAGE_TOKEN_KEY = 'budget_token';
const STORAGE_USER_KEY = 'budget_user';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private readonly apiService = inject(ApiService);
  private readonly router = inject(Router);

  readonly currentUser = signal<UserInfo | null>(null);
  readonly isAuthenticated = computed(() => this.currentUser() !== null);

  constructor() {
    this.restoreSession();
  }

  getToken(): string | null {
    try {
      const token = localStorage.getItem(STORAGE_TOKEN_KEY);
      if (!token) {
        return null;
      }
      if (this.isTokenExpired(token)) {
        this.clearAuth();
        return null;
      }
      return token;
    } catch {
      if (isDevMode()) console.error('localStorage indisponible');
      return null;
    }
  }

  login(credentials: LoginRequest): Observable<AuthResponse> {
    return this.apiService.post<AuthResponse>('/auth/login', credentials).pipe(
      tap((response) => this.saveAuth(response)),
      catchError((error) => throwError(() => this.mapAuthError(error))),
    );
  }

  register(data: RegisterRequest): Observable<AuthResponse> {
    return this.apiService.post<AuthResponse>('/auth/register', data).pipe(
      tap((response) => this.saveAuth(response)),
      catchError((error) => throwError(() => this.mapAuthError(error))),
    );
  }

  logout(): void {
    this.clearAuth();
    this.router.navigate(['/auth']);
  }

  private restoreSession(): void {
    try {
      const token = localStorage.getItem(STORAGE_TOKEN_KEY);
      if (!token) {
        return;
      }

      if (this.isTokenExpired(token)) {
        this.clearAuth();
        return;
      }

      const userJson = localStorage.getItem(STORAGE_USER_KEY);
      if (!userJson) {
        this.clearAuth();
        return;
      }

      try {
        const user: UserInfo = JSON.parse(userJson);
        this.currentUser.set(user);
      } catch {
        if (isDevMode()) console.error('budget_user corrompu');
        this.clearAuth();
      }
    } catch {
      if (isDevMode()) console.error('localStorage indisponible');
    }
  }

  private saveAuth(response: AuthResponse): void {
    try {
      localStorage.setItem(STORAGE_TOKEN_KEY, response.token);
      localStorage.setItem(
        STORAGE_USER_KEY,
        JSON.stringify({ name: response.name, email: response.email }),
      );
    } catch {
      if (isDevMode()) console.error('localStorage indisponible');
    }
    this.currentUser.set({ name: response.name, email: response.email });
  }

  private clearAuth(): void {
    try {
      localStorage.removeItem(STORAGE_TOKEN_KEY);
      localStorage.removeItem(STORAGE_USER_KEY);
    } catch {
      if (isDevMode()) console.error('localStorage indisponible');
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
      if (isDevMode()) console.error('Token corrompu');
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
      if (isDevMode()) console.error('Erreur réseau', error);
      return 'Impossible de contacter le serveur';
    }
    return 'Une erreur est survenue';
  }
}
