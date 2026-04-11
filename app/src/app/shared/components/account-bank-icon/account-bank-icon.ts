import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { Account } from '../../../core/models/account.model';

@Component({
  selector: 'app-account-bank-icon',
  standalone: true,
  templateUrl: './account-bank-icon.html',
  styleUrl: './account-bank-icon.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AccountBankIcon {
  readonly account = input.required<Account>();
  readonly size = input<number>(24);

  readonly showBankLogo = computed(() => {
    const acc = this.account();
    return !!acc.bankCode && acc.bankCode !== 'OTHER' && !!acc.bankLogoUrl;
  });

  readonly showCustomLogo = computed(() => {
    const acc = this.account();
    return acc.bankCode === 'OTHER' && !!acc.bankCustomLogo;
  });

  readonly showEmoji = computed(() => !this.showBankLogo() && !this.showCustomLogo());

  readonly logoSrc = computed(() => {
    const acc = this.account();
    if (this.showBankLogo()) return acc.bankLogoUrl;
    if (this.showCustomLogo()) return acc.bankCustomLogo;
    return null;
  });

  readonly brandColor = computed(() => this.account().bankBrandColor);

  onImgError(event: Event): void {
    // Hide img and show emoji fallback
    (event.target as HTMLElement).style.display = 'none';
    const parent = (event.target as HTMLElement).parentElement;
    if (parent) {
      const fallback = parent.querySelector('.account-bank-icon__emoji-fallback') as HTMLElement;
      if (fallback) fallback.style.display = 'inline';
    }
  }
}
