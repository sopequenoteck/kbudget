import { Injectable, isDevMode } from '@angular/core';

/**
 * Lightweight dev-only logger.
 * All output is silenced in production builds (guarded by `isDevMode()`).
 * Mirrors SLF4J levels: debug, info, warn, error.
 */
@Injectable({ providedIn: 'root' })
export class DevLogger {
  private readonly enabled = isDevMode();

  debug(message: string, ...data: unknown[]): void {
    // eslint-disable-next-line no-console
    if (this.enabled) console.debug(`[DEBUG] ${message}`, ...data);
  }

  info(message: string, ...data: unknown[]): void {
    // eslint-disable-next-line no-console
    if (this.enabled) console.info(`[INFO] ${message}`, ...data);
  }

  warn(message: string, ...data: unknown[]): void {
    // eslint-disable-next-line no-console
    if (this.enabled) console.warn(`[WARN] ${message}`, ...data);
  }

  error(message: string, ...data: unknown[]): void {
    if (this.enabled) console.error(`[ERROR] ${message}`, ...data);
  }
}
