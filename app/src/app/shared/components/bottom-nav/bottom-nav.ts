import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorHouse, phosphorCurrencyDollar, phosphorArrowsClockwise, phosphorHandshake } from '@ng-icons/phosphor-icons/regular';
import { phosphorHouseFill, phosphorCurrencyDollarFill, phosphorArrowsClockwiseFill, phosphorHandshakeFill } from '@ng-icons/phosphor-icons/fill';

@Component({
  selector: 'app-bottom-nav',
  standalone: true,
  imports: [RouterLink, NgIcon],
  host: { '[attr.data-item-count]': 'items().length.toString()' },
  providers: [
    provideIcons({
      phosphorHouse,
      phosphorHouseFill,
      phosphorCurrencyDollar,
      phosphorCurrencyDollarFill,
      phosphorArrowsClockwise,
      phosphorArrowsClockwiseFill,
      phosphorHandshake,
      phosphorHandshakeFill,
    }),
  ],
  template: `
    <nav class="bottom-nav">
      @for (item of items(); track item.route) {
        <a
          [routerLink]="item.route"
          class="bottom-nav-item"
          [class.active]="activeRoute().startsWith(item.route)"
        >
          <span class="bottom-nav-icon">
            @if (activeRoute().startsWith(item.route) && item.filledIcon) {
              <ng-icon [name]="item.filledIcon" size="24" />
            } @else {
              <ng-icon [name]="item.icon" size="24" />
            }
          </span>
          <span class="bottom-nav-label">{{ item.label }}</span>
        </a>
      }
    </nav>
  `,
  styleUrl: './bottom-nav.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BottomNav {
  readonly items = input.required<{ label: string; route: string; icon: string; filledIcon?: string }[]>();
  readonly activeRoute = input<string>('');
}
