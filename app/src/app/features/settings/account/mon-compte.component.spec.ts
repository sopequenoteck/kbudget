import { TestBed } from '@angular/core/testing';
import { provideRouter, Router } from '@angular/router';
import { signal } from '@angular/core';
import { of, throwError } from 'rxjs';

import { MonCompteComponent } from './mon-compte.component';
import { AuthService } from '../../../core/services/auth';
import { UserService } from '../../../core/services/user';
import { AvatarService } from '../../../core/services/avatar.service';
import { UserExportService } from '../../../core/services/user-export.service';
import { UserInfo } from '../../../core/models/user.model';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

describe('MonCompteComponent', () => {
  let authServiceMock: {
    currentUser: ReturnType<typeof signal<UserInfo | null>>;
    logout: ReturnType<typeof vi.fn>;
  };
  let userServiceMock: {
    getProfile: ReturnType<typeof vi.fn>;
    updateProfile: ReturnType<typeof vi.fn>;
  };
  let avatarServiceMock: {
    avatarUrl: ReturnType<typeof signal<string | null>>;
    loadAvatarBlob: ReturnType<typeof vi.fn>;
    upload: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
  };
  let userExportServiceMock: { exportJson: ReturnType<typeof vi.fn>; exportCsv: ReturnType<typeof vi.fn> };

  const user: UserInfo = {
    name: 'Ada Lovelace',
    email: 'ada@exemple.com',
    mustResetCredentials: false,
  };

  const setup = () => {
    authServiceMock = {
      currentUser: signal<UserInfo | null>(user),
      logout: vi.fn(),
    };
    userServiceMock = {
      getProfile: vi.fn().mockReturnValue(of(user)),
      updateProfile: vi.fn().mockReturnValue(of(user)),
    };
    avatarServiceMock = {
      avatarUrl: signal<string | null>(null),
      loadAvatarBlob: vi.fn().mockReturnValue(of(undefined)),
      upload: vi.fn().mockReturnValue(of({ etag: 'etag-1' })),
      delete: vi.fn().mockReturnValue(of(undefined)),
    };
    userExportServiceMock = {
      exportJson: vi.fn().mockReturnValue(of(undefined)),
      exportCsv: vi.fn().mockReturnValue(of(undefined)),
    };

    TestBed.configureTestingModule({
      imports: [MonCompteComponent],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        { provide: AuthService, useValue: authServiceMock },
        { provide: UserService, useValue: userServiceMock },
        { provide: AvatarService, useValue: avatarServiceMock },
        { provide: UserExportService, useValue: userExportServiceMock },
      ],
    });

    return TestBed.createComponent(MonCompteComponent);
  };

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('initials()', () => {
    it('should_compute_initials_from_the_current_user_name', () => {
      const fixture = setup();
      fixture.detectChanges();

      expect(fixture.componentInstance.initials()).toBe('AL');
    });

    it('should_return_placeholder_when_there_is_no_current_user', () => {
      const fixture = setup();
      authServiceMock.currentUser.set(null);
      fixture.detectChanges();

      expect(fixture.componentInstance.initials()).toBe('?');
    });
  });

  describe('avatar handlers', () => {
    it('should_upload_avatar_and_reset_uploading_flag', async () => {
      const fixture = setup();
      fixture.detectChanges();
      const file = new File(['x'], 'avatar.png', { type: 'image/png' });

      await fixture.componentInstance.onAvatarUpload(file);

      expect(avatarServiceMock.upload).toHaveBeenCalledWith(file);
      expect(fixture.componentInstance.isUploadingAvatar()).toBe(false);
      expect(fixture.componentInstance.errorMessage()).toBeNull();
    });

    it('should_set_error_message_when_avatar_upload_fails', async () => {
      const fixture = setup();
      avatarServiceMock.upload.mockReturnValue(throwError(() => new Error('boom')));
      fixture.detectChanges();
      const file = new File(['x'], 'avatar.png', { type: 'image/png' });

      await fixture.componentInstance.onAvatarUpload(file);

      expect(fixture.componentInstance.errorMessage()).toBe(
        "Impossible d'uploader la photo. Veuillez réessayer.",
      );
    });

    it('should_delete_avatar', async () => {
      const fixture = setup();
      fixture.detectChanges();

      await fixture.componentInstance.onAvatarDelete();

      expect(avatarServiceMock.delete).toHaveBeenCalled();
      expect(fixture.componentInstance.errorMessage()).toBeNull();
    });

    it('should_set_error_message_when_avatar_delete_fails', async () => {
      const fixture = setup();
      avatarServiceMock.delete.mockReturnValue(throwError(() => new Error('boom')));
      fixture.detectChanges();

      await fixture.componentInstance.onAvatarDelete();

      expect(fixture.componentInstance.errorMessage()).toBe('Impossible de supprimer la photo.');
    });

    it('should_forward_avatar_validation_errors', () => {
      const fixture = setup();
      fixture.detectChanges();

      fixture.componentInstance.onAvatarError('Fichier trop volumineux');

      expect(fixture.componentInstance.errorMessage()).toBe('Fichier trop volumineux');
    });
  });

  describe('name edition', () => {
    it('should_start_editing_with_the_current_name', () => {
      const fixture = setup();
      fixture.detectChanges();

      fixture.componentInstance.startEditName();

      expect(fixture.componentInstance.isEditingName()).toBe(true);
      expect(fixture.componentInstance.editedName()).toBe('Ada Lovelace');
    });

    it('should_cancel_editing_and_clear_the_edited_name', () => {
      const fixture = setup();
      fixture.detectChanges();
      fixture.componentInstance.startEditName();

      fixture.componentInstance.cancelEditName();

      expect(fixture.componentInstance.isEditingName()).toBe(false);
      expect(fixture.componentInstance.editedName()).toBe('');
    });

    it('should_save_the_trimmed_name_and_stop_editing', async () => {
      const fixture = setup();
      fixture.detectChanges();
      fixture.componentInstance.startEditName();
      fixture.componentInstance.editedName.set('  Grace Hopper  ');

      await fixture.componentInstance.onSaveName();

      expect(userServiceMock.updateProfile).toHaveBeenCalledWith({ name: 'Grace Hopper' });
      expect(fixture.componentInstance.isEditingName()).toBe(false);
    });

    it('should_not_save_when_the_trimmed_name_is_empty', async () => {
      const fixture = setup();
      fixture.detectChanges();
      fixture.componentInstance.startEditName();
      fixture.componentInstance.editedName.set('   ');

      await fixture.componentInstance.onSaveName();

      expect(userServiceMock.updateProfile).not.toHaveBeenCalled();
    });

    it('should_set_error_message_when_saving_the_name_fails', async () => {
      const fixture = setup();
      userServiceMock.updateProfile.mockReturnValue(throwError(() => new Error('boom')));
      fixture.detectChanges();
      fixture.componentInstance.startEditName();
      fixture.componentInstance.editedName.set('Grace Hopper');

      await fixture.componentInstance.onSaveName();

      expect(fixture.componentInstance.errorMessage()).toBe(
        'Impossible de sauvegarder le nom. Veuillez réessayer.',
      );
    });
  });

  describe('export', () => {
    it('should_export_json_once_at_a_time', async () => {
      const fixture = setup();
      fixture.detectChanges();

      const promise = fixture.componentInstance.onExportJson();
      const concurrent = fixture.componentInstance.onExportJson();
      await Promise.all([promise, concurrent]);

      expect(userExportServiceMock.exportJson).toHaveBeenCalledTimes(1);
      expect(fixture.componentInstance.isExportingJson()).toBe(false);
    });

    it('should_set_error_message_when_json_export_fails', async () => {
      const fixture = setup();
      userExportServiceMock.exportJson.mockReturnValue(throwError(() => new Error('boom')));
      fixture.detectChanges();

      await fixture.componentInstance.onExportJson();

      expect(fixture.componentInstance.errorMessage()).toBe(
        "Erreur lors de l'export JSON. Veuillez réessayer.",
      );
    });

    it('should_export_csv_once_at_a_time', async () => {
      const fixture = setup();
      fixture.detectChanges();

      const promise = fixture.componentInstance.onExportCsv();
      const concurrent = fixture.componentInstance.onExportCsv();
      await Promise.all([promise, concurrent]);

      expect(userExportServiceMock.exportCsv).toHaveBeenCalledTimes(1);
      expect(fixture.componentInstance.isExportingCsv()).toBe(false);
    });

    it('should_set_error_message_when_csv_export_fails', async () => {
      const fixture = setup();
      userExportServiceMock.exportCsv.mockReturnValue(throwError(() => new Error('boom')));
      fixture.detectChanges();

      await fixture.componentInstance.onExportCsv();

      expect(fixture.componentInstance.errorMessage()).toBe(
        "Erreur lors de l'export CSV. Veuillez réessayer.",
      );
    });
  });

  describe('onLogout()', () => {
    it('should_call_authService_logout', () => {
      const fixture = setup();
      fixture.detectChanges();

      fixture.componentInstance.onLogout();

      expect(authServiceMock.logout).toHaveBeenCalled();
    });

    it('should_navigate_to_auth_when_logout_throws', () => {
      const fixture = setup();
      authServiceMock.logout.mockImplementation(() => {
        throw new Error('boom');
      });
      fixture.detectChanges();
      const router = TestBed.inject(Router);
      const navigateSpy = vi.spyOn(router, 'navigate');

      fixture.componentInstance.onLogout();

      expect(navigateSpy).toHaveBeenCalledWith(['/auth']);
    });
  });
});
