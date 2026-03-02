import { ChangeDetectionStrategy, Component, inject, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { HealthService, type HealthCheckResult } from '../../../../core/services/health';

@Component({
  selector: 'app-data-settings',
  imports: [RouterLink],
  templateUrl: './data-settings.html',
  styleUrl: './data-settings.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DataSettings implements OnInit {
  private readonly healthService = inject(HealthService);

  readonly serverInfo = this.healthService.getServerInfo();
  readonly healthResult = signal<HealthCheckResult>({
    status: 'checking',
    responseTimeMs: null,
    error: null,
    checkedAt: null,
  });

  readonly isTestRunning = signal(false);
  readonly confirmReload = signal(false);

  ngOnInit(): void {
    this.runHealthCheck();
  }

  testConnection(): void {
    if (this.isTestRunning()) return;
    this.runHealthCheck();
  }

  reloadData(): void {
    this.confirmReload.set(true);
  }

  confirmReloadData(): void {
    this.confirmReload.set(false);
    window.location.reload();
  }

  cancelReload(): void {
    this.confirmReload.set(false);
  }

  formatTime(date: Date | null): string {
    if (!date) return '';
    return date.toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
  }

  private runHealthCheck(): void {
    this.isTestRunning.set(true);
    this.healthResult.set({
      status: 'checking',
      responseTimeMs: null,
      error: null,
      checkedAt: null,
    });

    this.healthService.checkHealth().subscribe((result) => {
      this.healthResult.set(result);
      this.isTestRunning.set(false);
    });
  }
}
