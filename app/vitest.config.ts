/// <reference types="vitest" />
import { defineConfig } from 'vitest/config';
import angular from '@analogjs/vite-plugin-angular';

// Fuseau par defaut de la suite, surchargeable par la variable d'environnement
// (ex: `TZ=Europe/Paris npx vitest run`) : les dates seules (LocalDate) lues
// via `new Date` reculent d'un jour dans un fuseau en retard sur UTC, un bug
// invisible sous UTC, le fuseau natif des runners CI.
process.env.TZ ??= 'America/Los_Angeles';

export default defineConfig({
  plugins: [angular()],
  test: {
    globals: true,
    environment: 'jsdom',
    include: ['src/**/*.spec.ts'],
    setupFiles: ['./src/test-setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
      reportsDirectory: './coverage',
      include: ['src/**/*.ts'],
      exclude: [
        '**/*.spec.ts',
        'src/test-setup.ts',
        'src/main.ts',
        'src/**/*.config.ts',
        'src/environments/**',
      ],
    },
  },
});
