import {
  Directive,
  ElementRef,
  afterNextRender,
  inject,
  input,
  DestroyRef,
} from '@angular/core';

@Directive({
  selector: '[appAutoFitText]',
  standalone: true,
})
export class AutoFitTextDirective {
  private readonly el = inject(ElementRef<HTMLElement>);
  private readonly destroyRef = inject(DestroyRef);

  readonly minSize = input(10);

  constructor() {
    afterNextRender(() => this.init());
  }

  private init(): void {
    const el = this.el.nativeElement;
    const parent = el.parentElement;
    if (!parent) return;

    // Force display block pour avoir un width fiable
    el.style.display = 'block';
    el.style.overflow = 'hidden';

    const fit = () => requestAnimationFrame(() => this.fitText(el));

    fit();

    const observer = new ResizeObserver(fit);
    observer.observe(parent);

    this.destroyRef.onDestroy(() => observer.disconnect());
  }

  private fitText(el: HTMLElement): void {
    const min = this.minSize();

    // Reset à la taille CSS (respecte le text-scale)
    el.style.fontSize = '';
    let size = parseFloat(getComputedStyle(el).fontSize);
    el.style.fontSize = `${size}px`;

    while (el.scrollWidth > el.clientWidth && size > min) {
      size -= 0.5;
      el.style.fontSize = `${size}px`;
    }
  }
}
