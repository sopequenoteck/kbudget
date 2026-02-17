import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';

@Component({
  selector: 'app-placeholder',
  imports: [RouterLink],
  templateUrl: './placeholder.html',
  styleUrl: './placeholder.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Placeholder {
  private readonly route = inject(ActivatedRoute);

  readonly title = this.route.snapshot.data['title'] as string;
  readonly icon = this.route.snapshot.data['icon'] as string;
}
