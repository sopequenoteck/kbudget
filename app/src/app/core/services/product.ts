import { Injectable, inject, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api';
import {
  Product,
  ProductRequest,
  ProductUpdateRequest,
  RestockRequest,
  SellRequest,
} from '../models/product.model';
import { Transaction } from '../models/transaction.model';

@Injectable({
  providedIn: 'root',
})
export class ProductService {
  private readonly api = inject(ApiService);

  readonly refreshTrigger = signal(0);

  private refresh(): void {
    this.refreshTrigger.update((v) => v + 1);
  }

  getAll(includeInactive?: boolean): Observable<Product[]> {
    const path = includeInactive ? '/products?includeInactive=true' : '/products';
    return this.api.get<Product[]>(path);
  }

  getById(id: string): Observable<Product> {
    return this.api.get<Product>(`/products/${id}`);
  }

  create(request: ProductRequest): Observable<Product> {
    return this.api.post<Product>('/products', request).pipe(tap(() => this.refresh()));
  }

  update(id: string, request: ProductUpdateRequest): Observable<Product> {
    return this.api.put<Product>(`/products/${id}`, request).pipe(tap(() => this.refresh()));
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/products/${id}`).pipe(tap(() => this.refresh()));
  }

  sell(id: string, quantity?: number): Observable<Product> {
    const body = quantity && quantity > 1 ? ({ quantity } as SellRequest) : undefined;
    return this.api.post<Product>(`/products/${id}/sell`, body).pipe(tap(() => this.refresh()));
  }

  restock(id: string, request: RestockRequest): Observable<Product> {
    return this.api
      .post<Product>(`/products/${id}/restock`, request)
      .pipe(tap(() => this.refresh()));
  }

  getSalesHistory(id: string): Observable<Transaction[]> {
    return this.api.get<Transaction[]>(`/products/${id}/sales`);
  }
}
