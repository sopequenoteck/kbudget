import { ChangeDetectionStrategy, Component, inject, output } from '@angular/core';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorBell } from '@ng-icons/phosphor-icons/regular';
import { NotificationService } from '../../../core/services/notification';

@Component({
  selector: 'app-notification-badge',
  standalone: true,
  imports: [NgIcon],
  providers: [provideIcons({ phosphorBell })],
  template: `
    <button class="notification-badge" (click)="clicked.emit()" aria-label="Notifications">
      <ng-icon name="phosphorBell" size="22" />
      @if (notificationService.hasUnread()) {
        <span class="badge">{{ notificationService.unreadCount() }}</span>
      }
    </button>
  `,
  styles: [`
    .notification-badge {
      position: relative;
      display: flex;
      align-items: center;
      justify-content: center;
      background: none;
      border: none;
      cursor: pointer;
      padding: 6px;
      border-radius: var(--radius-md, 8px);
      color: var(--text-primary);
      transition: background-color 0.15s;
    }
    .notification-badge:hover {
      background-color: var(--hover-bg);
    }
    .badge {
      position: absolute;
      top: 0;
      right: 0;
      min-width: 18px;
      height: 18px;
      padding: 0 5px;
      border-radius: 9px;
      background-color: var(--text-error);
      color: white;
      font-size: var(--font-size-2xs);
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: center;
      line-height: 1;
    }
  `],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationBadge {
  readonly notificationService = inject(NotificationService);
  readonly clicked = output<void>();
}
