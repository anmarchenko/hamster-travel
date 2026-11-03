import test from 'node:test';
import assert from 'node:assert/strict';

class FakeTimers {
  constructor() {
    this.now = 0;
    this.nextId = 1;
    this.tasks = new Map();
  }

  setTimeout = (callback, delay) => {
    const id = this.nextId++;
    this.tasks.set(id, { callback, due: this.now + delay });
    return id;
  };

  clearTimeout = (id) => {
    this.tasks.delete(id);
  };

  advance(ms) {
    const end = this.now + ms;

    while (true) {
      const next = [...this.tasks.entries()]
        .filter(([, task]) => task.due <= end)
        .sort((a, b) => a[1].due - b[1].due)[0];

      if (!next) break;
      const [id, task] = next;
      this.tasks.delete(id);
      this.now = task.due;
      task.callback();
    }

    this.now = end;
  }
}

class FakeWindow {
  constructor() {
    this.listeners = new Map();
    this.events = [];
  }

  addEventListener(name, callback) {
    const callbacks = this.listeners.get(name) ?? [];
    callbacks.push(callback);
    this.listeners.set(name, callbacks);
  }

  dispatchEvent(event) {
    this.events.push(event);
    this.listeners.get(event.type)?.forEach((callback) => callback(event));
  }

  emit(type, detail = {}) {
    this.dispatchEvent({ type, detail });
  }
}

class FakeDocument {
  constructor(hasRoot) {
    this.root = hasRoot ? {} : null;
    this.listeners = new Map();
  }

  querySelector(selector) {
    return selector === '[data-phx-main]' ? this.root : null;
  }

  addEventListener(name, callback) {
    this.listeners.set(name, callback);
  }

  clickRetry() {
    const button = {};
    this.listeners.get('click')?.({
      target: { closest: (selector) => (selector === '[data-connection-retry]' ? button : null) },
      preventDefault() {},
    });
  }
}

class FakeLiveSocket {
  constructor() {
    this.connectCalls = 0;
    this.disconnectCalls = 0;
    this.reloadCalls = 0;
    this.deferDisconnect = false;
    this.disconnectCallbacks = [];
    this.reloadWithJitter = () => {
      this.reloadCalls += 1;
    };
  }

  connect() {
    this.connectCalls += 1;
  }

  disconnect(callback) {
    this.disconnectCalls += 1;
    if (this.deferDisconnect) {
      this.disconnectCallbacks.push(callback);
    } else {
      callback?.();
    }
  }
}

globalThis.CustomEvent = class {
  constructor(type, options = {}) {
    this.type = type;
    this.detail = options.detail;
  }
};

const { connectionSocketOptions, createConnectionController } = await import(
  '../../assets/js/connection_controller.js'
);

function setup(hasRoot = true) {
  const timers = new FakeTimers();
  const windowRef = new FakeWindow();
  const documentRef = new FakeDocument(hasRoot);
  const navigatorRef = { onLine: true };
  const liveSocket = new FakeLiveSocket();
  const controller = createConnectionController(liveSocket, {
    documentRef,
    windowRef,
    navigatorRef,
    timers,
  });

  return { controller, documentRef, liveSocket, navigatorRef, timers, windowRef };
}

test('default timers keep the Window receiver required by browsers', () => {
  const windowRef = new FakeWindow();
  const calls = [];
  windowRef.setTimeout = function (_callback, delay) {
    assert.equal(this, windowRef);
    calls.push(delay);
    return 42;
  };
  windowRef.clearTimeout = function (timer) {
    assert.equal(this, windowRef);
    assert.equal(timer, 42);
  };
  const controller = createConnectionController(new FakeLiveSocket(), {
    windowRef,
    documentRef: new FakeDocument(true),
    navigatorRef: { onLine: true },
  });

  controller.connect();
  assert.deepEqual(calls, [5000]);
  windowRef.emit('hamster:liveview-joined');
  assert.equal(controller.getState().phase, 'connected');
});

test('bounds a hanging LiveView join to two attempts even if the WebSocket opens', () => {
  assert.equal(connectionSocketOptions.timeout, 5000);
  assert.equal(connectionSocketOptions.reconnectAfterMs(), 60_000);
  assert.equal(connectionSocketOptions.rejoinAfterMs(), 60_000);

  const { controller, liveSocket, timers, windowRef } = setup();
  controller.connect();
  assert.deepEqual(controller.getState(), { phase: 'connecting', attempts: 1, managed: true });

  // A transport open alone is deliberately not a join success.
  windowRef.emit('phx:socket-open');
  timers.advance(5000);
  assert.equal(controller.getState().phase, 'retry_wait');
  timers.advance(250);
  assert.equal(liveSocket.disconnectCalls, 1);
  assert.equal(liveSocket.connectCalls, 2);
  assert.equal(controller.getState().attempts, 2);

  timers.advance(5000);
  assert.equal(controller.getState().phase, 'failed');
  assert.equal(liveSocket.disconnectCalls, 2);
  assert.equal(liveSocket.reloadCalls, 0);
  timers.advance(120_000);
  assert.equal(liveSocket.connectCalls, 2);
});

test('successful hook join cancels the deadline and a later loss starts one recovery cycle', () => {
  const { controller, liveSocket, timers, windowRef } = setup();
  controller.connect();
  windowRef.emit('hamster:liveview-joined');
  assert.deepEqual(controller.getState(), { phase: 'connected', attempts: 0, managed: true });
  timers.advance(60_000);
  assert.equal(liveSocket.connectCalls, 1);

  windowRef.emit('hamster:offline-read-only', { connectionState: 'unavailable' });
  assert.equal(controller.getState().phase, 'retry_wait');
  timers.advance(250);
  assert.equal(liveSocket.disconnectCalls, 1);
  assert.equal(liveSocket.connectCalls, 2);

  windowRef.emit('hamster:liveview-joined');
  timers.advance(10_000);
  assert.deepEqual(controller.getState(), { phase: 'connected', attempts: 0, managed: true });
});

test('stale successful join events cannot unlock during disconnect or after terminal failure', () => {
  const { controller, liveSocket, timers, windowRef } = setup();
  liveSocket.deferDisconnect = true;
  controller.connect();

  timers.advance(5000);
  timers.advance(250);
  assert.equal(controller.getState().phase, 'retry_wait');
  windowRef.emit('hamster:liveview-joined');
  assert.equal(controller.getState().phase, 'retry_wait');
  liveSocket.disconnectCallbacks.shift()();
  assert.equal(controller.getState().phase, 'connecting');

  timers.advance(5000);
  assert.equal(controller.getState().phase, 'failed');
  windowRef.emit('hamster:liveview-joined');
  assert.equal(controller.getState().phase, 'failed');
  liveSocket.disconnectCallbacks.shift()();
  windowRef.emit('hamster:liveview-joined');
  assert.equal(controller.getState().phase, 'failed');
});

test('repeated errors are idempotent, hard reload requests become bounded retries, and Retry resets the budget', () => {
  const { controller, documentRef, liveSocket, navigatorRef, timers, windowRef } = setup();
  controller.connect();

  liveSocket.reloadWithJitter({}, () => {});
  windowRef.emit('hamster:offline-read-only', { connectionState: 'unavailable' });
  assert.equal(controller.getState().phase, 'retry_wait');
  assert.equal(liveSocket.reloadCalls, 0);
  timers.advance(250);
  assert.equal(liveSocket.connectCalls, 2);

  windowRef.emit('hamster:offline-read-only', { connectionState: 'unavailable' });
  windowRef.emit('hamster:offline-read-only', { connectionState: 'unavailable' });
  assert.equal(controller.getState().phase, 'failed');
  assert.equal(liveSocket.disconnectCalls, 2);

  navigatorRef.onLine = true;
  windowRef.emit('online');
  timers.advance(60_000);
  assert.equal(liveSocket.connectCalls, 2);

  documentRef.clickRetry();
  assert.equal(controller.getState().phase, 'connecting');
  assert.equal(controller.getState().attempts, 1);
  assert.equal(liveSocket.connectCalls, 3);
});

test('static pages without a LiveView root connect normally and are not controller-managed', () => {
  const { controller, liveSocket, timers } = setup(false);
  controller.connect();
  assert.deepEqual(controller.getState(), { phase: 'idle', attempts: 0, managed: false });
  assert.equal(liveSocket.connectCalls, 1);

  liveSocket.reloadWithJitter({}, () => {});
  timers.advance(60_000);
  assert.equal(liveSocket.reloadCalls, 1);
  assert.equal(liveSocket.connectCalls, 1);
});
