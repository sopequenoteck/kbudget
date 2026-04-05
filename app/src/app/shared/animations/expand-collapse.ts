import { trigger, transition, style, animate } from '@angular/animations';

export const expandCollapse = trigger('expandCollapse', [
  transition(':enter', [
    style({ opacity: 0, transform: 'translateY(-8px)', maxHeight: 0 }),
    animate('200ms cubic-bezier(0, 0, 0.2, 1)', style({ opacity: 1, transform: 'translateY(0)', maxHeight: '500px' })),
  ]),
  transition(':leave', [
    animate('150ms cubic-bezier(0.4, 0, 1, 1)', style({ opacity: 0, transform: 'translateY(-8px)', maxHeight: 0 })),
  ]),
]);
