import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';

@Component({
  selector: 'app-emoji-input',
  templateUrl: './emoji-input.html',
  styleUrl: './emoji-input.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EmojiInput {
  readonly value = input('');
  readonly valueChange = output<string>();

  onInput(event: Event): void {
    const raw = (event.target as HTMLInputElement).value;
    const segments = [...new Intl.Segmenter('fr', { granularity: 'grapheme' }).segment(raw)];
    const emoji = segments.find(s => /\p{Extended_Pictographic}/u.test(s.segment))?.segment ?? '';
    this.valueChange.emit(emoji);
    (event.target as HTMLInputElement).value = emoji;
  }
}
