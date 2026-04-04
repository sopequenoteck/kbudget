import { Injectable, signal } from '@angular/core';

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
  readonly isOpen = signal(false);
  readonly config = signal<ConfirmConfig | null>(null);

  private resolveCallback: ((value: boolean) => void) | null = null;

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
      confirmLabel: options.confirmLabel ?? 'Confirmer',
      cancelLabel: options.cancelLabel ?? 'Annuler',
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
