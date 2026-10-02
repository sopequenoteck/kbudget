import { TestBed } from '@angular/core/testing';

import { ShortDatePipe } from './short-date.pipe';
import { LanguageService } from '../../core/services/language';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

const toDateStr = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

describe('ShortDatePipe', () => {
  let languageServiceMock: { displayLocale: ReturnType<typeof vi.fn> };
  let pipe: ShortDatePipe;

  beforeEach(() => {
    languageServiceMock = {
      displayLocale: vi.fn().mockReturnValue('fr-FR'),
    };

    TestBed.configureTestingModule({
      providers: [
        { provide: LanguageService, useValue: languageServiceMock },
        ...provideTranslocoTesting(),
      ],
    });

    pipe = TestBed.runInInjectionContext(() => new ShortDatePipe());
  });

  it('should_return_empty_string_when_value_is_empty', () => {
    expect(pipe.transform('')).toBe('');
  });

  it('should_return_aujourdhui_when_value_is_today', () => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    expect(pipe.transform(toDateStr(today))).toBe("Aujourd'hui");
  });

  it('should_return_hier_when_value_is_yesterday', () => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);
    expect(pipe.transform(toDateStr(yesterday))).toBe('Hier');
  });

  it('should_return_demain_when_value_is_tomorrow', () => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(today.getDate() + 1);
    expect(pipe.transform(toDateStr(tomorrow))).toBe('Demain');
  });

  it('should_return_short_localized_date_when_value_is_far_in_the_future', () => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const farDate = new Date(today);
    farDate.setDate(today.getDate() + 45);
    const result = pipe.transform(toDateStr(farDate));
    expect(result).not.toBe('');
    expect(result).not.toBe("Aujourd'hui");
    expect(result).not.toBe('Demain');
    expect(languageServiceMock.displayLocale).toHaveBeenCalled();
  });

  it('should_use_locale_from_language_service_when_formatting_far_date', () => {
    languageServiceMock.displayLocale.mockReturnValue('en-US');
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const farDate = new Date(today);
    farDate.setDate(today.getDate() + 45);
    const resultEn = pipe.transform(toDateStr(farDate));

    languageServiceMock.displayLocale.mockReturnValue('fr-FR');
    const resultFr = pipe.transform(toDateStr(farDate));

    expect(resultEn).not.toBe(resultFr);
  });
});
