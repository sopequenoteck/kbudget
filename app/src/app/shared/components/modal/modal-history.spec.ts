import { APP_BASE_HREF, PlatformLocation, BrowserPlatformLocation } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { TestBed, type ComponentFixture } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { provideNoopAnimations } from '@angular/platform-browser/animations';
import { NavigationEnd, Router, provideRouter } from '@angular/router';
import { of } from 'rxjs';

import { Modal } from './modal';
import { ConfirmDialog } from '../confirm-dialog/confirm-dialog';
import { SelectPicker } from '../select-picker/select-picker';
import { RepayDialog } from '../../../features/debts/components/repay-dialog/repay-dialog';
import { AccountService } from '../../../core/services/account';
import { ConfirmService } from '../../../core/services/confirm.service';
import { DebtService } from '../../../core/services/debt';
import { HistoryLayerService } from '../../../core/services/history-layer.service';
import { ModalService } from '../../../core/services/modal.service';
import { ToastService } from '../toast/toast.service';
import { type Account, AccountType } from '../../../core/models/account.model';
import { type Debt, DebtType } from '../../../core/models/debt.model';
import { goBack, resetHistory, settleHistory } from '../../../../testing/history-testing';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

const CLOSE_ANIMATION_MS = 250;

const account: Account = {
  id: 'acc-1',
  nom: 'Courant',
  type: AccountType.COURANT,
  soldeInitial: 1000,
  solde: 1500,
  icone: '🏦',
  couleur: '#3b82f6',
  isDefault: true,
  actif: true,
  currency: 'EUR',
};

const debt: Debt = {
  id: 'debt-1',
  personne: 'Bob',
  montant: 300,
  montantRestant: 200,
  sens: DebtType.EMPRUNT,
  date: '2026-01-01',
  dueDate: null,
  rembourse: false,
  category: null,
  currency: 'EUR',
  account: null,
  includeInBalance: false,
  reminderDate: null,
  reminderTime: null,
};

/** Feuille du shell : Modal + formulaire de remboursement + dialogue de confirmation. */
@Component({
  selector: 'app-sheet-host',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Modal, RepayDialog, ConfirmDialog],
  template: `
    <app-modal
      [isOpen]="modalService.modalOpen()"
      title="Remboursement"
      (closed)="modalService.closeModal()"
    >
      @if (modalService.activeModal() === 'repay') {
        <app-repay-dialog (cancelled)="modalService.closeModal()" />
      }
    </app-modal>
    <app-confirm-dialog />
  `,
})
class SheetHost {
  readonly modalService = inject(ModalService);
}

function wait(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

describe('Retour arriere sur les surfaces (KKS-447)', () => {
  let fixture: ComponentFixture<SheetHost>;
  let modalService: ModalService;

  const repay = (): RepayDialog =>
    fixture.debugElement.query(By.directive(RepayDialog)).componentInstance as RepayDialog;
  const picker = (): SelectPicker =>
    fixture.debugElement.query(By.directive(SelectPicker)).componentInstance as SelectPicker;
  const render = (): void => {
    fixture.detectChanges();
    TestBed.tick();
    fixture.detectChanges();
  };

  beforeEach(() => {
    resetHistory();
    TestBed.configureTestingModule({
      imports: [SheetHost],
      providers: [
        provideNoopAnimations(),
        provideTranslocoTesting(),
        { provide: Router, useValue: { currentNavigation: () => null } },
        { provide: DebtService, useValue: { repay: vi.fn() } },
        { provide: AccountService, useValue: { getAll: vi.fn().mockReturnValue(of([account])) } },
        { provide: ToastService, useValue: { success: vi.fn(), error: vi.fn() } },
      ],
    });
    fixture = TestBed.createComponent(SheetHost);
    modalService = TestBed.inject(ModalService);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('feuille', () => {
    it('should_close_the_sheet_when_back_is_pressed_while_it_is_open', async () => {
      modalService.openModal('repay', debt);
      render();

      await goBack();

      expect(modalService.isClosing()).toBe(true);
    });

    it('should_not_close_the_sheet_when_back_is_not_pressed', async () => {
      modalService.openModal('repay', debt);
      render();

      await settleHistory();

      expect(modalService.isClosing()).toBe(false);
      expect(modalService.modalOpen()).toBe(true);
    });

    it('should_remove_the_history_entry_when_the_sheet_is_closed_by_the_cancel_button', async () => {
      modalService.openModal('repay', debt);
      render();
      const goSpy = vi.spyOn(history, 'go');

      modalService.closeModal();
      render();
      await wait(CLOSE_ANIMATION_MS);

      expect(goSpy).toHaveBeenCalledWith(-1);
    });

    it('should_not_close_anything_when_back_is_pressed_after_the_sheet_was_closed_by_the_cancel_button', async () => {
      modalService.openModal('repay', debt);
      render();
      modalService.closeModal();
      render();
      await wait(CLOSE_ANIMATION_MS);
      const closeSpy = vi.spyOn(modalService, 'closeModal');

      await goBack();

      expect(closeSpy).not.toHaveBeenCalled();
    });

    it('should_close_the_sheet_when_the_escape_key_is_pressed_then_remove_its_entry', async () => {
      modalService.openModal('repay', debt);
      render();
      const goSpy = vi.spyOn(history, 'go');

      const overlay: HTMLElement = fixture.nativeElement.querySelector('.modal-overlay');
      overlay.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
      render();
      await settleHistory();

      expect(modalService.isClosing()).toBe(true);
      expect(goSpy).toHaveBeenCalledWith(-1);
    });
  });

  describe('section depliee', () => {
    const expandAccountSection = (): void => {
      repay().toggleSection('account');
      render();
    };

    it('should_collapse_the_section_and_keep_the_sheet_open_when_back_is_pressed', async () => {
      modalService.openModal('repay', debt);
      render();
      expandAccountSection();

      await goBack();

      expect(repay().expandedSection()).toBeNull();
      expect(modalService.isClosing()).toBe(false);
      expect(modalService.modalOpen()).toBe(true);
    });

    it('should_keep_the_typed_amount_when_the_section_is_collapsed_by_back', async () => {
      modalService.openModal('repay', debt);
      render();
      repay().form.patchValue({ amount: '123' });
      expandAccountSection();

      await goBack();

      expect(repay().form.getRawValue().amount).toBe('123');
    });

    it('should_close_the_sheet_when_back_is_pressed_a_second_time', async () => {
      modalService.openModal('repay', debt);
      render();
      expandAccountSection();

      await goBack();
      render();
      await goBack();

      expect(modalService.isClosing()).toBe(true);
    });

    it('should_remove_both_entries_when_the_sheet_closes_with_a_section_expanded', async () => {
      modalService.openModal('repay', debt);
      render();
      expandAccountSection();
      const goSpy = vi.spyOn(history, 'go');

      modalService.closeModal();
      render();
      await wait(CLOSE_ANIMATION_MS);
      render();
      await settleHistory();

      const traversed = goSpy.mock.calls.reduce((sum, [delta]) => sum + (delta ?? 0), 0);
      expect(traversed).toBe(-2);
    });
  });

  describe('surface ouverte par-dessus une autre', () => {
    it('should_close_only_the_picker_when_back_is_pressed_over_an_expanded_section', async () => {
      modalService.openModal('repay', debt);
      render();
      repay().toggleSection('account');
      render();
      picker().open();
      render();

      await goBack();

      expect(picker().isOpen()).toBe(false);
      expect(repay().expandedSection()).toBe('account');
      expect(modalService.isClosing()).toBe(false);
    });

    it('should_collapse_the_section_when_back_is_pressed_after_the_picker_closed', async () => {
      modalService.openModal('repay', debt);
      render();
      repay().toggleSection('account');
      render();
      picker().open();
      render();

      await goBack();
      render();
      await goBack();

      expect(repay().expandedSection()).toBeNull();
      expect(modalService.isClosing()).toBe(false);
    });

    it('should_cancel_the_confirmation_and_keep_the_sheet_open_when_back_is_pressed_over_it', async () => {
      modalService.openModal('repay', debt);
      render();
      const answer = TestBed.inject(ConfirmService).confirm({ title: 'Titre', message: 'Message' });
      render();

      await goBack();

      expect(await answer).toBe(false);
      expect(modalService.isClosing()).toBe(false);
      expect(modalService.modalOpen()).toBe(true);
    });

    it('should_close_the_sheet_when_back_is_pressed_after_the_confirmation_was_dismissed', async () => {
      modalService.openModal('repay', debt);
      render();
      const confirmService = TestBed.inject(ConfirmService);
      const answer = confirmService.confirm({ title: 'Titre', message: 'Message' });
      render();
      await goBack();
      await answer;
      render();

      await goBack();

      expect(modalService.isClosing()).toBe(true);
    });

    it('should_resolve_the_confirmation_true_without_back_navigation_when_confirmed_by_button', async () => {
      modalService.openModal('repay', debt);
      render();
      const answer = TestBed.inject(ConfirmService).confirm({ title: 'Titre', message: 'Message' });
      render();
      const goSpy = vi.spyOn(history, 'go');

      const confirmButton: HTMLButtonElement =
        fixture.nativeElement.querySelector('.confirm-btn--confirm');
      confirmButton.click();
      render();
      await settleHistory();

      expect(await answer).toBe(true);
      expect(goSpy).toHaveBeenCalledWith(-1);
      expect(modalService.modalOpen()).toBe(true);
    });
  });

  describe('navigation de route', () => {
    it('should_never_traverse_the_history_when_the_shell_resets_the_modal_after_a_navigation', async () => {
      modalService.openModal('repay', debt);
      render();
      // Le routeur a pousse sa propre entree : le shell ferme alors la feuille par `resetModal`.
      history.pushState({ navigationId: 2 }, '', '/dashboard');
      const goSpy = vi.spyOn(history, 'go');

      modalService.resetModal();
      render();
      await settleHistory();

      expect(goSpy).not.toHaveBeenCalled();
      expect(location.pathname).toBe('/dashboard');
    });
  });
});

@Component({
  selector: 'app-route-stub',
  standalone: true,
  template: '',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class RouteStub {}

describe('Retour arriere et routeur Angular (KKS-447)', () => {
  let router: Router;
  let layers: HistoryLayerService;
  let navigationEnds: string[];

  beforeEach(async () => {
    resetHistory();
    TestBed.configureTestingModule({
      providers: [
        { provide: APP_BASE_HREF, useValue: '/' },
        // TestBed remplace `PlatformLocation` par un mock : le vrai historique de jsdom est requis ici.
        { provide: PlatformLocation, useClass: BrowserPlatformLocation },
        provideRouter([
          { path: '', component: RouteStub },
          { path: 'a', component: RouteStub },
          { path: 'b', component: RouteStub },
        ]),
      ],
    });
    router = TestBed.inject(Router);
    layers = TestBed.inject(HistoryLayerService);
    navigationEnds = [];
    router.events.subscribe((event) => {
      if (event instanceof NavigationEnd) navigationEnds.push(event.urlAfterRedirects);
    });
    router.initialNavigation();
    await router.navigateByUrl('/a');
    navigationEnds.length = 0;
  });

  it('should_keep_the_url_and_emit_no_navigation_end_when_back_closes_a_layer', async () => {
    const onBack = vi.fn();
    layers.push(onBack);
    expect(location.pathname).toBe('/a');

    await goBack();

    expect(onBack).toHaveBeenCalledTimes(1);
    expect(location.pathname).toBe('/a');
    expect(navigationEnds).toEqual([]);
    expect(router.url).toBe('/a');
  });

  it('should_emit_no_navigation_end_when_a_layer_is_released_by_the_surface', async () => {
    const handle = layers.push(vi.fn());

    layers.release(handle);
    await settleHistory();

    expect(navigationEnds).toEqual([]);
    expect(location.pathname).toBe('/a');
  });

  it('should_navigate_normally_and_stamp_the_router_state_when_a_layer_was_closed_by_back', async () => {
    layers.push(vi.fn());
    await goBack();

    await router.navigateByUrl('/b');

    expect(location.pathname).toBe('/b');
    expect(navigationEnds).toEqual(['/b']);
    expect(history.state).toEqual(expect.objectContaining({ navigationId: expect.any(Number) }));
  });

  it('should_navigate_normally_when_a_layer_was_released_by_the_surface', async () => {
    const handle = layers.push(vi.fn());
    layers.release(handle);
    await settleHistory();

    await router.navigateByUrl('/b');

    expect(location.pathname).toBe('/b');
    expect(history.state).toEqual(expect.objectContaining({ navigationId: expect.any(Number) }));
  });

  it('should_complete_the_navigation_when_a_layer_is_released_at_the_same_time_it_starts', async () => {
    const handle = layers.push(vi.fn());

    const navigation = router.navigateByUrl('/b');
    layers.release(handle);
    await navigation;
    await settleHistory();

    expect(location.pathname).toBe('/b');
    expect(router.url).toBe('/b');
    expect(navigationEnds).toEqual(['/b']);
  });

  it('should_complete_the_navigation_when_a_layer_is_released_just_after_it_ended', async () => {
    const handle = layers.push(vi.fn());

    await router.navigateByUrl('/b');
    layers.release(handle);
    await settleHistory();

    expect(location.pathname).toBe('/b');
    expect(router.url).toBe('/b');
    expect(navigationEnds).toEqual(['/b']);
  });

  it('should_return_to_the_previous_page_when_back_is_pressed_after_an_abandoned_layer', async () => {
    const handle = layers.push(vi.fn());
    await router.navigateByUrl('/b');
    layers.release(handle);
    await settleHistory();
    navigationEnds.length = 0;

    await goBack();
    await settleHistory();

    // Residu documente : l'entree abandonnee reste sous la page, un second retour serait « a vide ».
    expect(location.pathname).toBe('/a');
    expect(router.url).toBe('/a');
  });
});
