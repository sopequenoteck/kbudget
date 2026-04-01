import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorCaretLeft,
  phosphorCircleHalf,
  phosphorMoon,
  phosphorSun,
} from '@ng-icons/phosphor-icons/regular';

import { ThemeService, type Theme } from '../../../../core/services/theme';
import { TextScaleService, type TextScale } from '../../../../core/services/text-scale';

@Component({
  selector: 'app-appearance',
  imports: [RouterLink, NgIcon],
  viewProviders: [provideIcons({ phosphorCaretLeft, phosphorCircleHalf, phosphorMoon, phosphorSun })],
  templateUrl: './appearance.html',
  styleUrl: './appearance.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Appearance {
  private readonly themeService = inject(ThemeService);
  readonly textScaleService = inject(TextScaleService);

  readonly currentTheme = this.themeService.currentTheme;
  readonly currentTextScale = this.textScaleService.currentTextScale;

  setTheme(theme: Theme): void {
    this.themeService.setTheme(theme);
  }

  setTextScale(scale: TextScale): void {
    this.textScaleService.setTextScale(scale);
  }
}
