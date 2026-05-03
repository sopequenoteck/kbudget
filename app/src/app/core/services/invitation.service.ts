import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api';
import { AcceptInviteRequest, InviteLookup } from '../models/invitation.model';
import { AuthResponse } from '../models/auth.model';

@Injectable({
  providedIn: 'root',
})
export class InvitationService {
  private readonly api = inject(ApiService);

  lookup(token: string): Observable<InviteLookup> {
    return this.api.get<InviteLookup>(`/auth/invitations/${token}`);
  }

  accept(req: AcceptInviteRequest): Observable<AuthResponse> {
    return this.api.post<AuthResponse>('/auth/accept-invite', req);
  }
}
