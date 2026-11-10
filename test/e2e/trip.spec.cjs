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
  await expect.poll(() => cover.evaluate(img => img.naturalHeight > img.naturalWidth)).toBe(true);
  const jpegUrl = await cover.getAttribute('src');

  await input.setInputFiles({
    name: 'corrupt.jpg',
    mimeType: 'image/jpeg',
    buffer: Buffer.from('invalid image data'),
  });
  await expect(alert).toHaveText('Upload failed. Please try again.');
  await expect(cover).toHaveAttribute('src', jpegUrl);

  const [fileChooser] = await Promise.all([page.waitForEvent('filechooser'), cover.tap()]);
  await fileChooser.setFiles(join(__dirname, 'fixtures', 'phone.HEIC'));
  await expect(cover).not.toHaveAttribute('src', jpegUrl);
  await expect.poll(() => cover.evaluate(img => img.naturalWidth > img.naturalHeight)).toBe(true);
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

test('reads loaded trip notes offline and picks up online edits on the next disconnect', async ({ page, context }) => {
  await page.goto(`/trips/${process.env.E2E_NOTES_TRIP}`);
  await expect(page.locator(connected)).toBeAttached();

  const notebook = page.locator('[data-offline-notebook]');
  const reader = notebook.locator('[data-offline-note-reader]');
  const notesTab = page.locator('#mobile-trip-tab-notes');
  const packing = notebook.getByRole('button', { name: /Packing/ });
  const food = notebook.getByRole('button', { name: /Food/ });

  await context.setOffline(true);
  await notesTab.click();
  await packing.click();
  await expect(reader.getByRole('heading', { name: 'Packing' })).toBeFocused();
  await expect(reader.locator('strong')).toHaveText('Bring tickets');
  await expect(page.getByRole('button', { name: 'Edit', exact: true })).toHaveCount(0);

  await reader.getByRole('button', { name: 'Back to notes' }).click();
  await expect(packing).toBeFocused();
  await food.click();
  await expect(reader.getByText('Visit the market')).toBeVisible();

  await context.setOffline(false);
  await expect(notebook).toBeHidden();
  await notesTab.click();
  await page.getByRole('link', { name: /Packing/ }).click();
  await expect(page).toHaveURL(/[?&]note=\d+/);
  const onlineReader = page.locator('[data-online-notebook]');
  await onlineReader.getByRole('button', { name: 'Edit', exact: true }).click();
  await onlineReader.getByLabel('Note title').fill('Updated packing');
  await onlineReader.getByRole('button', { name: 'Save', exact: true }).click();
  await expect(onlineReader.getByRole('heading', { name: 'Updated packing' })).toBeVisible();

  await context.setOffline(true);
  await expect(reader.getByRole('heading', { name: 'Updated packing' })).toBeVisible();
  await reader.getByRole('button', { name: 'Back to notes' }).click();
  await expect(food).toBeVisible();
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

test.describe('desktop expense sheet', () => {
  test.use({ viewport: { width: 1200, height: 800 }, isMobile: false, hasTouch: false });

  test('keeps category fields and actions in place when validation fails', async ({ page }) => {
    await page.goto(`/trips/${process.env.E2E_SHEET_TRIP}?tab=budget`);
    await page.getByRole('button', { name: 'Add category', exact: true }).click();

    const form = page.locator('form[id^="budget-category-form-"]');
    const name = form.locator('input[name="budget_category[name]"]');
    const amount = form.locator('input[id$="_amount"]');
    const save = form.getByRole('button', { name: 'Save', exact: true });
    const fieldPositions = () => form.evaluate(element => {
      const formTop = element.getBoundingClientRect().top;
      return Array.from(element.querySelectorAll('input:not([type="hidden"]), select, button'),
        control => control.getBoundingClientRect().top - formTop);
    });

    await name.fill('Souvenirs');
    const positions = await fieldPositions();
    expect(positions[0]).toBe(positions[1]);

    await save.click();
    await expect(form.getByText("can't be blank", { exact: true })).toBeVisible();
    expect(await fieldPositions()).toEqual(positions);

    await amount.fill('12');
    await name.fill('');
    await form.evaluate(element => {
      // Exercise the server-side name error without the browser's required-field prompt.
      element.noValidate = true;
      element.requestSubmit();
    });
    await expect(form.locator('.pc-form-field-error')).toHaveText("can't be blank");
    expect(await fieldPositions()).toEqual(positions);
  });

  test('edits cells, copies ranges, appends TSV, and preserves a draft on reconnect', async ({ page, context }) => {
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    let liveSocket;
    await page.routeWebSocket(/\/live\/websocket(?:\?|$)/, route => {
      route.connectToServer();
      liveSocket = route;
    });
    await page.goto(`/trips/${process.env.E2E_SHEET_TRIP}?tab=budget`);
    const food = page.getByRole('grid', { name: 'Actual expenses for Food' });
    const other = page.getByRole('grid', { name: 'Actual expenses for Other' });
    const foodToggle = page.locator('summary[aria-label="Actual expenses for Food"]');
    const otherAdd = other.getByRole('gridcell', { name: 'A1 Add expense' });
    const cell = index => food.locator(`[data-index="${index}"]`);
    const editor = food.getByRole('textbox');
    const status = food.locator('..').locator('[data-sheet-status]');

    await expect(food).toBeHidden();
    await expect(other).toBeHidden();
    await foodToggle.press('Enter');
    await expect(food.getByRole('columnheader', { name: 'D' })).toBeVisible();
    await expect(other).toBeHidden();
    await foodToggle.click();
    await expect(food).toBeHidden();
    await foodToggle.click();
    await page.locator('summary[aria-label="Actual expenses for Other"]').click();
    await expect(otherAdd).toBeVisible();
    await expect(cell(0)).toHaveText('€7.00');

    await cell(0).press('F2');
    await expect(food.locator('..').getByRole('combobox', { name: 'Currency', exact: true })).toBeVisible();
    const desktopViewport = page.viewportSize();
    await page.setViewportSize({ width: 390, height: 400 });
    await food.locator('..').getByRole('button', { name: 'Currency EUR', exact: true }).click();
    const currencyPicker = page.getByRole('dialog', { name: 'Currency' });
    const currencySearch = currencyPicker.getByRole('searchbox');
    await expect(currencyPicker).toBeInViewport();
    await currencySearch.fill('usd');
    await currencySearch.press('Enter');
    await expect(currencyPicker).toBeHidden();
    await expect(editor).toHaveAccessibleName('Amount in USD');
    await expect(editor).toHaveValue('7');

    await editor.fill('7.70');
    await food.locator('..').getByRole('button', { name: 'Currency USD', exact: true }).click();
    await currencySearch.fill('eur');
    await currencySearch.press('Escape');
    await expect(currencyPicker).toBeHidden();
    await expect(editor).toHaveAccessibleName('Amount in USD');
    await expect(editor).toHaveValue('7.70');
    await editor.press('Escape');
    await page.setViewportSize(desktopViewport);
    await expect(food.getByRole('columnheader', { name: 'D' })).toBeVisible();

    await cell(0).press('Alt+ArrowDown');
    await expect(currencyPicker).toBeHidden();
    await expect(cell(0)).toHaveText('€7.00');
    await expect(editor).toHaveCount(0);

    await cell(0).click();
    await page.keyboard.press('Shift+ArrowRight');
    await expect(cell(1)).toHaveAttribute('aria-selected', 'true');
    await page.keyboard.press('Control+c');
    expect(await page.evaluate(() => navigator.clipboard.readText())).toMatch(/^7(?:\.0+)?\t11(?:\.0+)?$/);

    await cell(0).press('Enter');
    await expect(editor).toBeFocused();
    await expect(editor).toHaveValue('7');
    await editor.press('Alt+ArrowDown');
    await expect(currencyPicker).toBeHidden();
    await expect(editor).toBeFocused();
    await editor.fill('8.50');
    await editor.press('Enter');
    await expect(cell(0)).toHaveText('€8.50');
    await expect(cell(4)).toBeFocused();

    await cell(0).press('F2');
    await editor.fill('9.50');
    await otherAdd.click();
    await expect(cell(0)).toHaveText('€9.50');
    await expect(otherAdd).toBeFocused();

    await cell(0).press('F2');
    await editor.fill('invalid');
    await otherAdd.click();
    await expect(status).toContainText('Enter a positive amount');
    await expect(editor).toHaveValue('invalid');
    await food.locator('..').getByRole('button', { name: 'Cancel', exact: true }).click();
    await expect(cell(0)).toHaveText('€9.50');

    await cell(2).dblclick();
    await expect(editor).toHaveAccessibleName('Amount in USD');
    await editor.fill('25');
    await editor.press('Escape');
    await expect(cell(2)).toHaveText('€20.00');

    async function paste(text) {
      await page.evaluate(value => navigator.clipboard.writeText(value), text);
      await page.keyboard.press('Control+v');
    }

    await cell(1).click();
    await paste('13\t14');
    await expect(status).toHaveText('C1 · Edit this amount in its original currency.');
    await expect(cell(1)).toHaveText('€11.00');

    await cell(0).click();
    await paste('10\t12');
    await expect(cell(0)).toHaveText('€10.00');
    await expect(cell(1)).toHaveText('€12.00');

    await cell(5).click();
    await paste('30\nnot a number');
    await expect(status).toContainText('Enter a positive amount');
    await expect(cell(5)).toHaveText('+');
    await paste('30\n31');
    await expect(cell(5)).toHaveText('€30.00');
    await expect(cell(6)).toHaveText('€31.00');
    await expect(cell(7)).toBeFocused();
    await page.keyboard.press('4');
    await editor.fill('40');
    await editor.press('Tab');
    await expect(cell(7)).toHaveText('€40.00');
    await expect(cell(8)).toBeFocused();
    await cell(7).press('F2');
    await editor.press('Tab');
    await expect(cell(8)).toBeFocused();

    await cell(1).press('F2');
    await editor.fill('32.75');
    const originalSocket = liveSocket;
    await context.setOffline(true);
    await originalSocket.close({ code: 1001, reason: 'Test disconnect' });
    await expect(page.locator('[data-sheet-grid][aria-label="Actual expenses for Food"]')).toHaveAttribute('aria-readonly', 'true');
    await expect(page.locator(connected)).toHaveCount(0);
    await foodToggle.click();
    await expect(foodToggle.locator('..')).not.toHaveAttribute('open', '');
    await foodToggle.click();
    await expect(foodToggle.locator('..')).toHaveAttribute('open', '');
    await context.setOffline(false);
    await expect(food).toHaveAttribute('aria-readonly', 'false');
    expect(liveSocket).not.toBe(originalSocket);
    await expect(editor).toHaveValue('32.75');
    await editor.press('Enter');
    await expect(cell(1)).toHaveText('€32.75');

    const secondPage = await context.newPage();
    await secondPage.goto(`/trips/${process.env.E2E_SHEET_TRIP}?tab=budget`);
    await secondPage.locator('summary[aria-label="Actual expenses for Food"]').click();
    const secondGrid = secondPage.getByRole('grid', { name: 'Actual expenses for Food' });
    await cell(1).press('F2');
    await editor.fill('35');
    await secondGrid.locator('[data-index="1"]').press('F2');
    await secondGrid.getByRole('textbox').fill('36');
    await secondGrid.getByRole('textbox').press('Enter');
    await expect(secondGrid.locator('[data-index="1"]')).toHaveText('€36.00');
    await expect(editor).toHaveValue('35');
    await editor.press('Enter');
    await expect(status).toContainText('This expense changed to €36.00');
    await expect(editor).toHaveValue('35');
    await editor.press('Escape');
    await expect(cell(1)).toHaveText('€36.00');
    await food.locator('..').getByRole('button', { name: 'Edit', exact: true }).click();
    await expect(editor).toBeFocused();
    await expect(editor).toHaveValue('36');
    await editor.fill('');
    await editor.press('Enter');
    await expect(cell(1)).toHaveText('€20.00');

    await cell(1).press('F2');
    await editor.fill('0,00');
    await editor.press('Enter');
    await expect(cell(1)).toHaveText('€17.00');

    await cell(0).click();
    await page.keyboard.press('Shift+ArrowRight');
    await page.keyboard.press('Delete');
    await expect(cell(0)).toHaveText('€20.00');
    await expect(cell(4)).toHaveText('+');
  });
});

test('edits by touch with check and cancel icons next to the active row', async ({ page }) => {
  await page.goto(`/trips/${process.env.E2E_MOBILE_SHEET_TRIP}?tab=budget`);
  const grid = page.getByRole('grid', { name: 'Actual expenses for Food' });
  const add = grid.locator('[data-add]');
  const editor = grid.getByRole('textbox');
  const section = grid.locator('..');
  const save = section.getByRole('button', { name: 'Save', exact: true });
  const cancel = section.getByRole('button', { name: 'Cancel', exact: true });
  const actions = grid.locator('[data-sheet-editor-row]');
  const editedRow = grid.locator('[data-sheet-editor-row] + tr');

  await expect(grid).toBeHidden();
  await page.locator('summary[aria-label="Actual expenses for Food"]').tap();
  await expect(grid.getByRole('columnheader', { name: 'B' })).toBeVisible();
  await expect(grid.getByRole('columnheader', { name: 'C' })).toHaveCount(0);
  expect((await add.boundingBox()).height).toBeGreaterThanOrEqual(44);
  await expect(section.locator('[data-sheet-selection]')).toContainText('New expense in USD');
  await expect(actions).toHaveCount(0);
  await add.tap();
  await expect(editor).toBeFocused();
  await expect(editor).toHaveAttribute('inputmode', 'decimal');
  await expect(save).toBeInViewport();
  await expect(cancel).toBeInViewport();
  await expect(save.locator('.budget-sheet-edit-icon')).toBeVisible();
  await expect(cancel.locator('.budget-sheet-edit-icon')).toBeVisible();
  await expect(save.locator('.budget-sheet-edit-label')).toBeHidden();
  await expect(cancel.locator('.budget-sheet-edit-label')).toBeHidden();
  expect((await save.boundingBox()).width).toBeGreaterThanOrEqual(44);
  expect((await save.boundingBox()).height).toBeGreaterThanOrEqual(44);
  expect((await cancel.boundingBox()).width).toBeGreaterThanOrEqual(44);
  expect((await cancel.boundingBox()).height).toBeGreaterThanOrEqual(44);
  await expect(editedRow.getByRole('textbox')).toBeFocused();

  await editor.evaluate(input => {
    const clipboardData = new DataTransfer();
    clipboardData.setData('text/plain', '11\n22');
    input.dispatchEvent(new ClipboardEvent('paste', { bubbles: true, cancelable: true, clipboardData }));
  });
  const currencyPicker = section.getByRole('dialog', { name: 'Currency' });
  const pasteCurrency = section.getByRole('button', { name: 'Currency for pasted expenses EUR' });
  await pasteCurrency.tap();
  await expect(currencyPicker.getByRole('button', { name: 'EUR', exact: true })).toHaveAttribute('aria-current', 'true');
  await currencyPicker.getByRole('button', { name: 'USD', exact: true }).tap();
  await expect(section.getByRole('button', { name: 'Currency for pasted expenses USD' })).toBeVisible();
  await section.getByRole('button', { name: 'Add expenses', exact: true }).tap();
  await expect(grid.locator('[data-index="0"]')).toHaveText('€10.00');
  await expect(grid.locator('[data-index="1"]')).toHaveText('€20.00');

  await add.tap();
  await expect(editedRow.locator('[data-index="2"] input')).toBeFocused();
  await cancel.tap();
  await expect(actions).toHaveCount(0);

  const first = grid.locator('[data-index="0"]');
  await first.tap();
  await expect(editor).toBeFocused();
  await expect(editor).toHaveValue('11');
  await editor.fill('15');
  await cancel.tap();
  await expect(first).toHaveText('€10.00');
  await expect(editor).toHaveCount(0);
  await expect(actions).toHaveCount(0);

  await first.tap();
  await section.getByRole('button', { name: 'Currency USD', exact: true }).tap();
  await expect(currencyPicker).toBeVisible();
  const originalViewport = page.viewportSize();
  await page.setViewportSize({ width: 320, height: 320 });
  await expect.poll(() => currencyPicker.evaluate(dialog => {
    const bounds = dialog.getBoundingClientRect();
    const viewport = window.visualViewport;
    return bounds.top >= viewport.offsetTop &&
      bounds.left >= viewport.offsetLeft &&
      bounds.bottom <= viewport.offsetTop + viewport.height &&
      bounds.right <= viewport.offsetLeft + viewport.width;
  })).toBe(true);
  await currencyPicker.getByRole('searchbox').fill('eur');
  await currencyPicker.getByRole('button', { name: 'EUR', exact: true }).tap();
  await expect(currencyPicker).toBeHidden();
  await expect(editor).toHaveValue('11');
  await expect(section.getByRole('button', { name: 'Currency EUR', exact: true })).toBeVisible();
  await page.setViewportSize(originalViewport);
  await save.tap();
  await expect(first).toHaveText('€11.00');
  await expect(actions).toHaveCount(0);

  await first.tap();
  await editor.fill('12');
  await section.getByRole('button', { name: 'Currency EUR', exact: true }).tap();
  await currencyPicker.getByRole('button', { name: 'Close', exact: true }).tap();
  await expect(editor).toHaveValue('12');
  await section.locator('[data-sheet-selection]').tap();
  await expect(first).toHaveText('€12.00');
  await section.getByRole('button', { name: 'Delete', exact: true }).tap();
  await expect(first).toHaveText('€20.00');
});
