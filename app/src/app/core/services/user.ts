import { Injectable, inject, signal } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { ApiService } from './api';
import { AuthService } from './auth';
import { UserInfo } from '../models/user.model';

@Injectable({
  providedIn: 'root',
})
export class UserService {
  private readonly api = inject(ApiService);
  private readonly authService = inject(AuthService);

  private readonly _profile = signal<UserInfo | null>(null);
  readonly profile = this._profile.asReadonly();

  getProfile(): Observable<UserInfo> {
    return this.api.get<UserInfo>('/users/me').pipe(
      tap((profile) => {
        this._profile.set(profile);
        this.authService.patchUserInfo({ isAdmin: profile.isAdmin ?? false });
      }),
    );
  }

  updateDefaultCurrency(currency: string): Observable<UserInfo> {
    return this.api
      .put<UserInfo>('/users/me', { defaultCurrency: currency })
      .pipe(tap((profile) => this._profile.set(profile)));
  }
}
