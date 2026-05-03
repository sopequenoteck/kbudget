import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
  inject,
  signal,
} from '@angular/core';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorCaretLeft,
  phosphorPlus,
  phosphorTrash,
  phosphorLockSimpleOpen,
  phosphorLock,
  phosphorUsers,
  phosphorEnvelope,
  phosphorShieldCheck,
  phosphorCopy,
} from '@ng-icons/phosphor-icons/regular';
import { RouterLink } from '@angular/router';

import { AdminService } from '../../../../core/services/admin.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Invitation, InvitationStatus } from '../../../../core/models/invitation.model';
import { AdminUser } from '../../../../core/models/user.model';

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [ReactiveFormsModule, NgIcon, RouterLink],
  providers: [
    provideIcons({
      phosphorCaretLeft,
      phosphorPlus,
      phosphorTrash,
      phosphorLockSimpleOpen,
      phosphorLock,
      phosphorUsers,
      phosphorEnvelope,
      phosphorShieldCheck,
      phosphorCopy,
    }),
  ],
  templateUrl: './users.html',
  styleUrl: './users.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Users implements OnInit {
  private readonly adminService = inject(AdminService);
  private readonly toastService = inject(ToastService);
  private readonly fb = inject(FormBuilder);

  readonly activeTab = signal<'invitations' | 'users'>('invitations');
  readonly invitations = signal<Invitation[]>([]);
  readonly users = signal<AdminUser[]>([]);
  readonly loading = signal(false);
  readonly showInviteForm = signal(false);

  readonly inviteForm = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
  });

  async ngOnInit(): Promise<void> {
    await this.loadData();
  }

  setTab(tab: 'invitations' | 'users'): void {
    this.activeTab.set(tab);
  }

  openInviteForm(): void {
    this.inviteForm.reset();
    this.showInviteForm.set(true);
  }

  closeInviteForm(): void {
    this.showInviteForm.set(false);
  }

  async onInvite(): Promise<void> {
    if (this.inviteForm.invalid) {
      this.inviteForm.markAllAsTouched();
      return;
    }

    this.loading.set(true);
    try {
      const { email } = this.inviteForm.getRawValue();
      const created = await firstValueFrom(this.adminService.createInvitation({ email }));
      const link = `${window.location.origin}/auth/accept-invite/${created.token}`;
      await navigator.clipboard.writeText(link);
      this.toastService.success('Invitation créée et lien copié dans le presse-papiers.');
      this.showInviteForm.set(false);
      await this.loadInvitations();
    } catch {
      this.toastService.error("Impossible de créer l'invitation.");
    } finally {
      this.loading.set(false);
    }
  }

  async onRevoke(id: number): Promise<void> {
    this.loading.set(true);
    try {
      await firstValueFrom(this.adminService.revokeInvitation(id));
      this.toastService.success('Invitation révoquée.');
      await this.loadInvitations();
    } catch {
      this.toastService.error("Impossible de révoquer l'invitation.");
    } finally {
      this.loading.set(false);
    }
  }

  async onCopyLink(token: string): Promise<void> {
    const link = `${window.location.origin}/auth/accept-invite/${token}`;
    try {
      await navigator.clipboard.writeText(link);
      this.toastService.success('Lien copié dans le presse-papiers.');
    } catch {
      this.toastService.error('Impossible de copier le lien.');
    }
  }

  async onDisable(id: string): Promise<void> {
    this.loading.set(true);
    try {
      await firstValueFrom(this.adminService.disableUser(id));
      this.toastService.success('Utilisateur désactivé.');
      await this.loadUsers();
    } catch (err: unknown) {
      const status = (err as { status?: number })?.status;
      if (status === 409) {
        this.toastService.error('Impossible de désactiver le dernier administrateur actif.');
      } else {
        this.toastService.error("Impossible de désactiver l'utilisateur.");
      }
    } finally {
      this.loading.set(false);
    }
  }

  async onEnable(id: string): Promise<void> {
    this.loading.set(true);
    try {
      await firstValueFrom(this.adminService.enableUser(id));
      this.toastService.success('Utilisateur réactivé.');
      await this.loadUsers();
    } catch {
      this.toastService.error("Impossible de réactiver l'utilisateur.");
    } finally {
      this.loading.set(false);
    }
  }

  statusLabel(status: InvitationStatus): string {
    const labels: Record<InvitationStatus, string> = {
      ACTIVE: 'Active',
      EXPIRED: 'Expirée',
      USED: 'Utilisée',
      REVOKED: 'Révoquée',
    };
    return labels[status];
  }

  private async loadData(): Promise<void> {
    await Promise.all([this.loadInvitations(), this.loadUsers()]);
  }

  private async loadInvitations(): Promise<void> {
    try {
      const list = await firstValueFrom(this.adminService.listInvitations());
      this.invitations.set(list);
    } catch {
      this.toastService.error('Impossible de charger les invitations.');
    }
  }

  private async loadUsers(): Promise<void> {
    try {
      const list = await firstValueFrom(this.adminService.listUsers());
      this.users.set(list);
    } catch {
      this.toastService.error('Impossible de charger les utilisateurs.');
    }
  }
}
