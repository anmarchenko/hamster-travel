import test from 'node:test';
import assert from 'node:assert/strict';

class FakeElement {
  constructor(attributes = {}) {
    this.attributes = new Set(Object.keys(attributes));
    this.dataset = { ...attributes };
    this.children = [];
    this.classList = { contains: (name) => this.classes?.has(name) ?? false };
    this.hiddenWrites = 0;
    this._hidden = false;
    this.hidden = false;
    this.inert = false;
  }

  get hidden() {
    return this._hidden;
  }

  set hidden(value) {
    this.hiddenWrites += 1;
    this._hidden = value;
  }

  append(...children) {
    this.children.push(...children);
    return children.at(-1);
  }

  matches(selector) {
    if (selector === '[data-offline-lock]') return this.attributes.has('data-offline-lock');
    if (selector === '[data-offline-notice]') return this.attributes.has('data-offline-notice');
    if (selector === '[data-connection-retry]') return this.attributes.has('data-connection-retry');
    return false;
  }

  querySelectorAll(selector) {
    const matches = [];
    const visit = (node) => {
      node.children.forEach((child) => {
        if (selector === '[data-connection-message]' && child.attributes.has('data-connection-message')) {
          matches.push(child);
        }
        if (child.matches(selector)) matches.push(child);
        visit(child);
      });
    };
    visit(this);
    return matches;
  }

  toggleAttribute(name, enabled) {
    if (enabled) this.attributes.add(name);
    else this.attributes.delete(name);
  }

  setAttribute(name) {
    this.attributes.add(name);
  }
}

class FakeHTMLElement extends FakeElement {}

const body = new FakeHTMLElement();
const liveViewRoot = new FakeHTMLElement({ 'data-phx-main': '' });
liveViewRoot.classes = new Set();
const main = new FakeHTMLElement({ 'data-offline-lock': '' });
const messages = ['connecting', 'unavailable', 'offline'].map((state) => {
  const message = new FakeHTMLElement({ 'data-connection-message': state });
  message.dataset.connectionMessage = state;
  message.hidden = state !== 'connecting';
  return message;
});
const notice = new FakeHTMLElement({ 'data-offline-notice': '' });
notice.append(...messages);
const retryButton = new FakeHTMLElement({ 'data-connection-retry': '' });
retryButton.hidden = true;
notice.append(retryButton);
notice.hidden = true;
liveViewRoot.append(main, notice);
body.append(liveViewRoot);

globalThis.Element = FakeElement;
globalThis.HTMLElement = FakeHTMLElement;
Object.defineProperty(globalThis, 'navigator', {
  configurable: true,
  value: { onLine: true },
});
globalThis.document = {
  body,
  querySelector(selector) {
    return selector === '[data-phx-main]' ? liveViewRoot : null;
  },
  querySelectorAll(selector) {
    return [body, ...body.querySelectorAll(selector)].filter((node) => node.matches(selector));
  },
};
const listeners = new Map();
globalThis.window = {
  addEventListener(name, callback) {
    const callbacks = listeners.get(name) ?? [];
    callbacks.push(callback);
    listeners.set(name, callbacks);
  },
  removeEventListener(name, callback) {
    listeners.set(name, (listeners.get(name) ?? []).filter((listener) => listener !== callback));
  },
  dispatchEvent(event) {
    this.lastEvent = event;
    listeners.get(event.type)?.forEach((callback) => callback(event));
    return !event.defaultPrevented;
  },
};
globalThis.CustomEvent = class {
  constructor(type, options = {}) {
    this.type = type;
    this.detail = options.detail;
    this.cancelable = options.cancelable ?? false;
    this.defaultPrevented = false;
  }

  preventDefault() {
    if (this.cancelable) this.defaultPrevented = true;
  }
};
let observeMutations;
globalThis.MutationObserver = class {
  constructor(callback) {
    observeMutations = callback;
  }
  observe() {}
};

const { OfflineReadOnly, initOfflineReadOnly, lockAddedOfflineRegion, preserveOfflineLock } =
  await import('../../assets/js/offline_read_only.js');

test('locks writes until LiveView joins and tracks connection loss separately from browser offline', () => {
  initOfflineReadOnly();
  assert.equal(main.inert, true);
  assert.equal(notice.hidden, false);
  assert.equal(notice.dataset.connectionState, 'connecting');
  assert.equal(messages[0].hidden, false);
  assert.equal(messages[1].hidden, true);
  assert.equal(body.attributes.has('data-offline-readonly'), true);

  liveViewRoot.classes.add('phx-error');
  observeMutations([{ target: liveViewRoot, attributeName: 'class', addedNodes: [] }]);
  assert.equal(notice.dataset.connectionState, 'unavailable');

  liveViewRoot.classes.clear();
  OfflineReadOnly.mounted();
  assert.equal(main.inert, false);
  assert.equal(notice.hidden, true);
  assert.equal(body.attributes.has('data-offline-readonly'), false);

  const onlinePatch = new FakeHTMLElement({ 'data-offline-lock': '', inert: '' });
  preserveOfflineLock(null, onlinePatch);
  assert.equal(onlinePatch.attributes.has('inert'), false);

  OfflineReadOnly.disconnected();
  assert.equal(main.inert, true);
  assert.equal(notice.dataset.connectionState, 'unavailable');
  assert.equal(messages[1].hidden, false);

  const offlinePatch = new FakeHTMLElement({ 'data-offline-lock': '', inert: '' });
  preserveOfflineLock(null, offlinePatch);
  assert.equal(offlinePatch.attributes.has('inert'), true);

  navigator.onLine = false;
  window.dispatchEvent(new CustomEvent('offline'));
  assert.equal(notice.dataset.connectionState, 'offline');
  assert.equal(messages[2].hidden, false);

  navigator.onLine = true;
  window.dispatchEvent(new CustomEvent('online'));
  assert.equal(notice.dataset.connectionState, 'unavailable');

  OfflineReadOnly.reconnected();
  assert.equal(main.inert, false);
  assert.equal(notice.hidden, true);

  window.dispatchEvent(new CustomEvent('hamster:connection-state', { detail: { state: 'failed' } }));
  assert.equal(main.inert, true);
  assert.equal(notice.dataset.connectionState, 'failed');
  assert.equal(retryButton.hidden, false);
});

test('a canceled late join cannot unlock a terminally failed LiveView', () => {
  window.dispatchEvent(new CustomEvent('hamster:connection-state', { detail: { state: 'failed' } }));
  const rejectJoin = (event) => event.preventDefault();
  window.addEventListener('hamster:liveview-joined', rejectJoin);

  OfflineReadOnly.mounted();
  window.removeEventListener('hamster:liveview-joined', rejectJoin);

  assert.equal(main.inert, true);
  assert.equal(notice.dataset.connectionState, 'failed');
  assert.equal(retryButton.hidden, false);
});

test('repeated notice synchronization does not rewrite a stable Retry hidden state', () => {
  window.dispatchEvent(new CustomEvent('hamster:connection-state', { detail: { state: 'failed' } }));
  const retryWrites = retryButton.hiddenWrites;
  const noticeWrites = notice.hiddenWrites;

  // A hidden-attribute MutationObserver can feed the notice right back into
  // synchronization. Stable values must not create another observed write.
  observeMutations([{ target: notice, attributeName: 'hidden', addedNodes: [] }]);
  observeMutations([{ target: notice, attributeName: 'hidden', addedNodes: [] }]);

  assert.equal(retryButton.hidden, false);
  assert.equal(retryButton.hiddenWrites, retryWrites);
  assert.equal(notice.hiddenWrites, noticeWrites);
});

test('resynchronizes notice state and write locks when LiveView inserts or patches nodes', () => {
  navigator.onLine = true;
  OfflineReadOnly.reconnected();
  OfflineReadOnly.disconnected();

  const addedLock = new FakeHTMLElement({ 'data-offline-lock': '' });
  lockAddedOfflineRegion(addedLock);
  assert.equal(addedLock.inert, true);

  const addedNotice = new FakeHTMLElement({ 'data-offline-notice': '' });
  const addedMessage = new FakeHTMLElement({ 'data-connection-message': 'unavailable' });
  addedMessage.dataset.connectionMessage = 'unavailable';
  addedNotice.append(addedMessage);
  liveViewRoot.append(addedNotice);
  lockAddedOfflineRegion(addedNotice);
  assert.equal(addedNotice.hidden, false);
  assert.equal(addedNotice.dataset.connectionState, 'unavailable');
  assert.equal(addedMessage.hidden, false);

  // Server-rendered inert attributes can arrive in a patch after the page has
  // already joined; preserveOfflineLock must enforce the current online state.
  OfflineReadOnly.reconnected();
  const patchedOnlineLock = new FakeHTMLElement({ 'data-offline-lock': '', inert: '' });
  preserveOfflineLock(null, patchedOnlineLock);
  assert.equal(patchedOnlineLock.attributes.has('inert'), false);

  OfflineReadOnly.disconnected();
  preserveOfflineLock(null, patchedOnlineLock);
  assert.equal(patchedOnlineLock.attributes.has('inert'), true);

  addedNotice.dataset.connectionState = 'connected';
  observeMutations([{ target: addedNotice, attributeName: 'data-connection-state', addedNodes: [] }]);
  assert.equal(addedNotice.dataset.connectionState, 'unavailable');
  assert.equal(addedNotice.hidden, false);
});

test('does not leave static pages locked when no LiveView root exists', async () => {
  const originalQuerySelector = document.querySelector;
  document.querySelector = () => null;

  const { initOfflineReadOnly: initStaticPage } = await import(
    '../../assets/js/offline_read_only.js?static-page-test'
  );

  initStaticPage();
  assert.equal(main.inert, false);
  assert.equal(notice.hidden, true);
  assert.equal(body.attributes.has('data-offline-readonly'), false);

  document.querySelector = originalQuerySelector;
});
