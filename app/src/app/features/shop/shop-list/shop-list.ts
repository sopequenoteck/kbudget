import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  ElementRef,
  inject,
  OnDestroy,
  signal,
  viewChild,
} from '@angular/core';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorStorefront,
  phosphorTrendUp,
  phosphorPackage,
  phosphorCube,
  phosphorCaretDown,
} from '@ng-icons/phosphor-icons/regular';
import { ProductService } from '../../../core/services/product';
import { ModalService } from '../../../core/services/modal.service';
import { PreferenceService } from '../../../core/services/preference';
import { ConversionService } from '../../../core/services/conversion';
import { ExchangeRateService } from '../../../core/services/exchange-rate';
import { Product } from '../../../core/models/product.model';
import { AmountPipe } from '../../../shared/pipes/amount.pipe';
import { EmptyState } from '../../../shared/components/empty-state/empty-state';
import { CurrencyPillSelector } from '../../dashboard/components/currency-pill-selector';
import { DevLogger } from '../../../core/services/dev-logger';

interface ProductGroup {
  label: string;
  status: string;
  items: Product[];
}

@Component({
  selector: 'app-shop-list',
  standalone: true,
  imports: [AmountPipe, NgIcon, EmptyState, CurrencyPillSelector],
  providers: [
    provideIcons({
      phosphorStorefront,
      phosphorTrendUp,
      phosphorPackage,
      phosphorCube,
      phosphorCaretDown,
    }),
  ],
  templateUrl: './shop-list.html',
  styleUrl: './shop-list.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ShopList implements AfterViewInit, OnDestroy {
  private readonly router = inject(Router);
  private readonly productService = inject(ProductService);
  private readonly modalService = inject(ModalService);
  readonly preferenceService = inject(PreferenceService);
  readonly conversionService = inject(ConversionService);
  private readonly exchangeRateService = inject(ExchangeRateService);
  private readonly logger = inject(DevLogger);
  readonly activeCurrency = signal('EUR');
  private persistTimeout: ReturnType<typeof setTimeout> | null = null;

  readonly stickySentinel = viewChild<ElementRef>('stickySentinel');
  readonly isStuck = signal(false);
  private observer: IntersectionObserver | null = null;

  readonly products = signal<Product[]>([]);
  readonly loading = signal<boolean>(true);
  readonly error = signal<boolean>(false);
  readonly skeletonItems = Array(5);
  readonly collapsedGroups = signal<Set<string>>(new Set(['warning', 'inactive']));

  readonly activeProducts = computed(() => this.products().filter((p) => p.actif));
  readonly activeCount = computed(() => this.activeProducts().length);

  readonly totalCA = computed(() => {
    const raw = this.activeProducts().reduce((sum, p) => sum + p.totalVendu * p.prixVente, 0);
    const from = this.preferenceService.primaryCurrency();
    const to = this.activeCurrency();
    return this.conversionService.convert(raw, from, to) ?? raw;
  });

  readonly totalMargin = computed(() => {
    const raw = this.activeProducts().reduce(
      (sum, p) => sum + p.totalVendu * (p.prixVente - p.prixAchat),
      0,
    );
    const from = this.preferenceService.primaryCurrency();
    const to = this.activeCurrency();
    return this.conversionService.convert(raw, from, to) ?? raw;
  });

  readonly stockValue = computed(() => {
    const raw = this.activeProducts().reduce((sum, p) => sum + p.stock * p.prixAchat, 0);
    const from = this.preferenceService.primaryCurrency();
    const to = this.activeCurrency();
    return this.conversionService.convert(raw, from, to) ?? raw;
  });

  readonly groupedProducts = computed((): ProductGroup[] => {
    const all = this.products();

    const inStock: Product[] = [];
    const outOfStock: Product[] = [];
    const inactive: Product[] = [];

    for (const p of all) {
      if (!p.actif) {
        inactive.push(p);
      } else if (p.stock === 0) {
        outOfStock.push(p);
      } else {
        inStock.push(p);
      }
    }

    const groups: ProductGroup[] = [];
    if (inStock.length > 0) groups.push({ label: 'En stock', status: 'default', items: inStock });
    if (outOfStock.length > 0)
      groups.push({ label: 'Rupture de stock', status: 'warning', items: outOfStock });
    if (inactive.length > 0)
      groups.push({ label: 'Inactifs', status: 'inactive', items: inactive });

    return groups;
  });

  constructor() {
    this.activeCurrency.set(this.preferenceService.primaryCurrency());
    this.exchangeRateService.loadRates();

    effect(() => {
      this.productService.refreshTrigger();
      this.loadData();
    });
  }

  setActiveCurrency(currency: string): void {
    this.activeCurrency.set(currency);

    const current = this.preferenceService.currencies();
    const reordered = [currency, ...current.filter(c => c !== currency)];
    this.preferenceService.setCurrencies(reordered);

    if (this.persistTimeout) clearTimeout(this.persistTimeout);
    this.persistTimeout = setTimeout(async () => {
      this.persistTimeout = null;
      this.preferenceService.update({ currencies: reordered });
      await this.exchangeRateService.loadRates();
      this.loadData();
    }, 2000);
  }

  ngAfterViewInit(): void {
    const sentinel = this.stickySentinel();
    if (sentinel) {
      this.observer = new IntersectionObserver(
        ([entry]) => this.isStuck.set(!entry.isIntersecting),
        { threshold: 0 },
      );
      this.observer.observe(sentinel.nativeElement);
    }
  }

  ngOnDestroy(): void {
    this.observer?.disconnect();
    if (this.persistTimeout) clearTimeout(this.persistTimeout);
  }

  async loadData(): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    try {
      const data = await firstValueFrom(this.productService.getAll(true));
      this.products.set(data);
      this.loading.set(false);
    } catch (err) {
      this.logger.error('Failed to load products', err);
      this.error.set(true);
      this.loading.set(false);
    }
  }

  toggleGroup(status: string): void {
    const current = new Set(this.collapsedGroups());
    if (current.has(status)) {
      current.delete(status);
    } else {
      current.add(status);
    }
    this.collapsedGroups.set(current);
  }

  isCollapsed(status: string): boolean {
    return this.collapsedGroups().has(status);
  }

  onProductPressed(product: Product): void {
    this.router.navigate(['/shop', product.id]);
  }

  onCreate(): void {
    this.modalService.openModal('product');
  }
}
