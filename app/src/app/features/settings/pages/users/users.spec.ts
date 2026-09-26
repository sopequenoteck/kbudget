import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { of, throwError } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';

import { Users } from './users';
import { AdminService } from '../../../../core/services/admin.service';
import { ToastService } from '../../../../shared/components/toast/toast.service';
import { Invitation } from '../../../../core/models/invitation.model';
import { AdminUser } from '../../../../core/models/user.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

describe('Users', () => {
  let adminServiceMock: {
    createInvitation: ReturnType<typeof vi.fn>;
    listInvitations: ReturnType<typeof vi.fn>;
    revokeInvitation: ReturnType<typeof vi.fn>;
    listUsers: ReturnType<typeof vi.fn>;
    disableUser: ReturnType<typeof vi.fn>;
    enableUser: ReturnType<typeof vi.fn>;
  };
  let toastServiceMock: { success: ReturnType<typeof vi.fn>; error: ReturnType<typeof vi.fn> };

  const invitation: Invitation = {
    id: 1,
    email: 'invite@exemple.com',
    invitedByEmail: 'admin@exemple.com',
    status: 'ACTIVE',
    token: 'token-123',
    createdAt: '2026-01-01T00:00:00Z',
    expiresAt: '2026-01-08T00:00:00Z',
    usedAt: null,
    revokedAt: null,
  };

  const adminUser: AdminUser = {
    id: 'user-1',
    email: 'user@exemple.com',
    displayName: 'Utilisateur test',
    createdAt: '2026-01-01T00:00:00Z',
    disabledAt: null,
    isAdmin: false,
  };

  const setup = () => {
    adminServiceMock = {
      createInvitation: vi.fn().mockReturnValue(of({ token: 'created-token', expiresAt: '2026-02-01T00:00:00Z' })),
      listInvitations: vi.fn().mockReturnValue(of([invitation])),
      revokeInvitation: vi.fn().mockReturnValue(of(undefined)),
      listUsers: vi.fn().mockReturnValue(of([adminUser])),
      disableUser: vi.fn().mockReturnValue(of(undefined)),
      enableUser: vi.fn().mockReturnValue(of(undefined)),
    };
    toastServiceMock = { success: vi.fn(), error: vi.fn() };

    Object.defineProperty(navigator, 'clipboard', {
      value: { writeText: vi.fn().mockResolvedValue(undefined) },
      configurable: true,
    });

    TestBed.configureTestingModule({
      imports: [Users],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        { provide: AdminService, useValue: adminServiceMock },
        { provide: ToastService, useValue: toastServiceMock },
      ],
    });

    const fixture = TestBed.createComponent(Users);
    return fixture;
  };

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('ngOnInit()', () => {
    it('should_load_invitations_and_users_on_init', async () => {
      const fixture = setup();
      fixture.detectChanges();
      await fixture.whenStable();

      expect(fixture.componentInstance.invitations()).toEqual([invitation]);
      expect(fixture.componentInstance.users()).toEqual([adminUser]);
    });

    it('should_report_load_errors_when_invitations_and_users_fail_to_load', async () => {
      adminServiceMock = {
        createInvitation: vi.fn(),
        listInvitations: vi.fn().mockReturnValue(throwError(() => new Error('boom'))),
        revokeInvitation: vi.fn(),
        listUsers: vi.fn().mockReturnValue(throwError(() => new Error('boom'))),
        disableUser: vi.fn(),
        enableUser: vi.fn(),
      };
      TestBed.configureTestingModule({
        imports: [Users],
        providers: [
          provideTranslocoTesting(),
          provideRouter([]),
          { provide: AdminService, useValue: adminServiceMock },
          { provide: ToastService, useValue: toastServiceMock },
        ],
      });
      const fixture = TestBed.createComponent(Users);
      fixture.detectChanges();
      await fixture.whenStable();

      expect(toastServiceMock.error).toHaveBeenCalledWith('Impossible de charger les invitations.');
      expect(toastServiceMock.error).toHaveBeenCalledWith('Impossible de charger les utilisateurs.');
    });
  });

  describe('statusKey()', () => {
    it.each([
      ['ACTIVE', 'users.value.invitationActive'],
      ['EXPIRED', 'users.value.invitationExpired'],
      ['USED', 'users.value.invitationUsed'],
      ['REVOKED', 'users.value.invitationRevoked'],
    ] as const)('should_return_%s_key_for_%s_status', (status, key) => {
      const fixture = setup();
      fixture.detectChanges();

      expect(fixture.componentInstance.statusKey(status)).toBe(key);
    });
  });

  describe('onInvite()', () => {
    it('should_create_invitation_and_copy_link_when_form_is_valid', async () => {
      const fixture = setup();
      fixture.detectChanges();
      await fixture.whenStable();

      const component = fixture.componentInstance;
      component.inviteForm.setValue({ email: 'nouveau@exemple.com' });

      await component.onInvite();

      expect(adminServiceMock.createInvitation).toHaveBeenCalledWith({ email: 'nouveau@exemple.com' });
      expect(navigator.clipboard.writeText).toHaveBeenCalled();
      expect(toastServiceMock.success).toHaveBeenCalledWith(
        'Invitation créée et lien copié dans le presse-papiers.',
      );
      expect(component.showInviteForm()).toBe(false);
    });

    it('should_not_call_createInvitation_when_form_is_invalid', async () => {
      const fixture = setup();
      fixture.detectChanges();
      await fixture.whenStable();

      const component = fixture.componentInstance;
      component.inviteForm.setValue({ email: 'pas-un-email' });

      await component.onInvite();

      expect(adminServiceMock.createInvitation).not.toHaveBeenCalled();
    });

    it('should_report_error_when_invitation_creation_fails', async () => {
      const fixture = setup();
      adminServiceMock.createInvitation.mockReturnValue(throwError(() => new Error('boom')));
      fixture.detectChanges();
      await fixture.whenStable();

      const component = fixture.componentInstance;
      component.inviteForm.setValue({ email: 'nouveau@exemple.com' });

      await component.onInvite();

      expect(toastServiceMock.error).toHaveBeenCalledWith("Impossible de créer l'invitation.");
    });
  });

  describe('onRevoke()', () => {
    it('should_revoke_invitation_and_reload_list', async () => {
      const fixture = setup();
      fixture.detectChanges();
      await fixture.whenStable();

      await fixture.componentInstance.onRevoke(1);

      expect(adminServiceMock.revokeInvitation).toHaveBeenCalledWith(1);
      expect(toastServiceMock.success).toHaveBeenCalledWith('Invitation révoquée.');
    });

    it('should_report_error_when_revoke_fails', async () => {
      const fixture = setup();
      adminServiceMock.revokeInvitation.mockReturnValue(throwError(() => new Error('boom')));
      fixture.detectChanges();
      await fixture.whenStable();

      await fixture.componentInstance.onRevoke(1);

      expect(toastServiceMock.error).toHaveBeenCalledWith("Impossible de révoquer l'invitation.");
    });
  });

  describe('onCopyLink()', () => {
    it('should_copy_link_to_clipboard', async () => {
      const fixture = setup();
      fixture.detectChanges();
      await fixture.whenStable();

      await fixture.componentInstance.onCopyLink('token-123');

      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
        expect.stringContaining('token-123'),
      );
      expect(toastServiceMock.success).toHaveBeenCalledWith('Lien copié dans le presse-papiers.');
    });

    it('should_report_error_when_copy_fails', async () => {
      const fixture = setup();
      (navigator.clipboard.writeText as ReturnType<typeof vi.fn>).mockRejectedValue(new Error('denied'));
      fixture.detectChanges();
      await fixture.whenStable();

      await fixture.componentInstance.onCopyLink('token-123');

      expect(toastServiceMock.error).toHaveBeenCalledWith('Impossible de copier le lien.');
    });
  });

  describe('onDisable()', () => {
    it('should_disable_user_and_reload_list', async () => {
      const fixture = setup();
      fixture.detectChanges();
      await fixture.whenStable();

      await fixture.componentInstance.onDisable('user-1');

      expect(adminServiceMock.disableUser).toHaveBeenCalledWith('user-1');
      expect(toastServiceMock.success).toHaveBeenCalledWith('Utilisateur désactivé.');
    });

    it('should_report_last_admin_error_on_409_conflict', async () => {
      const fixture = setup();
      const error = new HttpErrorResponse({ status: 409 });
      adminServiceMock.disableUser.mockReturnValue(throwError(() => error));
      fixture.detectChanges();
      await fixture.whenStable();

      await fixture.componentInstance.onDisable('user-1');

      expect(toastServiceMock.error).toHaveBeenCalledWith(
        'Impossible de désactiver le dernier administrateur actif.',
      );
    });

    it('should_report_generic_error_on_other_failures', async () => {
      const fixture = setup();
      adminServiceMock.disableUser.mockReturnValue(throwError(() => new HttpErrorResponse({ status: 500 })));
      fixture.detectChanges();
      await fixture.whenStable();

      await fixture.componentInstance.onDisable('user-1');

      expect(toastServiceMock.error).toHaveBeenCalledWith("Impossible de désactiver l'utilisateur.");
    });
  });

  describe('onEnable()', () => {
    it('should_enable_user_and_reload_list', async () => {
      const fixture = setup();
      fixture.detectChanges();
      await fixture.whenStable();

      await fixture.componentInstance.onEnable('user-1');

      expect(adminServiceMock.enableUser).toHaveBeenCalledWith('user-1');
      expect(toastServiceMock.success).toHaveBeenCalledWith('Utilisateur réactivé.');
    });

    it('should_report_error_when_enable_fails', async () => {
      const fixture = setup();
      adminServiceMock.enableUser.mockReturnValue(throwError(() => new Error('boom')));
      fixture.detectChanges();
      await fixture.whenStable();

      await fixture.componentInstance.onEnable('user-1');

      expect(toastServiceMock.error).toHaveBeenCalledWith("Impossible de réactiver l'utilisateur.");
    });
  });

  describe('setTab() / openInviteForm() / closeInviteForm()', () => {
    it('should_switch_active_tab', () => {
      const fixture = setup();
      fixture.detectChanges();

      fixture.componentInstance.setTab('users');

      expect(fixture.componentInstance.activeTab()).toBe('users');
    });

    it('should_open_and_close_invite_form', () => {
      const fixture = setup();
      fixture.detectChanges();

      fixture.componentInstance.openInviteForm();
      expect(fixture.componentInstance.showInviteForm()).toBe(true);

      fixture.componentInstance.closeInviteForm();
      expect(fixture.componentInstance.showInviteForm()).toBe(false);
    });
  });
});
