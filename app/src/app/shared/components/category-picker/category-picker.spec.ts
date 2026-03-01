import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { of } from 'rxjs';

import { CategoryPicker } from './category-picker';
import { CategoryService } from '../../../core/services/category';
import { Category } from '../../../core/models/category.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockCategories: Category[] = [
  { id: 'cat-1', nom: 'Alimentation', icone: '🍔', couleur: '#ef4444', isSystem: false },
  { id: 'cat-2', nom: 'Transport', icone: '🚗', couleur: '#3b82f6', isSystem: false },
  { id: 'cat-3', nom: 'Abonnement', icone: '🔄', couleur: '#6366f1', isSystem: true },
];

describe('CategoryPicker', () => {
  let categoryServiceMock: {
    getAll: ReturnType<typeof vi.fn>;
    refreshTrigger: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    categoryServiceMock = {
      getAll: vi.fn().mockReturnValue(of(mockCategories)),
      refreshTrigger: vi.fn().mockReturnValue(0),
    };

    TestBed.configureTestingModule({
      imports: [CategoryPicker],
      providers: [{ provide: CategoryService, useValue: categoryServiceMock }],
    });
  });

  it('should create the component', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should load categories from service', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    expect(categoryServiceMock.getAll).toHaveBeenCalled();
  });

  it('should transform categories to SelectPickerItems', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const items = fixture.componentInstance.categoryItems();
    expect(items).toHaveLength(3);
    expect(items[0]).toEqual({
      id: 'cat-1',
      label: 'Alimentation',
      icon: '🍔',
      secondaryText: null,
      color: null,
    });
  });

  it('should emit categoryId via CVA on picker change', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let emittedValue = '';
    component.registerOnChange((value: string) => {
      emittedValue = value;
    });

    component.onPickerChange('cat-1');

    expect(emittedValue).toBe('cat-1');
    expect(component.selectedCategoryId()).toBe('cat-1');
  });

  it('should show create button when no exact match', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.searchTerm.set('Nouveau');

    expect(component.hasExactMatch()).toBe(false);
  });

  it('should not show create button when exact match exists', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.searchTerm.set('alimentation');

    expect(component.hasExactMatch()).toBe(true);
  });

  it('should open create modal', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.openCreateModal();

    expect(component.showCreateModal()).toBe(true);
  });

  it('should handle category saved', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let emittedValue = '';
    component.registerOnChange((value: string) => {
      emittedValue = value;
    });

    const newCategory: Category = {
      id: 'cat-new',
      nom: 'Nouveau',
      icone: '✨',
      couleur: '#000',
      isSystem: false,
    };

    component.openCreateModal();
    component.onCategorySaved(newCategory);

    expect(component.showCreateModal()).toBe(false);
    expect(emittedValue).toBe('cat-new');
    expect(component.categories()).toHaveLength(4);
  });

  it('should track search term changes', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.onSearchTermChange('test');

    expect(component.searchTerm()).toBe('test');
  });
});
