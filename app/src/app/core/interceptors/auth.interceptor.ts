import { inject } from '@angular/core';
import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { catchError, throwError } from 'rxjs';

import { AuthService } from '../services/auth';

const PUBLIC_PATHS = ['/auth/login', '/auth/register'];

let isLoggingOut = false;

/** @internal Reset state between tests */
export function _resetInterceptorState(): void {
  isLoggingOut = false;
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
      if (error.status === 401 && !isLoggingOut) {
        isLoggingOut = true;
        authService.logout();
        setTimeout(() => (isLoggingOut = false), 1000);
      }
      return throwError(() => error);
    }),
  );
};
