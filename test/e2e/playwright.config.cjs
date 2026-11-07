const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: '.',
  workers: 1,
  forbidOnly: !!process.env.CI,
  globalTimeout: 120_000,
  use: {
    ...devices['iPhone 13'],
    browserName: 'chromium',
    defaultBrowserType: 'chromium',
    baseURL: process.env.E2E_BASE_URL,
    launchOptions: { executablePath: process.env.E2E_CHROMIUM },
    trace: 'retain-on-failure',
  },
});
