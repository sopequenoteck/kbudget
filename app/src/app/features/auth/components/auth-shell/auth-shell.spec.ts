import { TestBed } from '@angular/core/testing';
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { By } from '@angular/platform-browser';

import { AuthShell } from './auth-shell';

@Component({
  standalone: true,
  imports: [AuthShell],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <app-auth-shell [title]="title" [tagline]="tagline" [error]="error" [size]="size">
      <span class="projected-content">contenu projeté</span>
    </app-auth-shell>
  `,
})
class TestHostComponent {
  title = 'K-Budget';
  tagline = '';
  error = '';
  size: 'sm' | 'md' = 'sm';
}

describe('AuthShell', () => {
  beforeEach(async () => {
    TestBed.configureTestingModule({
      imports: [TestHostComponent],
    });
  });

  it('should_render_title_when_input_provided', () => {
    // Arrange
    const fixture = TestBed.createComponent(TestHostComponent);
    fixture.componentInstance.title = 'K-Budget';

    // Act
    fixture.detectChanges();

    // Assert
    const titleEl = fixture.debugElement.query(By.css('.auth-shell__title'));
    expect(titleEl).not.toBeNull();
    expect(titleEl.nativeElement.textContent.trim()).toBe('K-Budget');
  });

  it('should_render_tagline_when_input_provided', () => {
    // Arrange
    const fixture = TestBed.createComponent(TestHostComponent);
    fixture.componentInstance.tagline = 'Connectez-vous à votre compte';

    // Act
    fixture.detectChanges();

    // Assert
    const taglineEl = fixture.debugElement.query(By.css('.auth-shell__tagline'));
    expect(taglineEl).not.toBeNull();
    expect(taglineEl.nativeElement.textContent.trim()).toBe('Connectez-vous à votre compte');
  });

  it('should_not_render_tagline_when_input_empty', () => {
    // Arrange
    const fixture = TestBed.createComponent(TestHostComponent);
    fixture.componentInstance.tagline = '';

    // Act
    fixture.detectChanges();

    // Assert
    const taglineEl = fixture.debugElement.query(By.css('.auth-shell__tagline'));
    expect(taglineEl).toBeNull();
  });

  it('should_render_error_when_input_provided', () => {
    // Arrange
    const fixture = TestBed.createComponent(TestHostComponent);
    fixture.componentInstance.error = 'Email ou mot de passe incorrect';

    // Act
    fixture.detectChanges();

    // Assert
    const errorEl = fixture.debugElement.query(By.css('.auth-shell__error'));
    expect(errorEl).not.toBeNull();
    expect(errorEl.nativeElement.textContent.trim()).toBe('Email ou mot de passe incorrect');
    expect(errorEl.nativeElement.getAttribute('role')).toBe('alert');
  });

  it('should_not_render_error_when_input_empty', () => {
    // Arrange
    const fixture = TestBed.createComponent(TestHostComponent);
    fixture.componentInstance.error = '';

    // Act
    fixture.detectChanges();

    // Assert
    const errorEl = fixture.debugElement.query(By.css('.auth-shell__error'));
    expect(errorEl).toBeNull();
  });

  it('should_apply_md_modifier_when_size_is_md', () => {
    // Arrange
    const fixture = TestBed.createComponent(TestHostComponent);
    fixture.componentInstance.size = 'md';

    // Act
    fixture.detectChanges();

    // Assert
    const mainEl = fixture.debugElement.query(By.css('.auth-shell__main'));
    expect(mainEl.classes['auth-shell__main--md']).toBe(true);
  });

  it('should_default_to_sm_size_when_size_not_provided', () => {
    // Arrange
    const fixture = TestBed.createComponent(TestHostComponent);
    // size defaults to 'sm' — not set explicitly

    // Act
    fixture.detectChanges();

    // Assert
    const mainEl = fixture.debugElement.query(By.css('.auth-shell__main'));
    expect(mainEl.classes['auth-shell__main--md']).toBeFalsy();
  });

  it('should_project_content_in_card', () => {
    // Arrange
    const fixture = TestBed.createComponent(TestHostComponent);

    // Act
    fixture.detectChanges();

    // Assert
    const projected = fixture.debugElement.query(By.css('.projected-content'));
    expect(projected).not.toBeNull();
    expect(projected.nativeElement.textContent.trim()).toBe('contenu projeté');
  });
});
