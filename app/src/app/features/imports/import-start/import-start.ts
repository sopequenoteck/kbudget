import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import {
  phosphorArrowLeft,
  phosphorCheck,
  phosphorCheckCircle,
  phosphorUploadSimple,
  phosphorWarningCircle,
} from '@ng-icons/phosphor-icons/regular';

import { AccountService } from '../../../core/services/account';
import { ApiErrorService } from '../../../core/services/api-error';
import { DevLogger } from '../../../core/services/dev-logger';
import { ImportService } from '../../../core/services/import';
import { Account } from '../../../core/models/account.model';
import { ImportDetection } from '../../../core/models/import.model';

/** Brouillon deja ouvert pour le compte choisi (HTTP 409) : `draftId` vaut `null` si introuvable. */
interface DraftConflict {
  draftId: string | null;
}

/**
 * Depart d'un import (KKS-386) : choix du fichier, reconnaissance de son
 * format, choix **explicite** du compte, puis envoi. Le compte n'est
 * preselectionne que si l'API en reconnait un (`suggestedAccountId`) ou si
 * l'URL en porte un (`?accountId=`) : jamais le compte par defaut, un reimport
 * partait sinon silencieusement sur le mauvais compte.
 */
@Component({
  selector: 'app-import-start',
  standalone: true,
  imports: [NgIcon, RouterLink, TranslocoPipe],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorCheck,
      phosphorCheckCircle,
      phosphorUploadSimple,
      phosphorWarningCircle,
    }),
  ],
  templateUrl: './import-start.html',
  styleUrl: './import-start.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ImportStart {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly accountService = inject(AccountService);
  private readonly importService = inject(ImportService);
  private readonly apiError = inject(ApiErrorService);
  private readonly logger = inject(DevLogger);
  private readonly transloco = inject(TranslocoService);

  readonly accounts = signal<Account[]>([]);
  readonly accountsLoading = signal(true);
  readonly file = signal<File | null>(null);
  readonly detecting = signal(false);
  readonly detection = signal<ImportDetection | null>(null);
  readonly accountId = signal<string | null>(null);
  readonly uploading = signal(false);
  /** Message d'erreur resolu au moment de l'evenement qui l'a provoque. */
  readonly error = signal<string | null>(null);
  readonly conflict = signal<DraftConflict | null>(null);

  readonly recognized = computed(() => this.detection()?.recognized === true);
  readonly showAccounts = computed(() => this.detection() !== null);
  readonly canSubmit = computed(
    () => this.file() !== null && this.accountId() !== null && !this.uploading(),
  );

  private readonly accountsLoaded: Promise<void>;

  constructor() {
    this.accountsLoaded = this.loadAccounts();
  }

  private async loadAccounts(): Promise<void> {
    try {
      this.accounts.set(await firstValueFrom(this.accountService.getAll(false)));
    } catch (err) {
      this.logger.error('Failed to load accounts', err);
      this.error.set(this.transloco.translate('imports.feedback.accountsLoadError'));
    } finally {
      this.accountsLoading.set(false);
    }
  }

  goBack(): void {
    this.router.navigate(['/transactions']);
  }

  async onFileSelected(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!file) return;

    this.detection.set(null);
    this.accountId.set(null);
    this.error.set(null);
    this.conflict.set(null);
    this.file.set(file);
    this.detecting.set(true);

    try {
      const detection = await firstValueFrom(this.importService.detect(file));
      await this.accountsLoaded;
      this.accountId.set(this.initialAccountId(detection));
      this.detection.set(detection);
    } catch (err) {
      this.logger.error('Failed to detect the import profile', err);
      this.file.set(null);
      this.error.set(
        this.apiError.label(err, this.transloco.translate('imports.feedback.detectError')),
      );
    } finally {
      this.detecting.set(false);
    }
  }

  /** Compte reconnu par l'API, sinon celui de l'URL, sinon aucun : le choix reste explicite. */
  private initialAccountId(detection: ImportDetection): string | null {
    const known = (id: string | null | undefined): string | null =>
      id && this.accounts().some((a) => a.id === id) ? id : null;
    return (
      known(detection.suggestedAccountId) ??
      known(this.route.snapshot.queryParamMap.get('accountId'))
    );
  }

  selectAccount(accountId: string): void {
    this.accountId.set(accountId);
    this.conflict.set(null);
    this.error.set(null);
  }

  async analyse(): Promise<void> {
    const file = this.file();
    const accountId = this.accountId();
    if (!file || !accountId || this.uploading()) return;

    this.uploading.set(true);
    this.error.set(null);
    this.conflict.set(null);

    try {
      const draft = await firstValueFrom(this.importService.upload(file, accountId));
      await this.router.navigate(['/transactions/import/review', draft.id]);
    } catch (err: unknown) {
      this.logger.error('Failed to upload the statement', err);
      const status = (err as { status?: number })?.status;
      if (status === 409) {
        await this.showConflict(accountId);
      } else if (status === 422) {
        this.openMapping();
        return;
      } else {
        this.error.set(
          this.apiError.label(err, this.transloco.translate('imports.feedback.uploadError')),
        );
      }
      this.uploading.set(false);
    }
  }

  /** Passe au mappage manuel des colonnes, avec le fichier et le compte choisis. */
  openMapping(): void {
    const file = this.file();
    const accountId = this.accountId();
    if (!file || !accountId) return;
    this.router.navigate(['/settings/import/mapping'], { state: { file, accountId } });
  }

  /** Le 409 ne dit pas quel brouillon : on le retrouve dans la liste des brouillons en cours. */
  private async showConflict(accountId: string): Promise<void> {
    let draftId: string | null = null;
    try {
      const drafts = await firstValueFrom(this.importService.listDrafts());
      draftId = drafts.find((d) => d.accountId === accountId)?.id ?? null;
    } catch (err) {
      this.logger.error('Failed to look up the draft in progress', err);
    }
    this.conflict.set({ draftId });
  }
}
