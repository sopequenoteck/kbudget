// Captures de reference des ecrans cles (KKS-587). Mode d'emploi : README.md du dossier.
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: '.',
  snapshotPathTemplate: '{testDir}/baseline/{arg}{ext}',
  fullyParallel: false,
  workers: 1,
  reporter: 'list',
  expect: {
    // Diff nul exige : un seul pixel different, d'aussi peu que ce soit, fait echouer la capture.
    // threshold vaut 0.2 par defaut : #737373 et #8a8a8a passeraient pour identiques.
    toHaveScreenshot: { maxDiffPixels: 0, threshold: 0, animations: 'disabled' },
  },
  use: {
    baseURL: process.env['KB_BASE_URL'] ?? 'http://localhost:4200',
    browserName: 'chromium',
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 1,
    locale: 'fr-FR',
    timezoneId: 'Europe/Paris',
  },
});
