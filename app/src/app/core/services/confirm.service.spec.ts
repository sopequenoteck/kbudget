import { TestBed } from '@angular/core/testing';

import { ConfirmService } from './confirm.service';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

describe('ConfirmService', () => {
  let service: ConfirmService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [ConfirmService, provideTranslocoTesting()],
    });
    service = TestBed.inject(ConfirmService);
  });

  describe('confirm', () => {
    it('should_default_confirm_and_cancel_labels_and_default_variant_when_not_provided', () => {
      void service.confirm({ title: 'Titre', message: 'Message' });

      expect(service.config()).toEqual({
        title: 'Titre',
        message: 'Message',
        confirmLabel: 'Confirmer',
        cancelLabel: 'Annuler',
        variant: 'default',
        icon: '',
      });
      expect(service.isOpen()).toBe(true);
    });

    it('should_resolve_true_when_resolved_with_true', async () => {
      const promise = service.confirm({ title: 'Titre', message: 'Message' });
      service.resolve(true);

      expect(await promise).toBe(true);
      expect(service.isOpen()).toBe(false);
      expect(service.config()).toBeNull();
    });

    it('should_resolve_false_when_resolved_with_false', async () => {
      const promise = service.confirm({ title: 'Titre', message: 'Message' });
      service.resolve(false);

      expect(await promise).toBe(false);
    });
  });

  describe('confirmDelete', () => {
    it('should_apply_danger_variant_and_translated_delete_label', () => {
      void service.confirmDelete({ title: 'Alice — 10,00 €', message: 'Voulez-vous vraiment ?', icon: 'phosphorTrash' });

      expect(service.config()).toEqual({
        title: 'Alice — 10,00 €',
        message: 'Voulez-vous vraiment ?',
        confirmLabel: 'Supprimer',
        cancelLabel: 'Annuler',
        variant: 'danger',
        icon: 'phosphorTrash',
      });
    });

    it('should_default_icon_to_empty_string_when_not_provided', () => {
      void service.confirmDelete({ title: 'Titre', message: 'Message' });

      expect(service.config()?.icon).toBe('');
    });

    it('should_resolve_the_returned_promise_when_confirmed', async () => {
      const promise = service.confirmDelete({ title: 'Titre', message: 'Message' });
      service.resolve(true);

      expect(await promise).toBe(true);
    });
  });
});
