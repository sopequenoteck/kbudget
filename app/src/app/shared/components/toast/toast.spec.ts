import { TestBed } from '@angular/core/testing';

import { Toast } from './toast';
import { ToastService } from './toast.service';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

describe('Toast', () => {
  let toastService: ToastService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [Toast],
      providers: [...provideTranslocoTesting()],
    });
    toastService = TestBed.inject(ToastService);
  });

  it('should_create_the_component', () => {
    const fixture = TestBed.createComponent(Toast);
    fixture.detectChanges();

    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_render_french_close_button_aria_label_when_a_toast_is_shown', () => {
    toastService.success('Enregistré');
    const fixture = TestBed.createComponent(Toast);
    fixture.detectChanges();

    const closeBtn: HTMLButtonElement = fixture.nativeElement.querySelector('.toast-close');

    expect(closeBtn.getAttribute('aria-label')).toBe('Fermer');
  });

  it('should_dismiss_toast_when_close_button_clicked', () => {
    toastService.success('Enregistré');
    const fixture = TestBed.createComponent(Toast);
    fixture.detectChanges();

    const closeBtn: HTMLButtonElement = fixture.nativeElement.querySelector('.toast-close');
    closeBtn.click();

    expect(toastService.toasts()).toHaveLength(0);
  });
});
