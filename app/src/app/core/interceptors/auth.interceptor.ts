import { inject, isDevMode } from '@angular/core';
import {
  HttpErrorResponse,
  HttpEvent,
  HttpHandlerFn,
  HttpInterceptorFn,
  HttpRequest,
} from '@angular/common/http';
import { BehaviorSubject, Observable, catchError, filter, switchMap, take, throwError } from 'rxjs';

import { AuthService } from '../services/auth';

const PUBLIC_PATHS = ['/auth/login', '/auth/register', '/auth/refresh', '/auth/logout'];

let isRefreshing = false;
let refreshSubject = new BehaviorSubject<boolean>(true);

/** @internal Reset state between tests */
export function _resetInterceptorState(): void {
  isRefreshing = false;
  refreshSubject = new BehaviorSubject<boolean>(true);
}

function isPublicUrl(url: string): boolean {
  return PUBLIC_PATHS.some((path) => url.includes(path));
}

function isExternalUrl(url: string): boolean {
  return url.startsWith('http://') || url.startsWith('https://');
}

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const token = authService.getToken();

  let request = req;
  if (token && !isPublicUrl(req.url) && !isExternalUrl(req.url)) {
    request = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` },
    });
  }

  return next(request).pipe(
    catchError((error: HttpErrorResponse) => {
      if (
        (error.status === 401 || error.status === 403) &&
        !isPublicUrl(req.url) &&
        !isExternalUrl(req.url) &&
        !req.headers.has('_retry')
      ) {
        return handle401(authService, req, next);
      }
      return throwError(() => error);
    }),
  );
};

function handle401(
  authService: AuthService,
  req: HttpRequest<unknown>,
  next: HttpHandlerFn,
): Observable<HttpEvent<unknown>> {
  if (!isRefreshing) {
    isRefreshing = true;
    refreshSubject.next(false);

    if (isDevMode()) console.log('Refresh token: tentative de renouvellement');

    return authService.refreshAccessToken().pipe(
      switchMap((response) => {
        isRefreshing = false;
        refreshSubject.next(true);
        if (isDevMode()) console.log('Refresh token: renouvellement réussi');

        return next(
          req.clone({
            setHeaders: { Authorization: `Bearer ${response.token}`, _retry: 'true' },
          }),
        );
      }),
      catchError((err) => {
        isRefreshing = false;
        refreshSubject.next(true);

        if (err instanceof HttpErrorResponse && err.status === 401) {
          if (isDevMode()) console.error('Refresh token: échec (401) — déconnexion');
          authService.logout();
        } else if (isDevMode()) {
          console.error('Refresh token: erreur réseau — pas de déconnexion');
        }

        return throwError(() => err);
      }),
    );
  }

  return refreshSubject.pipe(
    filter((ready) => ready),
    take(1),
    switchMap(() => {
      const newToken = authService.getToken();
      if (!newToken) {
        return throwError(() => new HttpErrorResponse({ status: 401, statusText: 'Unauthorized' }));
      }
      return next(
        req.clone({
          setHeaders: { Authorization: `Bearer ${newToken}`, _retry: 'true' },
        }),
      );
    }),
  );
}
