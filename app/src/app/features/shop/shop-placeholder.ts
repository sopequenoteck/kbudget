import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-shop-placeholder',
  imports: [RouterLink],
  template: `
    <div class="placeholder">
      <span class="placeholder__icon">🏪</span>
      <h2 class="placeholder__title">Boutique</h2>
      <p class="placeholder__message">Cette fonctionnalité sera bientôt disponible.</p>
      <a class="placeholder__link" routerLink="/dashboard">Retour à l'accueil</a>
    </div>
  `,
  styles: `
    :host {
      display: block;
      padding: var(--space-4);
    }
    .placeholder {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 60vh;
      text-align: center;
    }
    .placeholder__icon {
      font-size: 4rem;
      margin-bottom: var(--space-4);
    }
    .placeholder__title {
      font-size: var(--font-size-xl);
      font-weight: var(--font-weight-semibold);
      color: var(--text-primary);
      margin-bottom: var(--space-2);
    }
    .placeholder__message {
      color: var(--text-secondary);
      font-size: var(--font-size-sm);
      margin-bottom: var(--space-6);
    }
    .placeholder__link {
      color: var(--color-primary);
      text-decoration: none;
      font-size: var(--font-size-sm);
      font-weight: var(--font-weight-medium);
    }
    .placeholder__link:hover {
      text-decoration: underline;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ShopPlaceholder {}
