import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'bottom-nav',
  imports: [RouterLink],
  template: `
    <nav class="bottom-nav">
      @for (item of items(); track item.route) {
        <a
          [routerLink]="item.route"
          class="bottom-nav-item"
          [class.active]="activeRoute().startsWith(item.route)"
        >
          <span class="bottom-nav-icon">{{ item.icon }}</span>
          <span class="bottom-nav-label">{{ item.label }}</span>
        </a>
      }
    </nav>
  `,
  styleUrl: './bottom-nav.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BottomNav {
  readonly items = input.required<{ label: string; route: string; icon: string }[]>();
  readonly activeRoute = input<string>('');
}
