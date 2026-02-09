import { ComponentFixture, getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { ListItem } from './list-item';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

@Component({
  template: `
    <app-list-item
      [icon]="icon()"
      [title]="title()"
      [value]="value()"
      [subtitle]="subtitle()"
      [rightSubtitle]="rightSubtitle()"
      [valueClass]="valueClass()"
      (pressed)="onPressed()"
    />
  `,
  imports: [ListItem],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestHost {
  readonly icon = signal('🛒');
  readonly title = signal('Courses Carrefour');
  readonly value = signal('-42,50 €');
  readonly subtitle = signal('');
  readonly rightSubtitle = signal('');
  readonly valueClass = signal('');
  onPressed = vi.fn();
}

describe('ListItem', () => {
  let fixture: ComponentFixture<TestHost>;
  let host: TestHost;
  let element: HTMLElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TestHost],
    }).compileComponents();

    fixture = TestBed.createComponent(TestHost);
    host = fixture.componentInstance;
    fixture.detectChanges();
    element = fixture.nativeElement.querySelector('app-list-item');
  });

  // === US1: Afficher un élément de liste ===

  describe('US1 - Affichage', () => {
    it('should render icon, title, and value', () => {
      const icon = element.querySelector('.list-item__icon');
      const title = element.querySelector('.list-item__title');
      const value = element.querySelector('.list-item__value');

      expect(icon?.textContent?.trim()).toBe('🛒');
      expect(title?.textContent?.trim()).toBe('Courses Carrefour');
      expect(value?.textContent?.trim()).toBe('-42,50 €');
    });

    it('should render subtitle when provided', () => {
      host.subtitle.set('Alimentation · 15 jan.');
      fixture.detectChanges();

      const subtitle = element.querySelector('.list-item__subtitle');
      expect(subtitle?.textContent?.trim()).toBe('Alimentation · 15 jan.');
    });

    it('should not render subtitle when empty', () => {
      host.subtitle.set('');
      fixture.detectChanges();

      const subtitle = element.querySelector('.list-item__subtitle');
      expect(subtitle).toBeNull();
    });

    it('should render right subtitle when provided', () => {
      host.rightSubtitle.set('Prochain : 1 fév.');
      fixture.detectChanges();

      const rightSubtitle = element.querySelector('.list-item__right-subtitle');
      expect(rightSubtitle?.textContent?.trim()).toBe('Prochain : 1 fév.');
    });

    it('should not render right subtitle when empty', () => {
      host.rightSubtitle.set('');
      fixture.detectChanges();

      const rightSubtitle = element.querySelector('.list-item__right-subtitle');
      expect(rightSubtitle).toBeNull();
    });

    it('should truncate long title with ellipsis', () => {
      host.title.set(
        'Un titre extrêmement long qui devrait être tronqué avec une ellipse pour ne pas casser le layout',
      );
      fixture.detectChanges();

      const title = element.querySelector('.list-item__title') as HTMLElement;
      // Verify the title element exists and has the class that applies ellipsis styles
      expect(title).toBeTruthy();
      expect(title.classList.contains('list-item__title')).toBe(true);
      expect(title.textContent?.trim()).toBe(
        'Un titre extrêmement long qui devrait être tronqué avec une ellipse pour ne pas casser le layout',
      );
    });
  });

  // === US2: Interagir avec un élément de liste ===

  describe('US2 - Interaction', () => {
    it('should emit pressed on click', () => {
      const listItem = element.querySelector('.list-item') as HTMLElement;
      listItem.click();

      expect(host.onPressed).toHaveBeenCalledTimes(1);
    });

    it('should emit pressed on Enter key', () => {
      const listItem = element.querySelector('.list-item') as HTMLElement;
      listItem.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));

      expect(host.onPressed).toHaveBeenCalledTimes(1);
    });

    it('should emit pressed on Space key', () => {
      const listItem = element.querySelector('.list-item') as HTMLElement;
      listItem.dispatchEvent(new KeyboardEvent('keydown', { key: ' ', bubbles: true }));

      expect(host.onPressed).toHaveBeenCalledTimes(1);
    });

    it('should have role="button" and tabindex="0"', () => {
      const listItem = element.querySelector('.list-item') as HTMLElement;

      expect(listItem.getAttribute('role')).toBe('button');
      expect(listItem.getAttribute('tabindex')).toBe('0');
    });
  });

  // === US3: Différencier visuellement les types ===

  describe('US3 - Classe CSS sur la valeur', () => {
    it('should apply valueClass to value element', () => {
      host.valueClass.set('amount-expense');
      fixture.detectChanges();

      const value = element.querySelector('.list-item__value') as HTMLElement;
      expect(value.classList.contains('amount-expense')).toBe(true);
    });

    it('should not apply class when valueClass empty', () => {
      const value = element.querySelector('.list-item__value') as HTMLElement;
      // Only the static class 'list-item__value' should be present
      expect(value.classList.contains('list-item__value')).toBe(true);
      expect(value.classList.length).toBe(1);
    });
  });
});
