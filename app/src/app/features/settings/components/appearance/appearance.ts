import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { ThemeService, type Theme } from '../../../../core/services/theme';

@Component({
  selector: 'app-appearance',
  imports: [RouterLink],
  templateUrl: './appearance.html',
  styleUrl: './appearance.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Appearance {
  private readonly themeService = inject(ThemeService);

  readonly currentTheme = this.themeService.currentTheme;

  setTheme(theme: Theme): void {
    this.themeService.setTheme(theme);
  }
}
