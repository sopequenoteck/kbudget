import {
  ChangeDetectionStrategy,
  Component,
  computed,
  input,
  model,
  signal,
} from '@angular/core';

interface CalendarDay {
  date: Date;
  dayNumber: number;
  isCurrentMonth: boolean;
  isToday: boolean;
  isSelected: boolean;
  isOriginal: boolean;
  isDisabled: boolean;
  isoDate: string;
}

const MONTH_NAMES = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

const DAY_HEADERS = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

function toIsoDate(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function isoToDate(iso: string): Date | null {
  if (!iso) return null;
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d);
}

@Component({
  selector: 'app-inline-date-picker',
  imports: [],
  templateUrl: './inline-date-picker.html',
  styleUrl: './inline-date-picker.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InlineDatePicker {
  readonly value = model<string>('');
  readonly originalValue = input<string>();
  readonly min = input<string>();
  readonly max = input<string>();

  readonly dayHeaders = DAY_HEADERS;

  private readonly today = new Date();
  private readonly todayIso = toIsoDate(this.today);

  private readonly _initMonth = (): { month: number; year: number } => {
    const v = this.value();
    if (v) {
      const d = isoToDate(v);
      if (d) return { month: d.getMonth(), year: d.getFullYear() };
    }
    return { month: this.today.getMonth(), year: this.today.getFullYear() };
  };

  readonly currentMonth = signal<number>(this._initMonth().month);
  readonly currentYear = signal<number>(this._initMonth().year);

  readonly monthLabel = computed(() => {
    const name = MONTH_NAMES[this.currentMonth()];
    return name.charAt(0).toUpperCase() + name.slice(1) + ' ' + this.currentYear();
  });

  readonly calendarDays = computed((): CalendarDay[] => {
    const month = this.currentMonth();
    const year = this.currentYear();
    const selectedIso = this.value();
    const originalIso = this.originalValue();
    const hasOriginal = !!originalIso;
    const hasChanged = hasOriginal && selectedIso !== originalIso;
    const minIso = this.min();
    const maxIso = this.max();

    const firstDay = new Date(year, month, 1);
    // Monday-first: getDay() returns 0=Sun, so Mon=1 → offset 0, Sun=0 → offset 6
    let startOffset = firstDay.getDay() - 1;
    if (startOffset < 0) startOffset = 6;

    const days: CalendarDay[] = [];

    // Days from previous month to fill first week
    for (let i = startOffset; i > 0; i--) {
      const date = new Date(year, month, 1 - i);
      const iso = toIsoDate(date);
      days.push({
        date,
        dayNumber: date.getDate(),
        isCurrentMonth: false,
        isToday: iso === this.todayIso,
        isSelected: false,
        isOriginal: false,
        isDisabled: true,
        isoDate: iso,
      });
    }

    // Days of current month
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    for (let d = 1; d <= daysInMonth; d++) {
      const date = new Date(year, month, d);
      const iso = toIsoDate(date);
      let isDisabled = false;
      if (minIso && iso < minIso) isDisabled = true;
      if (maxIso && iso > maxIso) isDisabled = true;
      const isSelected = hasOriginal ? (hasChanged ? iso === selectedIso : false) : iso === selectedIso;
      const isOriginal = hasOriginal ? iso === originalIso : false;
      days.push({
        date,
        dayNumber: d,
        isCurrentMonth: true,
        isToday: iso === this.todayIso,
        isSelected,
        isOriginal: isOriginal && !isSelected,
        isDisabled,
        isoDate: iso,
      });
    }

    // Days from next month to complete last week
    const remainder = days.length % 7;
    if (remainder > 0) {
      const toAdd = 7 - remainder;
      for (let i = 1; i <= toAdd; i++) {
        const date = new Date(year, month + 1, i);
        const iso = toIsoDate(date);
        days.push({
          date,
          dayNumber: i,
          isCurrentMonth: false,
          isToday: iso === this.todayIso,
          isSelected: false,
          isOriginal: false,
          isDisabled: true,
          isoDate: iso,
        });
      }
    }

    return days;
  });

  prevMonth(): void {
    const month = this.currentMonth();
    const year = this.currentYear();
    if (month === 0) {
      this.currentMonth.set(11);
      this.currentYear.set(year - 1);
    } else {
      this.currentMonth.set(month - 1);
    }
  }

  nextMonth(): void {
    const month = this.currentMonth();
    const year = this.currentYear();
    if (month === 11) {
      this.currentMonth.set(0);
      this.currentYear.set(year + 1);
    } else {
      this.currentMonth.set(month + 1);
    }
  }

  goToToday(): void {
    this.currentMonth.set(this.today.getMonth());
    this.currentYear.set(this.today.getFullYear());
  }

  selectDay(day: CalendarDay): void {
    if (day.isDisabled) return;
    this.value.set(day.isoDate);
  }
}
