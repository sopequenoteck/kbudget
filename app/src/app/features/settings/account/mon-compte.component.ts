import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
  computed,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorCaretLeft,
  phosphorUser,
  phosphorLock,
  phosphorSignOut,
  phosphorPencil,
  phosphorCheck,
  phosphorX,
  phosphorDownloadSimple,
  phosphorFileCsv,
  phosphorDatabase,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { AuthService } from '../../../core/services/auth';
import { UserService } from '../../../core/services/user';
import { AvatarService } from '../../../core/services/avatar.service';
import { UserExportService } from '../../../core/services/user-export.service';
import { AvatarUploadComponent } from '../../../lib/avatar-upload/avatar-upload.component';
import { ChangePasswordDialogComponent } from './change-password-dialog.component';

@Component({
  selector: 'app-mon-compte',
  standalone: true,
  imports: [
    RouterLink,
    NgIcon,
    AvatarUploadComponent,
    ChangePasswordDialogComponent,
  ],
  providers: [
    provideIcons({
      phosphorCaretLeft,
      phosphorUser,
      phosphorLock,
      phosphorSignOut,
      phosphorPencil,
      phosphorCheck,
      phosphorX,
      phosphorDownloadSimple,
      phosphorFileCsv,
      phosphorDatabase,
    }),
  ],
  templateUrl: './mon-compte.component.html',
  styleUrl: './mon-compte.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MonCompteComponent implements OnInit {
  private readonly authService = inject(AuthService);
  private readonly userService = inject(UserService);
  private readonly avatarService = inject(AvatarService);
  private readonly userExportService = inject(UserExportService);
  private readonly router = inject(Router);

  readonly changePasswordDialog = viewChild.required(ChangePasswordDialogComponent);

  readonly currentUser = computed(() => this.authService.currentUser());
  readonly avatarUrl = computed(() => this.avatarService.avatarUrl());
  readonly isUploadingAvatar = signal(false);
  readonly isExportingJson = signal(false);
  readonly isExportingCsv = signal(false);
  readonly errorMessage = signal<string | null>(null);

  // Inline name edition
  readonly isEditingName = signal(false);
  readonly editedName = signal('');

  readonly initials = computed(() => {
    const user = this.currentUser();
    if (!user?.name) return '?';
    return user.name
      .split(' ')
      .map((part: string) => part[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  });

  ngOnInit(): void {
    firstValueFrom(this.userService.getProfile()).catch(() => {
      // profile already loaded or network error — non-blocking
    });
  }

  // ===== Avatar handlers =====

  async onAvatarUpload(file: File): Promise<void> {
    this.isUploadingAvatar.set(true);
    this.errorMessage.set(null);
    try {
      await firstValueFrom(this.avatarService.upload(file));
    } catch {
      this.errorMessage.set('Impossible d\'uploader la photo. Veuillez réessayer.');
    } finally {
      this.isUploadingAvatar.set(false);
    }
  }

  async onAvatarDelete(): Promise<void> {
    this.isUploadingAvatar.set(true);
    this.errorMessage.set(null);
    try {
      await firstValueFrom(this.avatarService.delete());
    } catch {
      this.errorMessage.set('Impossible de supprimer la photo.');
    } finally {
      this.isUploadingAvatar.set(false);
    }
  }

  onAvatarError(message: string): void {
    this.errorMessage.set(message);
  }

  // ===== Name edit =====

  startEditName(): void {
    const user = this.currentUser();
    if (user) {
      this.editedName.set(user.name);
      this.isEditingName.set(true);
    }
  }

  cancelEditName(): void {
    this.isEditingName.set(false);
    this.editedName.set('');
  }

  async onSaveName(): Promise<void> {
    const name = this.editedName().trim();
    if (!name) return;

    this.errorMessage.set(null);
    try {
      await firstValueFrom(this.userService.updateProfile({ name }));
      this.isEditingName.set(false);
    } catch {
      this.errorMessage.set('Impossible de sauvegarder le nom. Veuillez réessayer.');
    }
  }

  onNameInput(event: Event): void {
    this.editedName.set((event.target as HTMLInputElement).value);
  }

  // ===== Change password =====

  async onChangePassword(): Promise<void> {
    this.errorMessage.set(null);
    const result = await this.changePasswordDialog().open();
    if (result) {
      // AuthService.saveAuthResponse already called in UserService.changePassword
      // Show success feedback
      this.errorMessage.set(null);
    }
  }

  // ===== Export =====

  async onExportJson(): Promise<void> {
    if (this.isExportingJson()) return;
    this.isExportingJson.set(true);
    this.errorMessage.set(null);
    try {
      await firstValueFrom(this.userExportService.exportJson());
    } catch {
      this.errorMessage.set('Erreur lors de l\'export JSON. Veuillez réessayer.');
    } finally {
      this.isExportingJson.set(false);
    }
  }

  async onExportCsv(): Promise<void> {
    if (this.isExportingCsv()) return;
    this.isExportingCsv.set(true);
    this.errorMessage.set(null);
    try {
      await firstValueFrom(this.userExportService.exportCsv());
    } catch {
      this.errorMessage.set('Erreur lors de l\'export CSV. Veuillez réessayer.');
    } finally {
      this.isExportingCsv.set(false);
    }
  }

  // ===== Logout =====

  onLogout(): void {
    try {
      this.authService.logout();
    } catch {
      // Even if the API call fails, purge local state and redirect
      this.router.navigate(['/auth']);
    }
  }
}
