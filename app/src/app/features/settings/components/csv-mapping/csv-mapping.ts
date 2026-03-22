import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { FormsModule } from '@angular/forms';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorUploadSimple,
  phosphorArrowCounterClockwise,
  phosphorWarningCircle,
} from '@ng-icons/phosphor-icons/regular';

import { ImportService } from '../../../../core/services/import';
import { CsvPreview, CsvMapping as CsvMappingModel } from '../../../../core/models/import.model';

@Component({
  selector: 'app-csv-mapping',
  imports: [RouterLink, NgIcon, FormsModule],
  providers: [
    provideIcons({
      phosphorUploadSimple,
      phosphorArrowCounterClockwise,
      phosphorWarningCircle,
    }),
  ],
  templateUrl: './csv-mapping.html',
  styleUrl: './csv-mapping.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CsvMapping {
  private readonly importService = inject(ImportService);
  private readonly router = inject(Router);

  // File & account (passed via router state)
  protected file: File | null = null;
  readonly accountId = signal<string>('');
  readonly fileName = signal<string>('');

  // Preview state
  readonly preview = signal<CsvPreview | null>(null);
  readonly previewLoading = signal(false);
  readonly previewError = signal<string | null>(null);

  // Mapping config
  readonly separator = signal(';');
  readonly encoding = signal('UTF-8');
  readonly skipHeaderLines = signal(0);
  readonly dateFormat = signal('dd/MM/yyyy');
  readonly decimalSeparator = signal(',');
  readonly amountMode = signal<'single' | 'split'>('single');

  // Column selection
  readonly dateColumn = signal('');
  readonly amountColumn = signal('');
  readonly debitColumn = signal('');
  readonly creditColumn = signal('');
  readonly labelColumn = signal('');

  // Profile saving
  readonly saveAsProfile = signal(false);
  readonly profileName = signal('');

  // Submit state
  readonly importing = signal(false);
  readonly importError = signal<string | null>(null);

  readonly headers = computed(() => this.preview()?.headers ?? []);

  readonly DATE_FORMATS = ['dd/MM/yyyy', 'yyyy-MM-dd', 'MM/dd/yyyy', 'dd-MM-yyyy', 'MM/yyyy'];
  readonly ENCODINGS = ['UTF-8', 'ISO-8859-1', 'windows-1252'];
  readonly SEPARATORS = [
    { label: 'Point-virgule (;)', value: ';' },
    { label: 'Virgule (,)', value: ',' },
    { label: 'Tabulation (\\t)', value: '\t' },
    { label: 'Pipe (|)', value: '|' },
  ];

  constructor() {
    const nav = this.router.getCurrentNavigation();
    const state = nav?.extras?.state as
      | { file?: File; accountId?: string }
      | undefined;

    if (state?.file && state?.accountId) {
      this.file = state.file;
      this.accountId.set(state.accountId);
      this.fileName.set(state.file.name);
      this.loadPreview();
    }
  }

  async loadPreview(): Promise<void> {
    if (!this.file) return;

    this.previewLoading.set(true);
    this.previewError.set(null);

    try {
      const result = await firstValueFrom(
        this.importService.preview(
          this.file,
          this.separator(),
          this.encoding(),
          this.skipHeaderLines(),
        ),
      );
      this.preview.set(result);

      // Auto-set detected values
      if (result.detectedSeparator) {
        this.separator.set(result.detectedSeparator);
      }
      if (result.detectedEncoding) {
        this.encoding.set(result.detectedEncoding);
      }
      if (result.detectedSkipHeaderLines > 0) {
        this.skipHeaderLines.set(result.detectedSkipHeaderLines);
      }

      // Auto-select first matching columns by common names
      this.autoSelectColumns(result.headers);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to preview CSV', err);
      }
      this.previewError.set('Impossible de prévisualiser le fichier. Vérifiez les paramètres.');
    } finally {
      this.previewLoading.set(false);
    }
  }

  private autoSelectColumns(headers: string[]): void {
    const normalize = (s: string) => s.toLowerCase().replace(/[^a-z0-9]/g, '');
    const find = (...terms: string[]) =>
      headers.find((h) => terms.some((t) => normalize(h).includes(t))) ?? '';

    if (!this.dateColumn()) this.dateColumn.set(find('date'));
    if (!this.labelColumn()) this.labelColumn.set(find('libelle', 'label', 'detail', 'description'));
    if (!this.amountColumn()) this.amountColumn.set(find('montant', 'amount', 'valeur'));
    if (!this.debitColumn()) this.debitColumn.set(find('debit', 'debiteur'));
    if (!this.creditColumn()) this.creditColumn.set(find('credit', 'crediteur'));
  }

  onSeparatorChange(): void {
    this.loadPreview();
  }

  onEncodingChange(): void {
    this.loadPreview();
  }

  onSkipHeaderLinesChange(): void {
    this.loadPreview();
  }

  isValid(): boolean {
    if (!this.dateColumn() || !this.labelColumn()) return false;
    if (this.amountMode() === 'single' && !this.amountColumn()) return false;
    if (this.amountMode() === 'split' && (!this.debitColumn() || !this.creditColumn())) return false;
    if (this.saveAsProfile() && !this.profileName().trim()) return false;
    return true;
  }

  async import(): Promise<void> {
    if (!this.file || !this.isValid()) return;

    this.importing.set(true);
    this.importError.set(null);

    const mapping: CsvMappingModel = {
      separator: this.separator(),
      dateFormat: this.dateFormat(),
      dateColumn: this.dateColumn(),
      amountColumn: this.amountMode() === 'single' ? this.amountColumn() : null,
      debitColumn: this.amountMode() === 'split' ? this.debitColumn() : null,
      creditColumn: this.amountMode() === 'split' ? this.creditColumn() : null,
      labelColumn: this.labelColumn(),
      encoding: this.encoding(),
      decimalSeparator: this.decimalSeparator(),
      skipHeaderLines: this.skipHeaderLines(),
      saveAsProfile: this.saveAsProfile(),
      profileName: this.saveAsProfile() ? this.profileName().trim() : null,
    };

    try {
      const draft = await firstValueFrom(
        this.importService.uploadWithMapping(this.file, this.accountId(), mapping),
      );
      this.router.navigate(['/settings/import/review', draft.id]);
    } catch (err: unknown) {
      if (isDevMode()) {
        console.error('Failed to import with mapping', err);
      }
      const httpErr = err as { error?: { message?: string } };
      this.importError.set(
        httpErr?.error?.message ?? "Erreur lors de l'import. Vérifiez le mapping et réessayez.",
      );
      this.importing.set(false);
    }
  }
}
