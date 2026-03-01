import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, TimeoutError, catchError, map, of, timeout } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface HealthCheckResult {
  status: 'online' | 'offline' | 'checking';
  responseTimeMs: number | null;
  error: string | null;
  checkedAt: Date | null;
}

export interface ServerInfo {
  apiUrl: string;
  environment: string;
}

@Injectable({
  providedIn: 'root',
})
export class HealthService {
  private readonly http = inject(HttpClient);

  getServerInfo(): ServerInfo {
    return {
      apiUrl: window.location.origin + environment.apiUrl,
      environment: environment.production ? 'production' : 'development',
    };
  }

  checkHealth(): Observable<HealthCheckResult> {
    const startTime = Date.now();
    const url = `${environment.apiUrl}/actuator/health`;

    return this.http.get(url).pipe(
      timeout(10000),
      map(() => ({
        status: 'online' as const,
        responseTimeMs: Date.now() - startTime,
        error: null,
        checkedAt: new Date(),
      })),
      catchError((err: unknown) => {
        let error: string;

        if (err instanceof TimeoutError) {
          error = 'Délai de réponse dépassé';
        } else if (err instanceof HttpErrorResponse) {
          if (err.status === 0) {
            error = 'Serveur injoignable';
          } else if (err.status >= 500) {
            error = 'Erreur serveur';
          } else {
            error = 'Erreur inconnue';
          }
        } else {
          error = 'Erreur inconnue';
        }

        return of({
          status: 'offline' as const,
          responseTimeMs: null,
          error,
          checkedAt: new Date(),
        });
      }),
    );
  }
}
