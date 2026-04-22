import { ChangeDetectionStrategy, Component, input } from '@angular/core';

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
}
