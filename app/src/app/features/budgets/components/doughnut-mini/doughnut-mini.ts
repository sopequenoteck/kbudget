import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

export interface DoughnutSegment {
  value: number;
  color: string;
}

@Component({
  selector: 'app-doughnut-mini',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg [attr.width]="size()" [attr.height]="size()" [attr.viewBox]="viewBox()">
      @for (arc of arcs(); track $index) {
        <circle
          [attr.cx]="half()"
          [attr.cy]="half()"
          [attr.r]="radius()"
          fill="none"
          [attr.stroke]="arc.color"
          [attr.stroke-width]="strokeWidth()"
          [attr.stroke-dasharray]="arc.dashArray"
          [attr.stroke-dashoffset]="arc.dashOffset"
          stroke-linecap="butt"
          opacity="0.7"
        />
      }
    </svg>
  `,
  styles: `
    :host {
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
  `,
})
export class DoughnutMini {
  readonly segments = input.required<DoughnutSegment[]>();
  readonly size = input(130);
  readonly strokeWidth = input(22);
  readonly gap = input(3);

  readonly half = computed(() => this.size() / 2);
  readonly radius = computed(() => (this.size() - this.strokeWidth()) / 2);
  readonly circumference = computed(() => 2 * Math.PI * this.radius());
  readonly viewBox = computed(() => `0 0 ${this.size()} ${this.size()}`);

  readonly arcs = computed(() => {
    const segs = this.segments().filter((s) => s.value > 0);
    if (segs.length === 0) return [];

    const total = segs.reduce((sum, s) => sum + s.value, 0);
    if (total === 0) return [];

    const circ = this.circumference();
    const gapSize = this.gap();
    const totalGap = segs.length > 1 ? gapSize * segs.length : 0;
    const usable = circ - totalGap;
    let offset = -circ / 4;

    return segs.map((seg) => {
      const fraction = seg.value / total;
      const length = fraction * usable;
      const arc = {
        color: seg.color,
        dashArray: `${length} ${circ - length}`,
        dashOffset: `${-offset}`,
      };
      offset += length + (segs.length > 1 ? gapSize : 0);
      return arc;
    });
  });
}
