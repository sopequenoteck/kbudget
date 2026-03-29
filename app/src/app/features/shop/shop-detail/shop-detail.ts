import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { DatePipe } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { toSignal } from '@angular/core/rxjs-interop';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowLeft,
  phosphorPencilSimple,
  phosphorTrash,
  phosphorTag,
  phosphorPackage,
  phosphorChartLineUp,
  phosphorTrendUp,
  phosphorShoppingCart,
  phosphorShoppingBag,
} from '@ng-icons/phosphor-icons/regular';
import { ProductService } from '../../../core/services/product';
import { ModalService } from '../../../core/services/modal.service';
import { Product, RestockRequest } from '../../../core/models/product.model';
import { Transaction } from '../../../core/models/transaction.model';
import { RestockDialog } from '../components/restock-dialog/restock-dialog';
import { AmountPipe } from '../../../shared/pipes/amount.pipe';

interface SalesGroup {
  label: string;
  items: Transaction[];
}

@Component({
  selector: 'app-shop-detail',
  imports: [DatePipe, RestockDialog, NgIcon, AmountPipe],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorPencilSimple,
      phosphorTrash,
      phosphorTag,
      phosphorPackage,
      phosphorChartLineUp,
      phosphorTrendUp,
      phosphorShoppingCart,
      phosphorShoppingBag,
    }),
  ],
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

  readonly groupedHistory = computed((): SalesGroup[] => {
    const txs = this.salesHistory();
    if (txs.length === 0) return [];

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);

    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay() + 1); // Lundi

    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

    const buckets = new Map<string, SalesGroup>();

    const add = (key: string, label: string, tx: Transaction) => {
      if (!buckets.has(key)) buckets.set(key, { label, items: [] });
      buckets.get(key)!.items.push(tx);
    };

    for (const tx of txs) {
      const txDate = new Date(tx.date);
      txDate.setHours(0, 0, 0, 0);

      if (txDate.getTime() === today.getTime()) {
        add('today', "Aujourd'hui", tx);
      } else if (txDate.getTime() === yesterday.getTime()) {
        add('yesterday', 'Hier', tx);
      } else if (txDate >= startOfWeek) {
        add('thisWeek', 'Cette semaine', tx);
      } else if (txDate >= startOfMonth) {
        add('ce-mois', 'Ce mois-ci', tx);
      } else {
        const monthLabel = new Intl.DateTimeFormat('fr-FR', { month: 'long', year: 'numeric' }).format(txDate);
        const sortKey = `month-${txDate.getFullYear()}-${String(txDate.getMonth()).padStart(2, '0')}`;
        add(sortKey, monthLabel.charAt(0).toUpperCase() + monthLabel.slice(1), tx);
      }
    }

    const order = ['today', 'yesterday', 'thisWeek', 'ce-mois'];
    const result: SalesGroup[] = [];
    for (const key of order) {
      if (buckets.has(key)) {
        result.push(buckets.get(key)!);
        buckets.delete(key);
      }
    }
    // Remaining month groups (sorted by key descending)
    for (const [, group] of [...buckets.entries()].sort((a, b) => b[0].localeCompare(a[0]))) {
      result.push(group);
    }
    return result;
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
      if (isDevMode()) {
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

  async onDelete(): Promise<void> {
    const p = this.product();
    if (!p) return;

    if (!window.confirm(`Supprimer le produit "${p.nom}" ?`)) return;

    try {
      await firstValueFrom(this.productService.delete(p.id));
      this.router.navigate(['/shop']);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to delete product', err);
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

  onTransactionPressed(tx: Transaction): void {
    this.modalService.openModal('transaction', tx);
  }

  onBack(): void {
    this.router.navigate(['/shop']);
  }

  isWebUrl(url: string | null): boolean {
    return !!url && (url.startsWith('http') || url.startsWith('data:'));
  }
}
