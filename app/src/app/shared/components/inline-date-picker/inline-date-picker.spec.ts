import { TestBed } from '@angular/core/testing';

import { InlineDatePicker } from './inline-date-picker';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

describe('InlineDatePicker', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [InlineDatePicker],
      providers: [...provideTranslocoTesting()],
    });
  });

  it('should_create_the_component', () => {
    const fixture = TestBed.createComponent(InlineDatePicker);
    fixture.detectChanges();

    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_derive_french_day_initials_from_the_active_locale', () => {
    const fixture = TestBed.createComponent(InlineDatePicker);
    fixture.detectChanges();

    expect(fixture.componentInstance.dayHeaders()).toEqual(['L', 'M', 'M', 'J', 'V', 'S', 'D']);
  });

  it('should_render_french_month_name_when_navigated_to_march', () => {
    const fixture = TestBed.createComponent(InlineDatePicker);
    fixture.detectChanges();
    fixture.componentInstance.currentYear.set(2026);
    fixture.componentInstance.currentMonth.set(2); // Mars

    expect(fixture.componentInstance.monthLabel()).toBe('Mars 2026');
  });

  it('should_go_to_previous_month_when_prevMonth_called', () => {
    const fixture = TestBed.createComponent(InlineDatePicker);
    fixture.detectChanges();
    fixture.componentInstance.currentYear.set(2026);
    fixture.componentInstance.currentMonth.set(2); // Mars

    fixture.componentInstance.prevMonth();

    expect(fixture.componentInstance.monthLabel()).toBe('Février 2026');
  });

  it('should_go_to_previous_year_when_prevMonth_called_on_january', () => {
    const fixture = TestBed.createComponent(InlineDatePicker);
    fixture.detectChanges();
    fixture.componentInstance.currentYear.set(2026);
    fixture.componentInstance.currentMonth.set(0); // Janvier

    fixture.componentInstance.prevMonth();

    expect(fixture.componentInstance.monthLabel()).toBe('Décembre 2025');
  });

  it('should_go_to_next_month_when_nextMonth_called', () => {
    const fixture = TestBed.createComponent(InlineDatePicker);
    fixture.detectChanges();
    fixture.componentInstance.currentYear.set(2026);
    fixture.componentInstance.currentMonth.set(2); // Mars

    fixture.componentInstance.nextMonth();

    expect(fixture.componentInstance.monthLabel()).toBe('Avril 2026');
  });

  it('should_go_to_next_year_when_nextMonth_called_on_december', () => {
    const fixture = TestBed.createComponent(InlineDatePicker);
    fixture.detectChanges();
    fixture.componentInstance.currentYear.set(2026);
    fixture.componentInstance.currentMonth.set(11); // Decembre

    fixture.componentInstance.nextMonth();

    expect(fixture.componentInstance.monthLabel()).toBe('Janvier 2027');
  });

  it('should_select_day_when_not_disabled', () => {
    const fixture = TestBed.createComponent(InlineDatePicker);
    fixture.detectChanges();
    fixture.componentInstance.currentYear.set(2026);
    fixture.componentInstance.currentMonth.set(2); // Mars

    const day = fixture.componentInstance
      .calendarDays()
      .find((d) => d.isoDate === '2026-03-20')!;
    fixture.componentInstance.selectDay(day);

    expect(fixture.componentInstance.value()).toBe('2026-03-20');
  });

  it('should_not_select_day_when_disabled', () => {
    const fixture = TestBed.createComponent(InlineDatePicker);
    fixture.componentRef.setInput('min', '2026-03-10');
    fixture.detectChanges();
    fixture.componentInstance.currentYear.set(2026);
    fixture.componentInstance.currentMonth.set(2); // Mars

    const day = fixture.componentInstance
      .calendarDays()
      .find((d) => d.isoDate === '2026-03-01')!;
    fixture.componentInstance.selectDay(day);

    expect(fixture.componentInstance.value()).toBe('');
  });

  it('should_render_french_navigation_aria_labels_and_hint', () => {
    const fixture = TestBed.createComponent(InlineDatePicker);
    fixture.detectChanges();

    const [prevBtn, , nextBtn] = fixture.nativeElement.querySelectorAll('.idp__nav-btn, .idp__month-label');
    const monthLabelBtn: HTMLButtonElement = fixture.nativeElement.querySelector('.idp__month-label');

    expect(prevBtn.getAttribute('aria-label')).toBe('Mois précédent');
    expect(nextBtn.getAttribute('aria-label')).toBe('Mois suivant');
    expect(monthLabelBtn.getAttribute('title')).toBe('Revenir au mois actuel');
  });
});
