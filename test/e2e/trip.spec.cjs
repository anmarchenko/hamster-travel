const { readFile } = require('node:fs/promises');
const { join } = require('node:path');
const { expect, test } = require('@playwright/test');

const connected = '[data-phx-main].phx-connected';

test.beforeEach(async ({ page }) => {
  await page.goto('/users/log_in');
  const csrf = await page.locator('#login-form input[name="_csrf_token"]').getAttribute('value');
  const login = await page.request.post('/users/log_in', {
    form: {
      _csrf_token: csrf,
      'user[email]': process.env.E2E_EMAIL,
      'user[password]': process.env.E2E_PASSWORD,
    },
    maxRedirects: 0,
  });

  expect(login.status()).toBe(302);
  expect(login.headers().location).not.toBe('/users/log_in');
});

test('validates and displays mobile trip cover uploads', async ({ page }) => {
  await page.goto(`/trips/${process.env.E2E_COVER_TRIP}`);
  await expect(page.locator(connected)).toBeAttached();

  const form = page.locator('#cover-upload-form');
  const input = form.locator('input[type="file"]');
  const alert = form.getByRole('alert');
  const cover = page.locator('img[data-cover-image]');

  await input.setInputFiles({
    name: 'too-large.jpg',
    mimeType: 'image/jpeg',
    buffer: Buffer.alloc(25_000_001),
  });
  await expect(alert).toHaveText('File is too large. Maximum size is 25 MB.');

  await input.setInputFiles({
    name: 'unsupported.gif',
    mimeType: 'image/gif',
    buffer: Buffer.from('unsupported image'),
  });
  await expect(alert).toHaveText('Unsupported file type. Use JPG, PNG, WebP, HEIC, or HEIF.');

  const jpeg = await readFile(join(__dirname, 'fixtures', 'rotated.jpg'));
  await input.setInputFiles({
    name: 'large.jpg',
    mimeType: 'image/jpeg',
    // Repeated bytes exercise WebSocket compression as well as the raised file limit.
    buffer: Buffer.concat([jpeg, Buffer.alloc(8_500_000)]),
  });
  await expect(page.getByText('Cover updated.', { exact: true })).toBeVisible();
  await expect.poll(() => cover.evaluate(img => img.naturalHeight > img.naturalWidth)).toBe(true);
  const jpegUrl = await cover.getAttribute('src');

  await input.setInputFiles({
    name: 'corrupt.jpg',
    mimeType: 'image/jpeg',
    buffer: Buffer.from('invalid image data'),
  });
  await expect(alert).toHaveText('Upload failed. Please try again.');
  await expect(cover).toHaveAttribute('src', jpegUrl);

  await input.setInputFiles(join(__dirname, 'fixtures', 'phone.HEIC'));
  await expect(cover).not.toHaveAttribute('src', jpegUrl);
  await expect.poll(() => cover.evaluate(img => img.naturalWidth > img.naturalHeight)).toBe(true);
  await expect(page.getByText('Cover updated.', { exact: true })).toBeVisible();
});

test('locks trip editing offline and saves an edit after reconnecting', async ({ page, context }) => {
  await page.goto(`/trips/${process.env.E2E_OFFLINE_TRIP}`);
  await expect(page.locator(connected)).toBeAttached();

  const header = page.locator('#trip-offline-header');
  await context.setOffline(true);
  await expect(header).toHaveAttribute('inert', '');
  await context.setOffline(false);
  await expect(header).not.toHaveAttribute('inert', '');

  await header.locator('a[href*="/edit"]').click();
  const form = page.locator('#trip-form');
  const name = form.locator('input[name="trip[name]"]');
  await expect(name).toHaveValue('Offline E2E');
  await name.fill('Offline E2E updated');
  await form.getByRole('button', { name: 'Save', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'Offline E2E updated' })).toBeVisible();
});

test('recovers an unsaved day expense after the LiveView socket drops', async ({ page, context }) => {
  let liveSocket;
  await page.routeWebSocket(/\/live\/websocket(?:\?|$)/, route => {
    route.connectToServer();
    liveSocket = route;
  });

  await page.goto(`/trips/${process.env.E2E_RECOVERY_TRIP}?tab=budget`);
  await expect(page.locator(connected)).toBeAttached();
  const originalSocket = liveSocket;

  await page.locator('#day-expense-new-0 [phx-click="add_day_expense"]').click();
  const form = page.locator('#day-expense-new-0 form');
  const name = form.locator('input[name="day_expense[name]"]');
  const amount = form.locator('input[name="day_expense[expense][price][amount]"]');
  await name.fill('Airport bus');
  await amount.fill('12.50');
  await amount.press('Tab');

  await context.setOffline(true);
  await originalSocket.close({ code: 1001, reason: 'Test disconnect' });
  await expect(page.locator(connected)).toHaveCount(0);

  await context.setOffline(false);
  await expect(page.locator(connected)).toBeAttached();
  expect(liveSocket).not.toBe(originalSocket);
  await expect(name).toHaveValue('Airport bus');
  await expect(amount).toHaveValue('12.50');

  await form.getByRole('button', { name: 'Save', exact: true }).click();
  await expect(form).toHaveCount(0);
  await expect(page.locator('[data-day-expense-id]').getByText('Airport bus', { exact: true })).toBeVisible();
});

test('downloads a real trip PDF from LiveView', async ({ page }) => {
  await page.goto(`/trips/${process.env.E2E_PDF_TRIP}`);
  await expect(page.locator(connected)).toBeAttached();

  const downloadEvent = page.waitForEvent('download');
  await page.locator('button[phx-click="export_pdf"]').click();
  const download = await downloadEvent;

  expect(download.suggestedFilename()).toMatch(/^pdf-e2e-plan-\d{8}-\d{6}\.pdf$/);
  const pdf = await readFile(await download.path());
  expect(pdf.subarray(0, 5).toString()).toBe('%PDF-');
  expect(pdf.subarray(-12).toString()).toMatch(/%%EOF\s*$/);
});
