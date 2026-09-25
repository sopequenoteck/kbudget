import { TestBed } from '@angular/core/testing';

import { Modal } from './modal';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

describe('Modal', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [Modal],
      providers: [...provideTranslocoTesting()],
    });
  });

  it('should_create_the_component', () => {
    const fixture = TestBed.createComponent(Modal);
    fixture.componentRef.setInput('isOpen', true);
    fixture.componentRef.setInput('title', 'Titre');
    fixture.detectChanges();

    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_render_french_close_button_aria_label_when_header_visible', () => {
    const fixture = TestBed.createComponent(Modal);
    fixture.componentRef.setInput('isOpen', true);
    fixture.componentRef.setInput('title', 'Titre');
    fixture.detectChanges();

    const closeBtn: HTMLButtonElement = fixture.nativeElement.querySelector('.modal-close');

    expect(closeBtn.getAttribute('aria-label')).toBe('Fermer');
  });

  it('should_emit_closed_when_close_button_clicked', () => {
    const fixture = TestBed.createComponent(Modal);
    fixture.componentRef.setInput('isOpen', true);
    fixture.componentRef.setInput('title', 'Titre');
    fixture.detectChanges();

    const emitSpy = vi.fn();
    fixture.componentInstance.closed.subscribe(emitSpy);

    const closeBtn: HTMLButtonElement = fixture.nativeElement.querySelector('.modal-close');
    closeBtn.click();

    expect(emitSpy).toHaveBeenCalled();
  });
});
