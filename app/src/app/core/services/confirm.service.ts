import { Injectable, inject, signal } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';

export type ConfirmVariant = 'default' | 'danger';

export interface ConfirmConfig {
  title: string;
  message: string;
  confirmLabel: string;
  cancelLabel: string;
  variant: ConfirmVariant;
  icon: string;
}

@Injectable({ providedIn: 'root' })
export class ConfirmService {
  private readonly transloco = inject(TranslocoService);

  readonly isOpen = signal(false);
  readonly config = signal<ConfirmConfig | null>(null);

  private resolveCallback: ((value: boolean) => void) | null = null;

  /**
   * Raccourci pour la confirmation de suppression : applique systematiquement
   * `variant: 'danger'` et le libelle `common.action.delete`, repetes a
   * l'identique dans chaque `onDelete` (KKS-378).
   */
  confirmDelete(options: { title: string; message: string; icon?: string }): Promise<boolean> {
    return this.confirm({
      title: options.title,
      message: options.message,
      confirmLabel: this.transloco.translate('common.action.delete'),
      variant: 'danger',
      icon: options.icon,
    });
  }

  confirm(options: {
    title: string;
    message: string;
    confirmLabel?: string;
    cancelLabel?: string;
    variant?: ConfirmVariant;
    icon?: string;
  }): Promise<boolean> {
    this.config.set({
      title: options.title,
      message: options.message,
      confirmLabel: options.confirmLabel ?? this.transloco.translate('common.action.confirm'),
      cancelLabel: options.cancelLabel ?? this.transloco.translate('common.action.cancel'),
      variant: options.variant ?? 'default',
      icon: options.icon ?? '',
    });
    this.isOpen.set(true);

    return new Promise<boolean>((resolve) => {
      this.resolveCallback = resolve;
    });
  }

  resolve(value: boolean): void {
    this.isOpen.set(false);
    this.config.set(null);
    this.resolveCallback?.(value);
    this.resolveCallback = null;
  }
}
