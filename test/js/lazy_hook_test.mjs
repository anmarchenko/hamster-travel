import test from 'node:test';
import assert from 'node:assert/strict';
import { lazyHook } from '../../assets/js/lazy_hook.js';

function deferred() {
  let resolve;
  const promise = new Promise((done) => { resolve = done; });
  return { promise, resolve };
}

test('loads only at mount and preserves the hook API and lifecycle', async () => {
  const events = [];
  let loads = 0;
  const feature = {
    mounted() { this.helper(); this.pushEvent('ready'); },
    helper() { events.push('helper'); },
    updated() { events.push('updated'); },
    disconnected() { events.push('disconnected'); },
    reconnected() { events.push('reconnected'); },
    destroyed() { events.push('destroyed'); },
  };
  const hook = lazyHook(async () => { loads++; return { default: { Feature: feature } }; }, 'Feature');
  assert.equal(loads, 0);
  const instance = { ...hook, pushEvent: (event) => events.push(event) };
  await instance.mounted();
  instance.updated();
  instance.disconnected();
  instance.reconnected();
  instance.destroyed();
  assert.equal(loads, 1);
  assert.deepEqual(events, ['helper', 'ready', 'updated', 'disconnected', 'reconnected', 'destroyed']);
});

test('navigation before import resolves never initializes a removed element', async () => {
  const loading = deferred();
  const instance = { ...lazyHook(() => loading.promise, 'Feature') };
  const mounted = instance.mounted();
  instance.destroyed();
  loading.resolve({ default: { Feature: { mounted() { assert.fail('removed hook mounted'); } } } });
  await mounted;
});

test('tracks disconnects during loading and keeps separate hook instances', async () => {
  const loading = deferred();
  const events = [];
  const hook = lazyHook(() => loading.promise, 'Feature');
  const removed = { ...hook };
  const active = { ...hook };
  const mounts = [removed.mounted(), active.mounted()];
  removed.destroyed();
  active.disconnected();
  loading.resolve({ default: { Feature: {
    mounted() { events.push('mounted'); },
    disconnected() { events.push('disconnected'); },
  } } });
  await Promise.all(mounts);
  assert.deepEqual(events, ['mounted', 'disconnected']);
});

test('a failed import is contained and a later mount retries', async () => {
  let attempts = 0;
  const hook = lazyHook(() => {
    if (++attempts === 1) return Promise.reject(new Error('offline'));
    return Promise.resolve({ default: { Feature: { mounted() { this.ready = true; } } } });
  }, 'Feature');
  const originalError = console.error;
  const errors = [];
  console.error = (...args) => errors.push(args);
  try {
    await ({ ...hook }).mounted();
    const next = { ...hook };
    await next.mounted();
    assert.equal(next.ready, true);
    assert.equal(errors.length, 1);
  } finally {
    console.error = originalError;
  }
});
