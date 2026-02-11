import { Injectable, inject, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api';
import { Category, CategoryRequest } from '../models/category.model';

@Injectable({
  providedIn: 'root',
})
export class CategoryService {
  private readonly api = inject(ApiService);

  readonly refreshTrigger = signal(0);

  private refresh(): void {
    this.refreshTrigger.update((v) => v + 1);
  }

  getAll(): Observable<Category[]> {
    return this.api.get<Category[]>('/categories');
  }

  getById(id: string): Observable<Category> {
    return this.api.get<Category>(`/categories/${id}`);
  }

  create(request: CategoryRequest): Observable<Category> {
    return this.api.post<Category>('/categories', request).pipe(tap(() => this.refresh()));
  }

  update(id: string, request: CategoryRequest): Observable<Category> {
    return this.api.put<Category>(`/categories/${id}`, request).pipe(tap(() => this.refresh()));
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/categories/${id}`).pipe(tap(() => this.refresh()));
  }
}
