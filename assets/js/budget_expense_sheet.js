const COLUMN_WIDTH = 104;
const ROW_GUTTER = 28;
const MAX_PASTE = 100;

function textElement(tag, text) {
  const element = document.createElement(tag);
  element.textContent = text;
  return element;
}

function cellTarget(expense) {
  return { id: expense.id, expected: expense.expected, expected_currency: expense.currency };
}

function cellChange(expense, amount, currency = expense.currency) {
  return { ...cellTarget(expense), currency, amount };
}

class ExpenseSheet {
  constructor(hook) {
    this.hook = hook;
    this.root = hook.el;
    this.grid = this.root.querySelector('[data-sheet-grid]');
    this.toolbar = this.root.querySelector('[data-sheet-toolbar]');
    this.selection = this.root.querySelector('[data-sheet-selection]');
    this.status = this.root.querySelector('[data-sheet-status]');
    this.editButton = this.root.querySelector('[data-sheet-edit]');
    this.deleteButton = this.root.querySelector('[data-sheet-delete]');
    this.editControls = this.root.querySelector('[data-sheet-editor]');
    this.editCurrency = this.root.querySelector('[data-sheet-edit-currency]');
    this.editCurrencyButton = this.root.querySelector('[data-sheet-edit-currency-button]');
    this.editSave = this.root.querySelector('[data-sheet-save]');
    this.editCancel = this.root.querySelector('[data-sheet-cancel]');
    this.pastePanel = this.root.querySelector('[data-sheet-paste]');
    this.pasteCurrency = this.root.querySelector('[data-sheet-paste-currency]');
    this.pasteCurrencyButton = this.root.querySelector('[data-sheet-paste-currency-button]');
    this.pasteCount = this.root.querySelector('[data-sheet-paste-count]');
    this.pasteSave = this.root.querySelector('[data-sheet-paste-save]');
    this.currencyDialog = this.root.querySelector('[data-sheet-currency-picker]');
    this.currencySearch = this.root.querySelector('[data-sheet-currency-search]');
    this.currencyChoices = this.root.querySelector('[data-sheet-currency-options]');
    this.currencyEmpty = this.root.querySelector('[data-sheet-currency-empty]');
    this.labels = JSON.parse(this.root.dataset.labels);
    this.snapshot = JSON.parse(this.root.dataset.snapshot);
    this.columns = this.columnCount();
    this.anchor = 0;
    this.active = 0;
    this.request = 0;
    this.connected = true;
    this.offline = document.body.hasAttribute('data-offline-readonly');
    this.listeners = new AbortController();
    this.bindEvents();
    this.resize = new ResizeObserver(() => this.resizeGrid());
    this.resize.observe(this.root);
    this.draw();
    this.root.classList.add('budget-expense-sheet-ready');
    if (typeof this.currencyDialog.showModal === 'function') {
      this.root.classList.add('budget-sheet-currency-picker-ready');
    }
  }

  bindEvents() {
    const listen = (target, event, callback) => {
      target.addEventListener(event, callback, { signal: this.listeners.signal });
    };
    listen(this.grid, 'keydown', event => this.onKey(event));
    listen(this.grid, 'pointerdown', event => this.onPointerDown(event));
    document.addEventListener('click', event => {
      if (this.draft && !this.currencyDialog.open &&
          !this.grid.contains(event.target) && !this.editControls.contains(event.target)) {
        this.saveEdit(this.active, { focus: false });
      }
    }, { capture: true, signal: this.listeners.signal });
    listen(this.grid, 'pointerover', event => {
      const index = this.targetIndex(event);
      if (this.dragging && event.buttons === 1 && index !== null) this.select(index, true);
    });
    listen(document, 'pointerup', () => { this.dragging = false; });
    listen(document, 'pointercancel', () => {
      this.dragging = false;
      this.tapCell = null;
    });
    listen(this.grid, 'click', event => {
      const index = this.targetIndex(event);
      const tap = index !== null && this.tapCell === index;
      this.tapCell = null;
      if (index === null || this.busy || this.paste) return;
      if (this.draft) {
        if (tap && index !== this.active) this.saveEdit(index);
        return;
      }
      const edit = tap && this.canEdit();
      this.select(index, event.shiftKey, !edit);
      if (edit) this.startEdit(undefined, true);
    });
    listen(this.grid, 'dblclick', event => {
      if (this.targetIndex(event) !== null) this.startEdit();
    });
    listen(this.grid, 'focusin', event => {
      const index = this.targetIndex(event);
      if (index !== null && index !== this.active && !this.draft && !this.paste) {
        this.select(index, false, false);
      }
    });
    // Firefox targets the document body when a grid cell has focus but no text selection.
    listen(document, 'copy', event => {
      if (this.grid.contains(document.activeElement)) this.copy(event);
    });
    listen(document, 'paste', event => {
      if (this.grid.contains(document.activeElement)) this.pasteClipboard(event);
    });
    listen(this.editButton, 'click', () => this.startEdit(undefined, true));
    listen(this.deleteButton, 'click', () => this.deleteSelection());
    listen(this.editCurrency, 'change', () => {
      this.draft.currency = this.editCurrency.value;
      this.draft.input.setAttribute('aria-label', this.amountLabel());
      this.updateSelection();
    });
    listen(this.editCurrencyButton, 'click', () => this.openCurrencyPicker(this.editCurrency));
    listen(this.pasteCurrencyButton, 'click', () => this.openCurrencyPicker(this.pasteCurrency));
    listen(this.pasteCurrency, 'change', () => this.updateControls());
    listen(this.currencySearch, 'input', () => this.renderCurrencyChoices());
    listen(this.currencyDialog, 'keydown', event => this.onCurrencyPickerKey(event));
    listen(this.currencyChoices, 'click', event => {
      const choice = event.target.closest('[data-currency-choice]');
      if (!choice || !this.canEdit()) return;
      this.currencySource.value = choice.dataset.currencyChoice;
      this.currencySource.dispatchEvent(new Event('change'));
      this.currencyDialog.close();
    });
    listen(this.currencyDialog.querySelector('[data-sheet-currency-close]'), 'click', () => this.currencyDialog.close());
    listen(window, 'resize', () => this.positionCurrencyPicker());
    if (window.visualViewport) {
      listen(window.visualViewport, 'resize', () => this.positionCurrencyPicker());
      listen(window.visualViewport, 'scroll', () => this.positionCurrencyPicker());
    }
    listen(this.editSave, 'click', () => this.saveEdit(this.active));
    listen(this.editCancel, 'click', () => this.closeEdit(this.active));
    listen(this.editControls, 'keydown', event => {
      if (event.key === 'Escape' && this.draft && !this.busy) {
        event.preventDefault();
        event.stopPropagation();
        this.closeEdit(this.active);
      }
    });
    listen(this.pasteSave, 'click', () => this.savePaste());
    listen(this.root.querySelector('[data-sheet-paste-cancel]'), 'click', () => this.closePaste());
    listen(this.pastePanel, 'keydown', event => {
      if (event.key === 'Escape' && !this.busy) {
        event.stopPropagation();
        this.closePaste();
      }
    });
    listen(window, 'hamster:offline-read-only', event => {
      this.offline = event.detail.readOnly;
      this.updateControls();
    });
  }

  get expenses() { return this.snapshot.expenses; }

  get last() { return Math.max(0, this.expenses.length - (this.snapshot.can_edit ? 0 : 1)); }

  canEdit() { return this.snapshot.can_edit && this.connected && !this.offline && !this.busy; }

  columnCount() {
    return this.root.clientWidth >= ROW_GUTTER + 4 * COLUMN_WIDTH ? 4 : 2;
  }

  resizeGrid() {
    if (!this.root.clientWidth || this.columns === this.columnCount() || this.draft || this.paste || this.busy) return;
    const focused = this.grid.contains(document.activeElement);
    this.columns = this.columnCount();
    this.anchor = this.active;
    this.draw();
    if (focused) this.cell(this.active)?.focus();
  }

  coords(index) { return [index % this.columns, Math.floor(index / this.columns)]; }

  address(index) {
    const [x, y] = this.coords(index);
    return `${String.fromCharCode(65 + x)}${y + 1}`;
  }

  cell(index) { return this.grid.querySelector(`[data-index="${index}"]`); }

  targetIndex(event) {
    const cell = event.target.closest('[data-index]');
    return cell ? Number(cell.dataset.index) : null;
  }

  range() {
    const [ax, ay] = this.coords(this.anchor);
    const [bx, by] = this.coords(this.active);
    return { left: Math.min(ax, bx), right: Math.max(ax, bx), top: Math.min(ay, by), bottom: Math.max(ay, by) };
  }

  draw() {
    this.grid.style.setProperty('--sheet-columns', this.columns);
    const head = document.createElement('thead');
    const heading = head.insertRow();
    const gutter = document.createElement('th');
    gutter.className = 'budget-sheet-gutter';
    heading.append(gutter);
    for (let x = 0; x < this.columns; x++) {
      const header = textElement('th', String.fromCharCode(65 + x));
      header.scope = 'col';
      heading.append(header);
    }

    const body = document.createElement('tbody');
    for (let y = 0; y <= this.coords(this.last)[1]; y++) {
      const row = body.insertRow();
      const header = textElement('th', y + 1);
      header.scope = 'row';
      row.append(header);
      for (let x = 0; x < this.columns; x++) {
        const index = y * this.columns + x;
        const cell = row.insertCell();
        if (index > this.last) continue;
        const expense = this.expenses[index];
        const value = textElement('span', expense ? expense.display : '+');
        cell.append(value);
        cell.dataset.index = index;
        cell.setAttribute('aria-label', `${this.address(index)} ${expense?.display ?? this.labels.add}`);
        if (expense?.converted) {
          cell.dataset.converted = '';
          cell.title = expense.original;
        } else if (expense) {
          cell.title = expense.display;
        } else {
          cell.dataset.add = '';
        }
      }
    }
    this.grid.replaceChildren(head, body);
    this.updateSelection();
  }

  updateSelection() {
    const { left, right, top, bottom } = this.range();
    for (const cell of this.grid.querySelectorAll('[data-index]')) {
      const index = Number(cell.dataset.index);
      const [x, y] = this.coords(index);
      cell.tabIndex = index === this.active ? 0 : -1;
      cell.toggleAttribute('data-anchor', index === this.anchor);
      cell.setAttribute('aria-selected', String(x >= left && x <= right && y >= top && y <= bottom));
    }

    const expense = this.expenses[this.active];
    const currency = expense?.currency ?? this.snapshot.trip_currency;
    let detail = expense ? currency : this.labels.add_in.replace('{currency}', currency);
    if (this.draft) {
      detail = this.amountLabel();
    } else if (expense?.converted || (expense && expense.copy === null)) {
      detail = this.labels.original.replace('{amount}', expense.original);
    }
    this.selection.textContent = this.anchor === this.active
      ? `${this.address(this.active)} · ${detail}`
      : this.labels.range.replace('{range}', `${this.address(top * this.columns + left)}:${this.address(bottom * this.columns + right)}`);
    this.updateControls();
  }

  updateControls() {
    const canEdit = this.canEdit();
    this.grid.setAttribute('aria-readonly', String(!canEdit));
    const showActions = this.snapshot.can_edit && !this.draft && !this.paste;
    const { left, top } = this.range();
    this.editButton.hidden = !showActions || this.anchor !== this.active;
    this.editButton.disabled = !canEdit;
    this.editButton.textContent = this.expenses[this.active] ? this.editButton.dataset.editLabel : this.labels.add;
    this.deleteButton.hidden = !showActions || !this.expenses[top * this.columns + left];
    this.deleteButton.disabled = !canEdit;
    this.editControls.hidden = !this.draft;
    this.editCurrency.disabled = !canEdit;
    this.editCurrencyButton.disabled = !canEdit;
    this.editCurrencyButton.querySelector('[data-sheet-currency-code]').textContent = this.editCurrency.value;
    this.editSave.disabled = !canEdit;
    this.editCancel.disabled = this.busy;
    this.pasteSave.disabled = !canEdit;
    this.pasteCurrency.disabled = this.busy || !canEdit;
    this.pasteCurrencyButton.disabled = !canEdit;
    this.pasteCurrencyButton.querySelector('[data-sheet-currency-code]').textContent = this.pasteCurrency.value;
    if (!canEdit && this.currencyDialog.open) this.currencyDialog.close();
    if (this.draft) this.draft.input.readOnly = !canEdit;
  }

  select(index, extend = false, focus = true) {
    this.active = index;
    if (!extend) this.anchor = index;
    this.updateSelection();
    if (focus) this.cell(index)?.focus();
  }

  onPointerDown(event) {
    const index = this.targetIndex(event);
    this.tapCell = null;
    if (event.button !== 0 || index === null || this.busy || this.paste) return;
    if (event.pointerType === 'touch' || event.pointerType === 'pen') {
      this.tapCell = index;
      return;
    }
    if (this.draft) {
      if (event.target !== this.draft.input) {
        event.preventDefault();
        this.saveEdit(index);
      }
      return;
    }
    if (event.pointerType === 'mouse') {
      event.preventDefault();
      this.select(index, event.shiftKey);
      this.dragging = true;
    }
  }

  onKey(event) {
    if (this.editControls.contains(event.target)) return;
    const { key, shiftKey, altKey, ctrlKey, metaKey } = event;
    if (this.draft) {
      if (key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        if (!this.busy) this.closeEdit(this.active);
      } else if (key === 'Tab' || key === 'Enter') {
        if (key === 'Tab' && (!this.canEdit() || this.draft.tabThroughControls)) return;
        event.preventDefault();
        const step = key === 'Tab' ? 1 : this.columns;
        const next = this.draft.expense ? this.active + (shiftKey ? -step : step) : this.active + 1;
        this.saveEdit(next);
      }
      return;
    }
    if (this.busy || this.paste || altKey || ctrlKey || metaKey) return;
    if (key === 'Delete' || key === 'Backspace') {
      if (this.canEdit()) {
        event.preventDefault();
        this.deleteSelection();
      }
      return;
    }
    if (key === 'Enter' && this.expenses[this.active] && !this.canEdit()) {
      event.preventDefault();
      const next = this.active + (shiftKey ? -this.columns : this.columns);
      if (next >= 0 && next <= this.last) this.select(next);
      return;
    }
    if (key === 'Enter' || key === 'F2' || /^[0-9]$/.test(key)) {
      if (this.canEdit()) {
        event.preventDefault();
        this.startEdit(key.length === 1 ? key : undefined);
      }
      return;
    }
    const directions = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -this.columns, ArrowDown: this.columns };
    if (key === 'Tab') {
      const next = this.active + (shiftKey ? -1 : 1);
      if (next < 0 || next > this.last) return;
      event.preventDefault();
      this.select(next);
    } else if (Object.hasOwn(directions, key)) {
      event.preventDefault();
      const [x] = this.coords(this.active);
      if ((key === 'ArrowLeft' && x === 0) || (key === 'ArrowRight' && x === this.columns - 1)) return;
      const next = this.active + directions[key];
      if (next >= 0 && next <= this.last) this.select(next, shiftKey);
    }
  }

  amountLabel() {
    return this.labels.amount_in.replace('{currency}', this.draft.currency);
  }

  startEdit(replacement, tabThroughControls = false) {
    if (!this.canEdit() || this.draft || this.paste) return;
    const expense = this.expenses[this.active];
    const currency = expense?.currency ?? this.snapshot.trip_currency;
    const input = document.createElement('input');
    input.type = 'text';
    input.inputMode = 'decimal';
    input.enterKeyHint = 'done';
    input.maxLength = 64;
    input.autocomplete = 'off';
    input.value = replacement ?? expense?.input ?? '';
    this.draft = { input, expense, currency, tabThroughControls };
    input.setAttribute('aria-label', this.amountLabel());
    this.setCurrencyOptions(this.editCurrency, currency);
    this.anchor = this.active;
    const cell = this.cell(this.active);
    cell.replaceChildren(input);
    if (window.matchMedia('(pointer: coarse)').matches) {
      const controlsRow = document.createElement('tr');
      controlsRow.dataset.sheetEditorRow = '';
      controlsRow.setAttribute('role', 'presentation');
      const controlsCell = controlsRow.insertCell();
      controlsCell.colSpan = this.columns + 1;
      controlsCell.setAttribute('role', 'presentation');
      controlsCell.append(this.editControls);
      cell.parentElement.before(controlsRow);
    }
    this.setStatus('');
    this.updateSelection();
    input.focus();
    input.setSelectionRange(input.value.length, input.value.length);
  }

  saveEdit(next, { focus = true } = {}) {
    if (!this.canEdit() || !this.draft) return;
    const { input, expense, currency } = this.draft;
    if (!expense && !input.value.trim()) {
      this.closeEdit(this.active, { focus });
      return;
    }
    const change = expense ? cellChange(expense, input.value, currency) : { amount: input.value, currency };
    const nextId = this.expenses[next]?.id;
    const nextIsAdd = next === this.expenses.length;
    const address = this.address(this.active);
    this.save(expense ? 'edit' : 'add', [change], [address], () => {
      if (expense && !this.expenses.some(item => item.id === expense.id)) {
        this.closeEdit(this.active, { reconcile: false, focus });
        return;
      }
      const target = !expense || nextIsAdd
        ? this.expenses.length
        : this.expenses.findIndex(item => item.id === nextId);
      this.closeEdit(target >= 0 ? target : this.active, { reconcile: false, focus });
    });
  }

  closeEdit(index, options) {
    this.draft = null;
    if (this.grid.contains(this.editControls)) this.toolbar.append(this.editControls);
    this.setStatus('');
    this.selectFromSnapshot(index, options);
  }

  deleteSelection() {
    if (!this.canEdit() || this.draft || this.paste) return;
    const { left, right, top, bottom } = this.range();
    const changes = [];
    const addresses = [];
    for (let y = top; y <= bottom; y++) {
      for (let x = left; x <= right; x++) {
        const index = y * this.columns + x;
        const expense = this.expenses[index];
        if (!expense) continue;
        if (changes.length === MAX_PASTE) {
          this.setStatus(this.labels.delete_too_large, true);
          return;
        }
        changes.push(cellTarget(expense));
        addresses.push(this.address(index));
      }
    }
    if (changes.length) {
      this.save('delete', changes, addresses, () => {
        this.selectFromSnapshot(top * this.columns + left, { reconcile: false });
      });
    }
  }

  copy(event) {
    if (this.draft || !event.clipboardData) return;
    const { left, right, top, bottom } = this.range();
    const rows = [];
    for (let y = top; y <= bottom; y++) {
      const row = [];
      for (let x = left; x <= right; x++) {
        const index = y * this.columns + x;
        const value = this.expenses[index]?.copy;
        if (value === null) {
          event.preventDefault();
          this.setStatus(`${this.address(index)} · ${this.labels.unavailable_conversion}`, true);
          return;
        }
        row.push(value ?? '');
      }
      rows.push(row.join('\t'));
    }
    event.clipboardData.setData('text/plain', rows.join('\n'));
    event.preventDefault();
  }

  pasteClipboard(event) {
    if (!event.clipboardData || !this.canEdit() || this.paste) return;
    const text = event.clipboardData.getData('text/plain');
    if (this.draft && (this.draft.expense || this.draft.input.value || !/[\t\r\n]/.test(text.trim()))) return;
    event.preventDefault();
    if (text.length > 8192) {
      this.setStatus(this.labels.paste_too_large, true);
      return;
    }
    const { left, top } = this.range();
    const append = this.anchor === this.active && this.active === this.expenses.length;
    const changes = [];
    const addresses = [];
    const lines = text.replace(/\r\n?/g, '\n').split('\n');
    for (const [y, line] of lines.entries()) {
      for (const [x, raw] of line.split('\t').entries()) {
        const amount = raw.trim();
        if (!amount) continue;
        if (changes.length === MAX_PASTE) {
          this.setStatus(this.labels.paste_too_large, true);
          return;
        }
        const index = append ? this.expenses.length + changes.length : (top + y) * this.columns + left + x;
        const expense = this.expenses[index];
        if (!append && (left + x >= this.columns || !expense)) {
          this.setStatus(`${String.fromCharCode(65 + left + x)}${top + y + 1} · ${this.labels.paste_outside}`, true);
          return;
        }
        changes.push(append ? { amount } : cellChange(expense, amount));
        addresses.push(this.address(index));
      }
    }
    if (!changes.length) return;
    if (this.draft) this.closeEdit(this.active, { reconcile: false, focus: false });
    if (append && this.snapshot.currency !== this.snapshot.trip_currency) {
      this.openPaste(changes, addresses);
    } else if (append) {
      this.append(changes, addresses, this.snapshot.trip_currency);
    } else {
      const targetId = this.expenses[top * this.columns + left].id;
      this.save('replace', changes, addresses, () => {
        const target = this.expenses.findIndex(item => item.id === targetId);
        this.selectFromSnapshot(target >= 0 ? target : this.active, { reconcile: false });
      });
    }
  }

  openPaste(changes, addresses) {
    this.paste = { changes, addresses };
    this.setCurrencyOptions(this.pasteCurrency, this.snapshot.currency);
    this.pasteCount.textContent = this.labels.paste_count.replace('{count}', changes.length);
    this.pastePanel.hidden = false;
    this.setStatus('');
    this.updateControls();
    const currencyControl = this.pasteCurrencyButton.getClientRects().length
      ? this.pasteCurrencyButton
      : this.pasteCurrency;
    currencyControl.focus();
  }

  setCurrencyOptions(select, selected) {
    const currencies = new Set(JSON.parse(this.root.dataset.currencies));
    currencies.add(selected);
    select.replaceChildren(...Array.from(currencies, currency => new Option(currency, currency)));
    select.value = selected;
  }

  openCurrencyPicker(select) {
    if (!this.canEdit() || this.currencyDialog.open) return;
    this.currencySource = select;
    this.currencySearch.value = '';
    this.renderCurrencyChoices();
    this.currencyDialog.showModal();
    this.positionCurrencyPicker();
  }

  onCurrencyPickerKey(event) {
    if (event.isComposing) return;
    if (event.key === 'Escape') {
      event.preventDefault();
      event.stopPropagation();
      this.currencyDialog.close();
    } else if (event.key === 'Enter' && event.target === this.currencySearch) {
      event.preventDefault();
      const query = this.currencySearch.value.trim().toUpperCase();
      const choices = Array.from(this.currencyChoices.children);
      const choice = choices.find(button => button.dataset.currencyChoice === query);
      (choice ?? (choices.length === 1 ? choices[0] : null))?.click();
    }
  }

  renderCurrencyChoices() {
    const { options, value } = this.currencySource;
    const query = this.currencySearch.value.trim().toUpperCase();
    const codes = new Set([value, ...Array.from(options, option => option.value)]);
    const choices = [];
    for (const code of codes) {
      if (!code.includes(query)) continue;
      const button = textElement('button', code);
      button.type = 'button';
      button.dataset.currencyChoice = code;
      if (code === value) button.setAttribute('aria-current', 'true');
      choices.push(button);
    }
    this.currencyChoices.replaceChildren(...choices);
    this.currencyChoices.scrollTop = 0;
    this.currencyEmpty.hidden = choices.length > 0;
  }

  positionCurrencyPicker() {
    if (!this.currencyDialog.open) return;
    const viewport = window.visualViewport;
    const width = viewport?.width ?? window.innerWidth;
    const height = viewport?.height ?? window.innerHeight;
    const left = (viewport?.offsetLeft ?? 0) + width / 2;
    const top = (viewport?.offsetTop ?? 0) + height / 2;
    this.currencyDialog.style.setProperty('--currency-width', `${width}px`);
    this.currencyDialog.style.setProperty('--currency-height', `${height}px`);
    this.currencyDialog.style.left = `${left}px`;
    this.currencyDialog.style.top = `${top}px`;
  }

  savePaste() {
    if (this.paste && this.canEdit()) this.append(this.paste.changes, this.paste.addresses, this.pasteCurrency.value);
  }

  closePaste(reconcile = true) {
    this.paste = null;
    this.pastePanel.hidden = true;
    this.setStatus('');
    this.selectFromSnapshot(this.expenses.length, { reconcile });
  }

  append(changes, addresses, currency) {
    this.save('append', changes.map(change => ({ ...change, currency })), addresses, () => this.closePaste(false));
  }

  async send(event, payload) {
    const [result] = await this.hook.pushEventTo(this.root, event, payload);
    if (result?.status === 'fulfilled') return result.value.reply;
    throw new Error('Expense sheet event did not reach the server');
  }

  save(mode, cells, addresses, onSaved) {
    const request = ++this.request;
    const tail = this.expenses[this.expenses.length - 1]?.id ?? null;
    this.busy = true;
    this.updateControls();
    this.setStatus(this.labels.saving);
    this.send('expense_sheet_save', { mode, cells, tail }).then(reply => {
      if (request !== this.request) return;
      this.busy = false;
      this.updateControls();
      if (!reply?.snapshot) {
        this.updated();
        const address = addresses[reply?.index];
        const message = reply?.error ?? this.labels.disconnected;
        this.setStatus(address ? `${address} · ${message}` : message, true);
        if (this.draft) this.draft.input.setAttribute('aria-invalid', 'true');
        return;
      }
      this.snapshot = reply.snapshot;
      this.setStatus('');
      onSaved();
    }, () => {
      if (request !== this.request) return;
      this.busy = false;
      this.updateControls();
      this.setStatus(this.labels.disconnected, true);
    });
  }

  setStatus(message, error = false) {
    this.status.textContent = message;
    this.status.toggleAttribute('data-error', error);
  }

  selectFromSnapshot(index, { reconcile = true, focus = true } = {}) {
    this.anchor = this.active = Math.max(0, Math.min(index, this.last));
    this.draw();
    if (reconcile) this.updated();
    this.resizeGrid();
    if (focus) this.cell(this.active)?.focus();
  }

  updated() {
    const next = JSON.parse(this.root.dataset.snapshot);
    if (this.draft || this.paste || this.busy) {
      if (!next.can_edit) this.snapshot = { ...this.snapshot, can_edit: false };
      this.updateControls();
      return;
    }
    if (JSON.stringify(next) === JSON.stringify(this.snapshot)) return;
    const activeId = this.expenses[this.active]?.id;
    const anchorId = this.expenses[this.anchor]?.id;
    const focused = this.grid.contains(document.activeElement);
    this.snapshot = next;
    const locate = (id, previous) => {
      if (!id) return this.last;
      const index = this.expenses.findIndex(expense => expense.id === id);
      return index >= 0 ? index : Math.min(previous, this.last);
    };
    this.active = locate(activeId, this.active);
    this.anchor = locate(anchorId, this.anchor);
    this.draw();
    if (focused) this.cell(this.active)?.focus();
  }

  disconnected() {
    this.connected = false;
    if (this.busy) {
      this.request++;
      this.busy = false;
      this.setStatus(this.labels.disconnected, true);
    }
    this.updateControls();
  }

  destroy() {
    this.request++;
    this.listeners.abort();
    this.resize.disconnect();
  }
}

const BudgetExpenseSheet = {
  mounted() { this.sheet = new ExpenseSheet(this); },
  updated() { this.sheet.updated(); },
  disconnected() { this.sheet.disconnected(); },
  reconnected() { this.sheet.connected = true; this.sheet.updated(); this.sheet.updateControls(); },
  destroyed() { this.sheet.destroy(); },
};

export default { BudgetExpenseSheet };
