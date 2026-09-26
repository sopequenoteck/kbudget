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
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';

import { AdminService } from '../../../../core/services/admin.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Invitation, InvitationStatus } from '../../../../core/models/invitation.model';
import { AdminUser } from '../../../../core/models/user.model';

const INVITATION_STATUS_KEYS: Record<InvitationStatus, string> = {
  ACTIVE: 'users.value.invitationActive',
  EXPIRED: 'users.value.invitationExpired',
  USED: 'users.value.invitationUsed',
  REVOKED: 'users.value.invitationRevoked',
};

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [ReactiveFormsModule, NgIcon, RouterLink, TranslocoPipe],
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
  private readonly transloco = inject(TranslocoService);

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
      this.toastService.success(this.transloco.translate('users.feedback.inviteCreated'));
      this.showInviteForm.set(false);
      await this.loadInvitations();
    } catch {
      this.toastService.error(this.transloco.translate('users.feedback.inviteCreateError'));
    } finally {
      this.loading.set(false);
    }
  }

  async onRevoke(id: number): Promise<void> {
    this.loading.set(true);
    try {
      await firstValueFrom(this.adminService.revokeInvitation(id));
      this.toastService.success(this.transloco.translate('users.feedback.inviteRevoked'));
      await this.loadInvitations();
    } catch {
      this.toastService.error(this.transloco.translate('users.feedback.inviteRevokeError'));
    } finally {
      this.loading.set(false);
    }
  }

  async onCopyLink(token: string): Promise<void> {
    const link = `${window.location.origin}/auth/accept-invite/${token}`;
    try {
      await navigator.clipboard.writeText(link);
      this.toastService.success(this.transloco.translate('users.feedback.linkCopied'));
    } catch {
      this.toastService.error(this.transloco.translate('users.feedback.linkCopyError'));
    }
  }

  async onDisable(id: string): Promise<void> {
    this.loading.set(true);
    try {
      await firstValueFrom(this.adminService.disableUser(id));
      this.toastService.success(this.transloco.translate('users.feedback.userDisabled'));
      await this.loadUsers();
    } catch (err: unknown) {
      const status = (err as { status?: number })?.status;
      if (status === 409) {
        this.toastService.error(this.transloco.translate('users.feedback.lastAdminDisableForbidden'));
      } else {
        this.toastService.error(this.transloco.translate('users.feedback.userDisableError'));
      }
    } finally {
      this.loading.set(false);
    }
  }

  async onEnable(id: string): Promise<void> {
    this.loading.set(true);
    try {
      await firstValueFrom(this.adminService.enableUser(id));
      this.toastService.success(this.transloco.translate('users.feedback.userEnabled'));
      await this.loadUsers();
    } catch {
      this.toastService.error(this.transloco.translate('users.feedback.userEnableError'));
    } finally {
      this.loading.set(false);
    }
  }

  statusKey(status: InvitationStatus): string {
    return INVITATION_STATUS_KEYS[status];
  }

  private async loadData(): Promise<void> {
    await Promise.all([this.loadInvitations(), this.loadUsers()]);
  }

  private async loadInvitations(): Promise<void> {
    try {
      const list = await firstValueFrom(this.adminService.listInvitations());
      this.invitations.set(list);
    } catch {
      this.toastService.error(this.transloco.translate('users.feedback.loadInvitationsError'));
    }
  }

  private async loadUsers(): Promise<void> {
    try {
      const list = await firstValueFrom(this.adminService.listUsers());
      this.users.set(list);
    } catch {
      this.toastService.error(this.transloco.translate('users.feedback.loadUsersError'));
    }
  }
}
