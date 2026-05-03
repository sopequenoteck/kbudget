import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api';
import {
  Invitation,
  InvitationCreated,
  CreateInvitationRequest,
} from '../models/invitation.model';
import { AdminUser } from '../models/user.model';

@Injectable({
  providedIn: 'root',
})
export class AdminService {
  private readonly api = inject(ApiService);

  createInvitation(req: CreateInvitationRequest): Observable<InvitationCreated> {
    return this.api.post<InvitationCreated>('/admin/invitations', req);
  }

  listInvitations(): Observable<Invitation[]> {
    return this.api.get<Invitation[]>('/admin/invitations');
  }

  revokeInvitation(id: number): Observable<void> {
    return this.api.delete<void>(`/admin/invitations/${id}`);
  }

  listUsers(): Observable<AdminUser[]> {
    return this.api.get<AdminUser[]>('/admin/users');
  }

  disableUser(id: string): Observable<void> {
    return this.api.patch<void>(`/admin/users/${id}/disable`, {});
  }

  enableUser(id: string): Observable<void> {
    return this.api.patch<void>(`/admin/users/${id}/enable`, {});
  }
}
