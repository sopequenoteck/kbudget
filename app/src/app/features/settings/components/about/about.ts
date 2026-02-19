import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import packageJson from '../../../../../../package.json';

@Component({
  selector: 'app-about',
  imports: [RouterLink],
  templateUrl: './about.html',
  styleUrl: './about.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class About {
  readonly appName = 'K-Budget';
  readonly version = packageJson.version;
  readonly author = 'Kelly SOSSOE - KKSDEV';
}
