// Ecrans cles dans les deux themes, compares pixel a pixel a baseline/.
// Donnees : seed.sql (base de dev du 25 octobre 2026), horloge figee au meme jour.
import { expect, test, type Page } from '@playwright/test';

const NOW = new Date('2026-10-25T11:00:00Z'); // midi a Paris, jour du dump
const THEMES = ['dark', 'light'] as const;

async function login(page: Page): Promise<void> {
  await page.goto('/auth');
  await page.waitForLoadState('networkidle');
  await page.fill('input[type=email]', 'dev@local.test');
  await page.fill('input[type=password]', 'dev123');
  await page.keyboard.press('Enter');
  await page.waitForURL(/\/dashboard/);
}

async function open(page: Page, path: string): Promise<void> {
  await page.goto(path);
  await page.waitForLoadState('networkidle');
}

for (const theme of THEMES) {
  test.describe(`theme ${theme}`, () => {
    test.beforeEach(async ({ page }) => {
      await page.addInitScript((t) => localStorage.setItem('budget_theme', t), theme);
      // Le theme s'applique au demarrage et declenche des transitions : meme a 0 ms, une transition
      // encore active a la capture change l'anticrenelage des coins (1 niveau de gris, rendu instable).
      // animations: 'disabled' ne l'empeche pas ; seul transition: none rend la capture stable.
      await page.addInitScript(() =>
        document.addEventListener('DOMContentLoaded', () => {
          const style = document.createElement('style');
          style.textContent = '*, *::before, *::after { transition: none !important; }';
          document.head.appendChild(style);
        }),
      );
      await page.clock.setFixedTime(NOW);
    });

    test('connexion', async ({ page }) => {
      await open(page, '/auth');
      await expect(page).toHaveScreenshot(`${theme}-connexion.png`);
    });

    test('ecrans connectes', async ({ page }) => {
      await login(page);

      await open(page, '/dashboard');
      await expect(page).toHaveScreenshot(`${theme}-dashboard.png`, { fullPage: true });

      await open(page, '/transactions');
      await expect(page).toHaveScreenshot(`${theme}-transactions.png`, { fullPage: true });

      await page.locator('.list-row').first().click();
      await expect(page.locator('.bsheet')).toBeVisible();
      await expect(page).toHaveScreenshot(`${theme}-bottom-sheet.png`);

      // Ouvre la confirmation de suppression sans la valider : la base n'est pas modifiee.
      await page.locator('.bsheet__action-pill--danger').click();
      await expect(page.getByRole('alertdialog')).toBeVisible();
      await expect(page).toHaveScreenshot(`${theme}-confirm.png`);

      await open(page, '/settings');
      await expect(page).toHaveScreenshot(`${theme}-reglages.png`, { fullPage: true });
    });
  });
}
