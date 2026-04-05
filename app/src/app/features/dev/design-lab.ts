import { Component, ChangeDetectionStrategy, inject, OnInit } from '@angular/core';
import { ThemeService } from '../../core/services/theme';

@Component({
  selector: 'app-design-lab',
  standalone: true,
  imports: [],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="lab">
      <div class="lab__header">
        <h1 class="lab__title">Design Lab</h1>
        <p class="lab__subtitle">Composants atomiques — visualisation et itération</p>
      </div>
    </div>
  `,
  styles: `
    :host {
      display: block;
      background: var(--bg-primary, #0a0a0a);
    }

    .lab {
      padding: var(--space-5);
      padding-bottom: 80px;
      max-width: 480px;
      margin: 0 auto;
    }

    .lab__header {
      margin-bottom: var(--space-8);
    }

    .lab__title {
      font-size: var(--font-size-xl);
      font-weight: var(--font-weight-bold);
      color: var(--text-primary);
    }

    .lab__subtitle {
      font-size: var(--font-size-xs);
      color: var(--text-tertiary);
      margin-top: var(--space-1);
    }
  `,
})
export class DesignLab implements OnInit {
  private themeService = inject(ThemeService);

  ngOnInit(): void {
    this.themeService.setTheme('dark');
  }
}
