import { TestBed } from '@angular/core/testing';

import { ModalService, type ModalType } from './modal.service';
import { type Account, AccountType } from '../models/account.model';

const mockAccount: Account = {
  id: '1',
  nom: 'Courant',
  type: AccountType.COURANT,
  soldeInitial: 0,
  solde: 0,
  icone: '🏦',
  couleur: '#4f46e5',
  isDefault: false,
  actif: true,
  currency: 'EUR',
  bankCode: 'OTHER',
  bankName: null,
  bankCountry: null,
  bankBrandColor: null,
  bankLogoUrl: null,
  bankCustomName: null,
  bankCustomLogo: null,
};

describe('ModalService', () => {
  let service: ModalService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [ModalService],
    });
    service = TestBed.inject(ModalService);
  });

  describe('modalTitleKey', () => {
    it('should_return_null_when_no_modal_open', () => {
      expect(service.modalTitleKey()).toBeNull();
    });

    const createTitleKeys: Record<ModalType, string> = {
      transaction: 'transactions.dialog.createTitle',
      subscription: 'subscriptions.dialog.createTitle',
      debt: 'debts.dialog.createTitle',
      category: 'categories.dialog.createTitle',
      account: 'accounts.dialog.createTitle',
      transfer: 'transactions.dialog.transferCreateTitle',
      budget: 'budgets.dialog.createTitle',
      repay: 'debts.dialog.repayTitle',
    };

    it.each(Object.entries(createTitleKeys))(
      'should_return_create_title_key_when_opening_%s_without_entity',
      (type, expected) => {
        service.openModal(type as ModalType);

        expect(service.modalTitleKey()).toBe(expected);
      },
    );

    const editTitleKeys: Record<ModalType, string> = {
      transaction: 'transactions.dialog.editTitle',
      subscription: 'subscriptions.dialog.editTitle',
      debt: 'debts.dialog.editTitle',
      category: 'categories.dialog.editTitle',
      account: 'accounts.dialog.editTitle',
      transfer: 'transactions.dialog.transferEditTitle',
      budget: 'budgets.dialog.editTitle',
      repay: 'debts.dialog.repayTitle',
    };

    it.each(Object.entries(editTitleKeys))(
      'should_return_edit_title_key_when_opening_%s_with_entity',
      (type, expected) => {
        service.openModal(type as ModalType, mockAccount);

        expect(service.modalTitleKey()).toBe(expected);
      },
    );
  });

  describe('openModal() / closeModal() / resetModal()', () => {
    it('should_open_modal_with_entity_and_options', () => {
      service.openModal('account', mockAccount, { asRecurring: true });

      expect(service.activeModal()).toBe('account');
      expect(service.editingEntity()).toBe(mockAccount);
      expect(service.asRecurring()).toBe(true);
      expect(service.modalOpen()).toBe(true);
    });

    it('should_close_modal_after_delay', async () => {
      vi.useFakeTimers();
      service.openModal('account', mockAccount);

      service.closeModal();
      expect(service.isClosing()).toBe(true);

      vi.advanceTimersByTime(200);

      expect(service.activeModal()).toBeNull();
      expect(service.editingEntity()).toBeNull();
      expect(service.isClosing()).toBe(false);
      vi.useRealTimers();
    });

    it('should_do_nothing_when_closeModal_called_and_no_modal_open', () => {
      service.closeModal();

      expect(service.isClosing()).toBe(false);
    });

    it('should_reset_modal_immediately', () => {
      vi.useFakeTimers();
      service.openModal('account', mockAccount);
      service.closeModal();

      service.resetModal();

      expect(service.activeModal()).toBeNull();
      expect(service.editingEntity()).toBeNull();
      expect(service.isClosing()).toBe(false);
      vi.useRealTimers();
    });
  });
});
