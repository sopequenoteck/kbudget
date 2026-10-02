import { Injectable, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import {
  Observable,
  catchError,
  finalize,
  firstValueFrom,
  of,
  shareReplay,
  tap,
  throwError,
} from 'rxjs';

import { ApiService } from './api';
import { AuthResponse, FirstLoginResetRequest, LoginRequest } from '../models/auth.model';
import { UserInfo } from '../models/user.model';
import { DevLogger } from './dev-logger';
import { ApiErrorService } from './api-error';
import { LOGIN_ERROR_OVERRIDES } from '../constants/error-messages.constants';
import { isInternalReturnUrl } from '../../shared/utils/return-url.utils';

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
  private readonly apiError = inject(ApiErrorService);

  readonly currentUser = signal<UserInfo | null>(null);
  readonly isAuthenticated = computed(() => this.currentUser() !== null);
  readonly isAdmin = computed(() => this.currentUser()?.isAdmin ?? false);
  readonly mustResetCredentials = computed(() => this.currentUser()?.mustResetCredentials ?? false);

  /**
   * Refresh en cours, partage entre tous les appelants (KKS-448). L'API fait
   * tourner le refresh token (usage unique) et revoque TOUTES les sessions de
   * l'utilisateur si un jeton deja consomme est rejoue : deux POST
   * `/auth/refresh` simultanes avec le meme jeton sont donc destructeurs.
   */
  private refreshInFlight: Observable<AuthResponse> | null = null;

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
      catchError((error) => throwError(() => this.mapAuthError(error, LOGIN_ERROR_OVERRIDES))),
    );
  }

  firstLoginReset(payload: FirstLoginResetRequest): Observable<AuthResponse> {
    return this.apiService.post<AuthResponse>('/auth/first-login-reset', payload).pipe(
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
    if (this.refreshInFlight) {
      return this.refreshInFlight;
    }
    const refresh$ = this.apiService.post<AuthResponse>('/auth/refresh', { refreshToken }).pipe(
      tap((response) => this.saveAuth(response)),
      finalize(() => {
        this.refreshInFlight = null;
      }),
      shareReplay({ bufferSize: 1, refCount: false }),
    );
    this.refreshInFlight = refresh$;
    return refresh$;
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
        const user = this.readStoredUser();
        if (user) {
          this.currentUser.set(user);
        } else {
          this.clearAuth();
        }
        return;
      }

      const refreshToken = this.getRefreshToken();
      if (refreshToken) {
        this.logger.error('restoreSession: access token expiré, tentative de refresh');
        // Session optimiste (KKS-448) : l'utilisateur memorise est pose tout
        // de suite, sans attendre le refresh, pour que `authGuard` (synchrone)
        // ne renvoie pas vers la connexion une session encore valide.
        const rememberedUser = this.readStoredUser();
        if (rememberedUser) {
          this.currentUser.set(rememberedUser);
        }
        this.refreshInBackground(rememberedUser !== null);
        return;
      }

      if (token) {
        this.clearAuth();
      }
    } catch {
      this.logger.error('localStorage indisponible');
    }
  }

  /** Utilisateur memorise (`budget_user`), ou null s'il est absent ou corrompu. */
  private readStoredUser(): UserInfo | null {
    const userJson = localStorage.getItem(STORAGE_USER_KEY);
    if (!userJson) {
      return null;
    }
    try {
      const parsed = JSON.parse(userJson);
      return { ...parsed, mustResetCredentials: parsed.mustResetCredentials ?? false };
    } catch {
      this.logger.error('budget_user corrompu');
      return null;
    }
  }

  /**
   * Refresh de demarrage. Differe d'un tick : appele depuis le constructeur,
   * la requete traverserait `authInterceptor`, qui injecte `AuthService` encore
   * en construction (NG0200, erreur reprise par le `clearAuth` : session
   * effacee a chaque lancement).
   *
   * Seul un 401 deconnecte : c'est la reponse de l'API a tout refus du refresh
   * token (expire, revoque, rejoue, inconnu), et la regle de `authInterceptor`.
   * Toute autre erreur (reseau, 5xx, 4xx d'un proxy, 429 du rate limiting)
   * laisse jetons et utilisateur en place ; l'intercepteur retente au premier 401.
   */
  private refreshInBackground(optimisticSession: boolean): void {
    queueMicrotask(() => {
      this.refreshAccessToken().subscribe({
        error: (error: unknown) => {
          if (!this.isRefreshRejected(error)) {
            this.logger.error('restoreSession: refresh impossible, session conservée', error);
            return;
          }
          this.clearAuth();
          if (optimisticSession) {
            this.redirectToLogin();
          }
        },
      });
    });
  }

  private isRefreshRejected(error: unknown): boolean {
    return error instanceof HttpErrorResponse && error.status === 401;
  }

  /** Renvoie vers la connexion en memorisant la page courante, sauf si on y est deja. */
  private redirectToLogin(): void {
    const url = this.router.url;
    if (url.startsWith('/auth')) {
      return;
    }
    if (isInternalReturnUrl(url)) {
      this.router.navigate(['/auth'], { queryParams: { returnUrl: url } });
    } else {
      this.router.navigate(['/auth']);
    }
  }

  private saveAuth(response: AuthResponse): void {
    try {
      localStorage.setItem(STORAGE_TOKEN_KEY, response.token);
      localStorage.setItem(STORAGE_REFRESH_TOKEN_KEY, response.refreshToken);
      localStorage.setItem(
        STORAGE_USER_KEY,
        JSON.stringify({
          name: response.name,
          email: response.email,
          mustResetCredentials: response.mustResetCredentials,
        }),
      );
    } catch {
      this.logger.error('localStorage indisponible');
    }
    this.currentUser.set({
      name: response.name,
      email: response.email,
      mustResetCredentials: response.mustResetCredentials,
    });
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

  /**
   * Traduit une erreur d'authentification en libelle affichable.
   *
   * Delegue integralement a {@link ApiErrorService} (KKS-324) : le libelle
   * derive du code porte par `error`, jamais du `message` du serveur, devenu
   * un champ de diagnostic. Les branchements par statut HTTP qui vivaient ici
   * ont disparu — le code seul suffit, c'est tout l'interet de la manoeuvre.
   *
   * Seul le journal reseau reste local : il documente une panne de transport,
   * pas un libelle.
   */
  private mapAuthError(
    error: HttpErrorResponse,
    overrides: Readonly<Record<string, string>> = {},
  ): string {
    if (error.status === 0) {
      this.logger.error('Erreur réseau', error);
    }
    return this.apiError.label(error, undefined, overrides);
  }
}
