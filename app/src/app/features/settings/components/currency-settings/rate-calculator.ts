import {
  ChangeDetectionStrategy,
  Component,
  computed,
  input,
  signal,
} from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-rate-calculator',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [DecimalPipe, FormsModule],
  template: `
    <div class="settings-section">
      <h3 class="settings-section__title">Calculateur de taux</h3>
      <div class="section-content">
        <p class="settings-section__desc">Calculez un taux à partir d'un montant converti.</p>

        <div class="calculator">
          <div class="calculator__row">
            <label class="form-label">J'ai</label>
            <div class="calculator__input-group">
              <input
                type="number"
                class="form-input"
                [ngModel]="calcAmount1()"
                (ngModelChange)="calcAmount1.set($event)"
                min="0"
                step="any"
                placeholder="Montant"
              />
              <select
                class="form-select form-select--currency"
                [ngModel]="calcCurrency1()"
                (ngModelChange)="calcCurrency1.set($event)"
              >
                @for (c of currencies(); track c) {
                  <option [value]="c">{{ c }}</option>
                }
              </select>
            </div>
          </div>

          <div class="calculator__equals">=</div>

          <div class="calculator__row">
            <label class="form-label">Équivaut à</label>
            <div class="calculator__input-group">
              <input
                type="number"
                class="form-input"
                [ngModel]="calcAmount2()"
                (ngModelChange)="calcAmount2.set($event)"
                min="0"
                step="any"
                placeholder="Montant"
              />
              <select
                class="form-select form-select--currency"
                [ngModel]="calcCurrency2()"
                (ngModelChange)="calcCurrency2.set($event)"
              >
                @for (c of currencies(); track c) {
                  <option [value]="c">{{ c }}</option>
                }
              </select>
            </div>
          </div>

          @if (calculatedRate() !== null) {
            <div class="calculator__result">
              1 {{ calcCurrency1() }} = <strong>{{ calculatedRate() | number: '1.0-6' }}</strong> {{ calcCurrency2() }}
            </div>
          }
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .settings-section {
        margin-bottom: 0;

        &__title {
          font-size: var(--font-size-xs);
          font-weight: var(--font-weight-semibold);
          text-transform: uppercase;
          letter-spacing: 0.5px;
          color: var(--text-tertiary);
          padding: 0 var(--space-4);
          margin-bottom: var(--space-2);
        }

        &__desc {
          font-size: var(--font-size-xs);
          color: var(--text-tertiary);
          margin-bottom: var(--space-4);
        }
      }

      .section-content {
        background: var(--surface-default);
        border-radius: var(--radius-xl);
        overflow: hidden;
        padding: var(--space-4);
      }

      .form-label {
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-medium);
        color: var(--text-secondary);
      }

      .form-input {
        padding: var(--space-2) var(--space-3);
        border: 1px solid var(--border-default);
        border-radius: var(--radius-lg);
        background: transparent;
        color: var(--text-primary);
        font-size: var(--font-size-sm);
        width: 100%;
        box-sizing: border-box;

        &:focus {
          outline: 2px solid var(--color-primary);
          outline-offset: 2px;
        }

        &::placeholder {
          color: var(--text-tertiary);
        }
      }

      .form-select {
        padding: var(--space-2) var(--space-3);
        border: 1px solid var(--border-default);
        border-radius: var(--radius-lg);
        background: transparent;
        color: var(--text-primary);
        font-size: var(--font-size-sm);
        cursor: pointer;
        appearance: auto;

        &:focus {
          outline: 2px solid var(--color-primary);
          outline-offset: 2px;
        }

        &--currency {
          width: 80px;
          flex-shrink: 0;
        }
      }

      .calculator {
        display: flex;
        flex-direction: column;
        gap: var(--space-3);

        &__row {
          display: flex;
          flex-direction: column;
          gap: var(--space-2);
        }

        &__input-group {
          display: flex;
          gap: var(--space-2);
          align-items: center;
        }

        &__equals {
          font-size: var(--font-size-base);
          font-weight: var(--font-weight-medium);
          color: var(--text-tertiary);
          text-align: center;
        }

        &__result {
          padding: var(--space-3) var(--space-4);
          background: rgba(255, 255, 255, 0.04);
          border-radius: var(--radius-lg);
          font-size: var(--font-size-sm);
          color: var(--text-primary);
          text-align: center;
        }
      }
    `,
  ],
})
export class RateCalculator {
  readonly currencies = input.required<string[]>();

  readonly calcAmount1 = signal<number | null>(null);
  readonly calcAmount2 = signal<number | null>(null);
  readonly calcCurrency1 = signal('EUR');
  readonly calcCurrency2 = signal('USD');

  readonly calculatedRate = computed(() => {
    const a1 = this.calcAmount1();
    const a2 = this.calcAmount2();
    if (a1 && a2 && a1 > 0) {
      return a2 / a1;
    }
    return null;
  });
}
