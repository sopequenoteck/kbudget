import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { firstValueFrom } from 'rxjs';
import { ProductService } from '../../../core/services/product';
import { ModalService } from '../../../core/services/modal.service';
import { Product, RestockRequest } from '../../../core/models/product.model';
import { Transaction } from '../../../core/models/transaction.model';
import { RestockDialog } from '../components/restock-dialog/restock-dialog';

@Component({
  selector: 'app-shop-detail',
  imports: [DatePipe, DecimalPipe, RestockDialog],
  templateUrl: './shop-detail.html',
  styleUrl: './shop-detail.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ShopDetail {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly productService = inject(ProductService);
  private readonly modalService = inject(ModalService);

  private readonly paramMap = toSignal(this.route.paramMap);

  readonly productId = computed(() => this.paramMap()?.get('id') ?? null);
  readonly product = signal<Product | null>(null);
  readonly loading = signal<boolean>(true);
  readonly showRestockDialog = signal(false);
  readonly salesHistory = signal<Transaction[]>([]);
  readonly salesLoading = signal(true);
  readonly historySkeletonItems = Array(3);

  readonly margeUnitaire = computed(() => {
    const p = this.product();
    if (!p) return 0;
    return p.prixVente - p.prixAchat;
  });

  readonly ca = computed(() => {
    const p = this.product();
    if (!p) return 0;
    return p.totalVendu * p.prixVente;
  });

  readonly margeTotal = computed(() => {
    const p = this.product();
    if (!p) return 0;
    return p.totalVendu * this.margeUnitaire();
  });

  constructor() {
    effect(() => {
      this.productService.refreshTrigger();
      const id = this.productId();
      if (id) {
        this.loadProduct(id);
      }
    });
  }

  async loadProduct(id: string): Promise<void> {
    this.loading.set(true);

    try {
      const data = await firstValueFrom(this.productService.getById(id));
      this.product.set(data);
      this.loading.set(false);
      this.loadSalesHistory(id);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to load product', err);
      }
      const status = (err as { status?: number }).status;
      if (status === 404) {
        this.router.navigate(['/shop']);
      } else {
        this.loading.set(false);
      }
    }
  }

  onEdit(): void {
    const p = this.product();
    if (p) {
      this.modalService.openModal('product', p);
    }
  }

  async onSell(): Promise<void> {
    const p = this.product();
    if (!p) return;

    if (!window.confirm('Confirmer la vente de 1 unité ?')) return;

    try {
      await firstValueFrom(this.productService.sell(p.id));
    } catch (err: unknown) {
      const status = (err as { status?: number }).status;
      if (status === 409) {
        window.alert('Stock insuffisant ou produit inactif.');
      } else if (isDevMode()) {
        console.error('Failed to sell product', err);
      }
    }
  }

  async onRestock(req: RestockRequest): Promise<void> {
    const p = this.product();
    if (!p) return;

    try {
      await firstValueFrom(this.productService.restock(p.id, req));
      this.showRestockDialog.set(false);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to restock product', err);
      }
    }
  }

  private async loadSalesHistory(id: string): Promise<void> {
    this.salesLoading.set(true);
    try {
      const history = await firstValueFrom(this.productService.getSalesHistory(id));
      this.salesHistory.set(history);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to load sales history', err);
      }
    } finally {
      this.salesLoading.set(false);
    }
  }

  onBack(): void {
    this.router.navigate(['/shop']);
  }

  isWebUrl(url: string | null): boolean {
    return !!url && (url.startsWith('http') || url.startsWith('data:'));
  }
}
