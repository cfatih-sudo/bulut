import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './tests',
  timeout: 45000,
  expect: { timeout: 10000 },
  fullyParallel: false,
  retries: 0,
  reporter: [['list'], ['html', { outputFolder: 'artifacts/html-report', open: 'never' }]],
  use: {
    baseURL: 'https://kdportal.com.tr',
    ignoreHTTPSErrors: true,           // origin serves a self-signed cert (FINDING #1)
    launchOptions: { executablePath: '/opt/pw-browsers/chromium' },
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    actionTimeout: 12000,
  },
});
