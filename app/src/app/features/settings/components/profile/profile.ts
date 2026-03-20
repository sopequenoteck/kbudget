import { ChangeDetectionStrategy, Component, DestroyRef, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';

import { AuthService } from '../../../../core/services/auth';
import { UserService } from '../../../../core/services/user';
import { CurrencyService } from '../../../../core/services/currency';
import { SelectPicker } from '../../../../shared/components/select-picker/select-picker';

@Component({
  selector: 'app-profile',
  imports: [RouterLink, SelectPicker, ReactiveFormsModule],
  templateUrl: './profile.html',
  styleUrl: './profile.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Profile {
  private readonly authService = inject(AuthService);
  private readonly userService = inject(UserService);
  private readonly currencyService = inject(CurrencyService);
  private readonly destroyRef = inject(DestroyRef);

  readonly currentUser = this.authService.currentUser;
  readonly saving = signal(false);
  readonly currencyControl = new FormControl('EUR');

  readonly currencyItems = this.currencyService.currencyItems;

  constructor() {
    this.currencyService.loadIfEmpty();
    firstValueFrom(this.userService.getProfile()).then((profile) => {
      this.currencyControl.setValue(profile.defaultCurrency || 'EUR', { emitEvent: false });
    });

    this.currencyControl.valueChanges.pipe(takeUntilDestroyed(this.destroyRef)).subscribe((code) => {
      if (code) {
        this.onCurrencyChange(code);
      }
    });
  }

  private async onCurrencyChange(code: string): Promise<void> {
    this.saving.set(true);
    try {
      await firstValueFrom(this.userService.updateDefaultCurrency(code));
    } finally {
      this.saving.set(false);
    }
  }
}
