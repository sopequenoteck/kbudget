import { ChangeDetectionStrategy, Component, booleanAttribute, computed, input } from '@angular/core';

// Squelette de chargement d'une liste, en classes k-skeleton-* de k-patterns.css (KKS-619) :
// `count` lignes dans un `.k-list-group`, precedees du squelette de hero quand `hero` est pose.
// `small` ajoute la seconde ligne de droite des listes a montant et date.
// L'hote est en display: contents : le DOM rendu est celui des anciens blocs inline des pages.
@Component({
  selector: 'app-list-skeleton',
  standalone: true,
  templateUrl: './list-skeleton.html',
  styleUrl: './list-skeleton.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ListSkeleton {
  readonly count = input.required<number>();
  readonly hero = input(false, { transform: booleanAttribute });
  readonly small = input(false, { transform: booleanAttribute });

  readonly items = computed(() => Array.from({ length: this.count() }));
}
