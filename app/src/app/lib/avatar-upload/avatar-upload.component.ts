import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostListener,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorCamera,
  phosphorTrash,
} from '@ng-icons/phosphor-icons/regular';

const MAX_FILE_SIZE_BYTES = 2 * 1024 * 1024; // 2 MB
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png'];

@Component({
  selector: 'app-avatar-upload',
  standalone: true,
  imports: [NgIcon],
  providers: [
    provideIcons({
      phosphorCamera,
      phosphorTrash,
    }),
  ],
  templateUrl: './avatar-upload.component.html',
  styleUrl: './avatar-upload.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AvatarUploadComponent {
  readonly currentAvatarUrl = input<string | null>(null);
  readonly userInitials = input.required<string>();
  readonly isUploading = input<boolean>(false);

  readonly upload = output<File>();
  readonly delete = output<void>();
  readonly validationError = output<string>();

  readonly showMenu = signal(false);

  readonly fileInput = viewChild.required<ElementRef<HTMLInputElement>>('fileInput');

  @HostListener('document:click')
  onDocumentClick(): void {
    if (this.showMenu()) {
      this.showMenu.set(false);
    }
  }

  onAvatarClick(): void {
    if (this.isUploading()) return;
    this.fileInput().nativeElement.click();
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    // Reset for next selection
    input.value = '';

    if (!ALLOWED_MIME_TYPES.includes(file.type)) {
      this.validationError.emit('Format non supporté. Utilisez une image JPG ou PNG.');
      return;
    }

    if (file.size > MAX_FILE_SIZE_BYTES) {
      this.validationError.emit('La taille maximale est 2 MB.');
      return;
    }

    this.upload.emit(file);
  }

  onChangePhoto(event: Event): void {
    event.stopPropagation();
    this.showMenu.set(false);
    this.fileInput().nativeElement.click();
  }

  onDeletePhoto(event: Event): void {
    event.stopPropagation();
    this.showMenu.set(false);
    this.delete.emit();
  }

  toggleMenu(event: Event): void {
    if (this.isUploading()) return;
    event.stopPropagation();
    this.showMenu.set(!this.showMenu());
  }
}
