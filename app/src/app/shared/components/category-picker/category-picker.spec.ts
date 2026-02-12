import { getTestBed, TestBed } from '@angular/core/testing';
import {
  BrowserTestingModule,
  platformBrowserTesting,
} from '@angular/platform-browser/testing';
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
      providers: [
        { provide: CategoryService, useValue: categoryServiceMock },
      ],
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

  it('should filter categories by search term', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.searchTerm.set('ali');

    const filtered = component.filteredCategories();
    expect(filtered).toHaveLength(1);
    expect(filtered[0].nom).toBe('Alimentation');
  });

  it('should emit categoryId on selection', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let emittedValue = '';
    component.registerOnChange((value: string) => {
      emittedValue = value;
    });

    component.selectCategory(mockCategories[0]);

    expect(emittedValue).toBe('cat-1');
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

  it('should show empty state when no categories match', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.searchTerm.set('zzzzz');

    expect(component.filteredCategories()).toHaveLength(0);
  });

  it('should close dropdown on escape key', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.isOpen.set(true);
    component.onKeydown(new KeyboardEvent('keydown', { key: 'Escape' }));

    expect(component.isOpen()).toBe(false);
  });

  it('should clear selection', () => {
    const fixture = TestBed.createComponent(CategoryPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let emittedValue: string | undefined;
    component.registerOnChange((value: string) => {
      emittedValue = value;
    });

    component.selectCategory(mockCategories[0]);
    component.clearSelection();

    expect(emittedValue).toBe('');
    expect(component.selectedCategoryId()).toBe('');
  });
});
