import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { Account } from '../../../core/models/account.model';

@Component({
  selector: 'app-account-picker',
  imports: [DecimalPipe],
  templateUrl: './account-picker.html',
  styleUrl: './account-picker.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AccountPicker {
  readonly accounts = input<Account[]>([]);
  readonly selectedAccountId = input<string | null>(null);
  readonly required = input(true);
  readonly label = input('Compte');

  readonly accountSelected = output<string | null>();

  readonly selectedAccount = computed(() => {
    const id = this.selectedAccountId();
    if (!id) return null;
    return this.accounts().find((a) => a.id === id) ?? null;
  });

  onSelect(accountId: string | null): void {
    this.accountSelected.emit(accountId);
  }
}
