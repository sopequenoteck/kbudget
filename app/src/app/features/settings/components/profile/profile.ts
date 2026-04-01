import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorCalendar,
  phosphorCamera,
  phosphorCaretLeft,
  phosphorEnvelope,
  phosphorSignOut,
  phosphorUser,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';

import { AuthService } from '../../../../core/services/auth';
import { UserService } from '../../../../core/services/user';

@Component({
  selector: 'app-profile',
  imports: [RouterLink, NgIcon],
  viewProviders: [
    provideIcons({
      phosphorCalendar,
      phosphorCamera,
      phosphorCaretLeft,
      phosphorEnvelope,
      phosphorSignOut,
      phosphorUser,
    }),
  ],
  templateUrl: './profile.html',
  styleUrl: './profile.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Profile {
  private readonly authService = inject(AuthService);
  private readonly userService = inject(UserService);

  readonly currentUser = this.authService.currentUser;

  constructor() {
    firstValueFrom(this.userService.getProfile());
  }

  getInitials(name: string): string {
    return name
      .split(' ')
      .map(part => part[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  }
}
