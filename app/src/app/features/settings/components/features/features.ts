import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { CdkDragDrop, CdkDropList, CdkDrag, moveItemInArray } from '@angular/cdk/drag-drop';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowsClockwise,
  phosphorCaretLeft,
  phosphorCurrencyDollar,
  phosphorDotsSixVertical,
  phosphorHandshake,
  phosphorHouse,
  phosphorLock,
  phosphorStorefront,
} from '@ng-icons/phosphor-icons/regular';

import { PreferenceService } from '../../../../core/services/preference';
import { SubscriptionService } from '../../../../core/services/subscription';
import { DebtService } from '../../../../core/services/debt';
import { FEATURES, type Feature } from '../../../../core/models/preference.model';

@Component({
  selector: 'app-features',
  imports: [RouterLink, CdkDropList, CdkDrag, NgIcon],
  providers: [
    provideIcons({
      phosphorArrowsClockwise,
      phosphorCaretLeft,
      phosphorCurrencyDollar,
      phosphorDotsSixVertical,
      phosphorHandshake,
      phosphorHouse,
      phosphorLock,
      phosphorStorefront,
    }),
  ],
  templateUrl: './features.html',
  styleUrl: './features.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Features {
  readonly preferenceService = inject(PreferenceService);
  private readonly subscriptionService = inject(SubscriptionService);
  private readonly debtService = inject(DebtService);
  readonly features = FEATURES;
  readonly confirmDisableFeature = signal<Feature | null>(null);

  readonly enabledNavItems = computed(() => {
    const navOrder = this.preferenceService.navOrder();
    const enabled = this.preferenceService.enabledFeatures();
    return navOrder
      .filter((f) => enabled.includes(f))
      .map((f) => FEATURES.find((m) => m.value === f)!);
  });

  async toggleFeature(feature: Feature): Promise<void> {
    const isCurrentlyEnabled = this.preferenceService.isEnabled(feature);

    // When disabling, check if data exists
    if (isCurrentlyEnabled) {
      const hasData = await this.checkFeatureHasData(feature);
      if (hasData) {
        this.confirmDisableFeature.set(feature);
        return;
      }
    }

    this.preferenceService.toggleFeature(feature);
  }

  confirmDisable(): void {
    const feature = this.confirmDisableFeature();
    if (feature) {
      this.preferenceService.toggleFeature(feature);
      this.confirmDisableFeature.set(null);
    }
  }

  cancelDisable(): void {
    this.confirmDisableFeature.set(null);
  }

  onDrop(event: CdkDragDrop<unknown>): void {
    const items = [...this.enabledNavItems()];
    moveItemInArray(items, event.previousIndex, event.currentIndex);
    this.preferenceService.reorderNavigation(items.map((i) => i.value));
  }

  private async checkFeatureHasData(feature: Feature): Promise<boolean> {
    try {
      if (feature === 'SUBSCRIPTIONS') {
        const subs = await firstValueFrom(this.subscriptionService.getAll());
        return subs.length > 0;
      }
      if (feature === 'DEBTS') {
        const debts = await firstValueFrom(this.debtService.getAll());
        return debts.length > 0;
      }
      return false; // SHOP never has data check
    } catch {
      return false; // On error, allow toggle without confirmation
    }
  }
}
