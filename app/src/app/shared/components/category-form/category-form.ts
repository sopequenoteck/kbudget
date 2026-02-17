import {
  ChangeDetectionStrategy,
  Component,
  inject,
  input,
  type OnInit,
  output,
  signal,
} from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { CategoryService } from '../../../core/services/category';
import { Category, CategoryRequest } from '../../../core/models/category.model';
import {
  CATEGORY_COLORS,
  randomColor,
} from '../../../core/constants/category.constants';
import { EmojiInput } from '../emoji-input/emoji-input';

@Component({
  selector: 'app-category-form',
  imports: [ReactiveFormsModule, EmojiInput],
  templateUrl: './category-form.html',
  styleUrl: './category-form.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CategoryForm implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly categoryService = inject(CategoryService);

  readonly category = input<Category | null>(null);
  readonly initialName = input('');
  readonly saved = output<Category>();
  readonly cancelled = output<void>();

  readonly selectedEmoji = signal('');
  readonly selectedColor = signal('');
  readonly submitting = signal(false);
  readonly errorMessage = signal('');

  readonly colors = CATEGORY_COLORS;

  readonly form = this.fb.nonNullable.group({
    nom: ['', [Validators.required, Validators.maxLength(30)]],
  });

  ngOnInit(): void {
    const cat = this.category();
    if (cat) {
      this.form.patchValue({ nom: cat.nom });
      this.selectedEmoji.set(cat.icone);
      this.selectedColor.set(cat.couleur);
    } else {
      if (this.initialName()) {
        this.form.patchValue({ nom: this.initialName() });
      }
      this.selectedColor.set(randomColor());
    }
  }

  get isEditMode(): boolean {
    return this.category() !== null;
  }

  onEmojiSelected(emoji: string): void {
    this.selectedEmoji.set(emoji);
  }

  onColorSelected(color: string): void {
    this.selectedColor.set(color);
  }

  async onSubmit(): Promise<void> {
    if (this.form.invalid || !this.selectedEmoji()) {
      this.form.markAllAsTouched();
      return;
    }

    this.submitting.set(true);
    this.errorMessage.set('');

    const request: CategoryRequest = {
      nom: this.form.getRawValue().nom,
      icone: this.selectedEmoji(),
      couleur: this.selectedColor(),
    };

    try {
      const cat = this.category();
      const result = cat
        ? await firstValueFrom(this.categoryService.update(cat.id, request))
        : await firstValueFrom(this.categoryService.create(request));
      this.saved.emit(result);
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : 'Erreur lors de la sauvegarde';
      this.errorMessage.set(message);
    } finally {
      this.submitting.set(false);
    }
  }

  onCancel(): void {
    this.cancelled.emit();
  }
}
