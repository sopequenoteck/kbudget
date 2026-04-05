import { Signal, signal } from '@angular/core';
import { AbstractControl } from '@angular/forms';

/**
 * Crée un signal qui mesure dynamiquement la largeur d'un montant
 * en fonction de la font-size du champ input.
 */
export function createAmountWidth(
  control: AbstractControl,
  fontSize: number = 30
): Signal<string> {
  const width = signal('2ch');
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d')!;
  ctx.font = `bold ${fontSize}px Inter, sans-serif`;

  control.valueChanges.subscribe((val) => {
    const text = val || '0';
    const measured = ctx.measureText(text).width;
    width.set(`${Math.ceil(measured) + 4}px`);
  });

  return width;
}
