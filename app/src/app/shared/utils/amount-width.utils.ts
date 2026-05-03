import { Signal, computed } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { AbstractControl } from '@angular/forms';

/**
 * Crée un signal qui mesure dynamiquement la largeur d'un montant
 * en fonction de la font-size du champ input.
 */
export function createAmountWidth(
  control: AbstractControl,
  fontSize = 30
): Signal<string> {
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  if (ctx) {
    ctx.font = `bold ${fontSize}px Inter, sans-serif`;
  }

  const val = toSignal(control.valueChanges, { initialValue: control.value || '0' });

  return computed(() => {
    const text = val() || '0';
    const measured = ctx ? ctx.measureText(text).width : text.length * fontSize * 0.6;
    return `${Math.ceil(measured) + 4}px`;
  });
}
