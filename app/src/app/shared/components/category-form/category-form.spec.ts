import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of, throwError } from 'rxjs';

import { CategoryForm } from './category-form';
import { CategoryService } from '../../../core/services/category';
import { Category } from '../../../core/models/category.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockCategory: Category = {
  id: 'cat-1',
  nom: 'Alimentation',
  icone: '🍔',
  couleur: '#ef4444',
  isSystem: false,
};

describe('CategoryForm', () => {
  let categoryServiceMock: {
    create: ReturnType<typeof vi.fn>;
    update: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    categoryServiceMock = {
      create: vi.fn().mockReturnValue(of(mockCategory)),
      update: vi.fn().mockReturnValue(of(mockCategory)),
    };

    TestBed.configureTestingModule({
      imports: [CategoryForm],
      providers: [{ provide: CategoryService, useValue: categoryServiceMock }],
    });
  });

  it('should create the component', () => {
    const fixture = TestBed.createComponent(CategoryForm);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should pre-fill name in create mode from initialName', () => {
    const fixture = TestBed.createComponent(CategoryForm);
    fixture.componentRef.setInput('initialName', 'Test');
    fixture.detectChanges();

    const component = fixture.componentInstance;
    expect(component.form.getRawValue().nom).toBe('Test');
  });

  it('should pre-select random color in create mode', () => {
    const fixture = TestBed.createComponent(CategoryForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    expect(component.selectedColor()).toBeTruthy();
    expect(component.selectedColor()).toMatch(/^#[0-9a-f]{6}$/);
  });

  it('should pre-fill fields in edit mode', () => {
    const fixture = TestBed.createComponent(CategoryForm);
    fixture.componentRef.setInput('category', mockCategory);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    expect(component.form.getRawValue().nom).toBe('Alimentation');
    expect(component.selectedEmoji()).toBe('🍔');
    expect(component.selectedColor()).toBe('#ef4444');
    expect(component.isEditMode).toBe(true);
  });

  it('should call update in edit mode on submit', async () => {
    const fixture = TestBed.createComponent(CategoryForm);
    fixture.componentRef.setInput('category', mockCategory);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.selectedEmoji.set('🍔');

    await component.onSubmit();

    expect(categoryServiceMock.update).toHaveBeenCalledWith('cat-1', {
      nom: 'Alimentation',
      icone: '🍔',
      couleur: '#ef4444',
    });
  });

  it('should call create in create mode on submit', async () => {
    const fixture = TestBed.createComponent(CategoryForm);
    fixture.componentRef.setInput('initialName', 'Loisirs');
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.selectedEmoji.set('🎮');

    await component.onSubmit();

    expect(categoryServiceMock.create).toHaveBeenCalled();
  });

  it('should reject empty name', async () => {
    const fixture = TestBed.createComponent(CategoryForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ nom: '' });
    component.selectedEmoji.set('🍔');

    await component.onSubmit();

    expect(categoryServiceMock.create).not.toHaveBeenCalled();
    expect(component.form.get('nom')?.touched).toBe(true);
  });

  it('should reject name exceeding 30 chars', () => {
    const fixture = TestBed.createComponent(CategoryForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ nom: 'a'.repeat(31) });

    expect(component.form.get('nom')?.hasError('maxlength')).toBe(true);
  });

  it('should not submit without emoji selected', async () => {
    const fixture = TestBed.createComponent(CategoryForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ nom: 'Test' });

    await component.onSubmit();

    expect(categoryServiceMock.create).not.toHaveBeenCalled();
  });

  it('should display error message on save failure', async () => {
    categoryServiceMock.create.mockReturnValue(throwError(() => new Error('Erreur réseau')));

    const fixture = TestBed.createComponent(CategoryForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.form.patchValue({ nom: 'Test' });
    component.selectedEmoji.set('🍔');

    await component.onSubmit();

    expect(component.errorMessage()).toBe('Erreur réseau');
  });

  it('should emit cancelled on cancel', () => {
    const fixture = TestBed.createComponent(CategoryForm);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let cancelled = false;
    component.cancelled.subscribe(() => {
      cancelled = true;
    });

    component.onCancel();

    expect(cancelled).toBe(true);
  });
});
