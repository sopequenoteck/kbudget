import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { NgClass } from '@angular/common';

@Component({
  selector: 'app-list-item',
  imports: [NgClass],
  templateUrl: './list-item.html',
  styleUrl: './list-item.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ListItem {
  readonly icon = input.required<string>();
  readonly title = input.required<string>();
  readonly value = input.required<string>();
  readonly subtitle = input<string>('');
  readonly rightSubtitle = input<string>('');
  readonly valueSubtitle = input<string>('');
  readonly valueClass = input<string>('');
  readonly imageUrl = input<string | null>(null);

  readonly webImageUrl = computed(() => {
    const url = this.imageUrl();
    if (!url) return null;
    return url.startsWith('http') || url.startsWith('data:') ? url : null;
  });

  readonly pressed = output<void>();

  onPress(): void {
    this.pressed.emit();
  }

  onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      this.pressed.emit();
    }
  }
}
