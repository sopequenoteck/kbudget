import { ChangeDetectionStrategy, Component, input } from '@angular/core';

import packageJson from '../../../../../../package.json';

@Component({
  selector: 'app-auth-shell',
  standalone: true,
  templateUrl: './auth-shell.html',
  styleUrl: './auth-shell.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AuthShell {
  readonly size = input<'sm' | 'md'>('sm');
  readonly title = input.required<string>();
  readonly tagline = input<string>('');
  readonly error = input<string>('');

  protected readonly version = `v${packageJson.version}`;
}
