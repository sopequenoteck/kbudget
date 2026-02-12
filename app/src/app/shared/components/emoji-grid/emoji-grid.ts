import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { BUDGET_EMOJIS } from '../../../core/constants/category.constants';

@Component({
  selector: 'app-emoji-grid',
  templateUrl: './emoji-grid.html',
  styleUrl: './emoji-grid.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EmojiGrid {
  readonly selected = input('');
  readonly emojiSelected = output<string>();

  readonly emojis = BUDGET_EMOJIS;

  onSelect(emoji: string): void {
    this.emojiSelected.emit(emoji);
  }
}
