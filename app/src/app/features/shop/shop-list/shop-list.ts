import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorStorefront } from '@ng-icons/phosphor-icons/regular';
import { ProductService } from '../../../core/services/product';
import { ModalService } from '../../../core/services/modal.service';
import { Product } from '../../../core/models/product.model';
import { ListItem } from '../../../shared/components/list-item/list-item';
import { AmountPipe } from '../../../shared/pipes/amount.pipe';

type ProductFilter = 'active' | 'inactive' | 'all';

@Component({
  selector: 'app-shop-list',
  imports: [ListItem, AmountPipe, NgIcon],
  providers: [
    provideIcons({
      phosphorStorefront,
    }),
  ],
  templateUrl: './shop-list.html',
  styleUrl: './shop-list.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ShopList {
  private readonly router = inject(Router);
  private readonly productService = inject(ProductService);
  private readonly modalService = inject(ModalService);

  readonly products = signal<Product[]>([]);
  readonly loading = signal<boolean>(true);
  readonly error = signal<boolean>(false);
  readonly filter = signal<ProductFilter>('active');
  readonly skeletonItems = Array(5);

  readonly filteredProducts = computed(() => {
    const all = this.products();
    const f = this.filter();
    if (f === 'active') return all.filter((p) => p.actif);
    if (f === 'inactive') return all.filter((p) => !p.actif);
    return all;
  });

  constructor() {
    effect(() => {
      this.productService.refreshTrigger();
      this.loadData();
    });
  }

  async loadData(): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    try {
      const data = await firstValueFrom(this.productService.getAll(true));
      this.products.set(data);
      this.loading.set(false);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load products', err);
      }
      this.error.set(true);
      this.loading.set(false);
    }
  }

  setFilter(f: ProductFilter): void {
    this.filter.set(f);
  }

  onProductPressed(product: Product): void {
    this.router.navigate(['/shop', product.id]);
  }

  onCreate(): void {
    this.modalService.openModal('product');
  }
}
