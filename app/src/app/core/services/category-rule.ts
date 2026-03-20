import { Injectable, inject, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api';
import { CategoryRule, CategoryRuleRequest } from '../models/import.model';

@Injectable({
  providedIn: 'root',
})
export class CategoryRuleService {
  private readonly api = inject(ApiService);

  readonly refreshTrigger = signal(0);

  private refresh(): void {
    this.refreshTrigger.update((v) => v + 1);
  }

  getAll(): Observable<CategoryRule[]> {
    return this.api.get<CategoryRule[]>('/imports/rules');
  }

  create(request: CategoryRuleRequest): Observable<CategoryRule> {
    return this.api.post<CategoryRule>('/imports/rules', request).pipe(tap(() => this.refresh()));
  }

  update(ruleId: string, request: CategoryRuleRequest): Observable<CategoryRule> {
    return this.api
      .put<CategoryRule>(`/imports/rules/${ruleId}`, request)
      .pipe(tap(() => this.refresh()));
  }

  delete(ruleId: string): Observable<void> {
    return this.api
      .delete<void>(`/imports/rules/${ruleId}`)
      .pipe(tap(() => this.refresh()));
  }
}
