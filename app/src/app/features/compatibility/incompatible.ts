import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';

import { AuthShell } from '../auth/components/auth-shell/auth-shell';
import { CompatibilityService } from '../../core/services/compatibility';

/**
 * Ecran affiche quand le client et le serveur ne peuvent pas fonctionner
 * ensemble (KKS-314).
 *
 * <p>Sa raison d'etre : sans lui, l'incompatibilite se manifeste par une erreur
 * de deserialisation JSON, chez un utilisateur qui n'a aucun moyen de
 * comprendre que son serveur est en cause. Le message doit donc nommer le
 * responsable et l'action, jamais exposer l'erreur technique.
 *
 * <p>N'est jamais affiche pour un serveur injoignable : hors ligne n'est pas
 * une incompatibilite.
 */
@Component({
  selector: 'app-incompatible',
  standalone: true,
  imports: [AuthShell],
  templateUrl: './incompatible.html',
  styleUrl: './incompatible.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Incompatible {
  private readonly compatibility = inject(CompatibilityService);

  protected readonly status = this.compatibility.status;

  protected readonly isClientTooOld = computed(
    () => this.status()?.kind === 'clientTooOld',
  );

  protected readonly title = computed(() =>
    this.isClientTooOld() ? 'Application à mettre à jour' : 'Serveur à mettre à jour',
  );

  /** Version en cause, ou null si le serveur est trop ancien pour l'annoncer. */
  protected readonly currentVersion = computed(() => {
    const s = this.status();
    if (s?.kind === 'clientTooOld') return s.clientVersion;
    if (s?.kind === 'serverTooOld') return s.serverVersion;
    return null;
  });

  protected readonly requiredVersion = computed(() => {
    const s = this.status();
    return s?.kind === 'clientTooOld' || s?.kind === 'serverTooOld'
      ? s.requiredVersion
      : null;
  });

  protected retry(): void {
    globalThis.location.reload();
  }
}
