import {
  ChangeDetectionStrategy,
  Component,
  computed,
  ElementRef,
  forwardRef,
  HostListener,
  inject,
  signal,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { BankService } from '../../../core/services/bank';
import { BankResponse } from '../../../core/models/bank.model';

interface BankGroup {
  label: string;
  banks: BankResponse[];
}

@Component({
  selector: 'app-bank-select',
  standalone: true,
  templateUrl: './bank-select.html',
  styleUrl: './bank-select.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => BankSelect),
      multi: true,
    },
  ],
})
export class BankSelect implements ControlValueAccessor {
  private readonly elementRef = inject(ElementRef);
  private readonly bankService = inject(BankService);

  readonly selectedCode = signal('OTHER');
  readonly searchQuery = signal('');
  readonly isOpen = signal(false);
  readonly disabled = signal(false);

  // eslint-disable-next-line @typescript-eslint/no-empty-function
  private onChange: (value: string) => void = () => {};
  // eslint-disable-next-line @typescript-eslint/no-empty-function
  private onTouched: () => void = () => {};

  constructor() {
    this.bankService.loadBanks();
  }

  readonly groupedBanks = computed((): BankGroup[] => {
    const banks = this.bankService.banks().filter((b) => b.code !== 'OTHER');
    const frBanks = banks.filter((b) => b.country === 'FR');
    const tgBanks = banks.filter((b) => b.country === 'TG');
    const intlBanks = banks.filter((b) => b.country === null);

    const groups: BankGroup[] = [];
    if (frBanks.length > 0) groups.push({ label: 'France', banks: frBanks });
    if (tgBanks.length > 0) groups.push({ label: 'Afrique de l\'Ouest', banks: tgBanks });
    if (intlBanks.length > 0) groups.push({ label: 'International', banks: intlBanks });
    return groups;
  });

  readonly filteredGroups = computed((): BankGroup[] => {
    const query = this.searchQuery().toLowerCase().trim();
    if (!query) return this.groupedBanks();
    return this.groupedBanks()
      .map((group) => ({
        ...group,
        banks: group.banks.filter((b) => b.name.toLowerCase().includes(query)),
      }))
      .filter((group) => group.banks.length > 0);
  });

  readonly selectedBank = computed((): BankResponse | null => {
    const code = this.selectedCode();
    if (code === 'OTHER') return null;
    return this.bankService.banks().find((b) => b.code === code) ?? null;
  });

  readonly isKnownBank = computed(() => this.selectedCode() !== 'OTHER');

  selectBank(code: string): void {
    this.selectedCode.set(code);
    this.onChange(code);
    this.closeDropdown();
  }

  toggleDropdown(): void {
    if (this.disabled()) return;
    if (this.isOpen()) {
      this.closeDropdown();
    } else {
      this.openDropdown();
    }
  }

  openDropdown(): void {
    if (this.disabled() || this.isOpen()) return;
    this.isOpen.set(true);
    this.searchQuery.set('');
  }

  closeDropdown(): void {
    if (!this.isOpen()) return;
    this.isOpen.set(false);
    this.searchQuery.set('');
    this.onTouched();
  }

  onSearchInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.searchQuery.set(value);
  }

  writeValue(value: string): void {
    this.selectedCode.set(value || 'OTHER');
  }

  registerOnChange(fn: (value: string) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled.set(isDisabled);
  }

  @HostListener('document:click', ['$event'])
  onClickOutside(event: MouseEvent): void {
    if (!this.elementRef.nativeElement.contains(event.target)) {
      if (this.isOpen()) {
        this.closeDropdown();
      }
    }
  }
}
