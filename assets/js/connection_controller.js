const LIVE_VIEW_ROOT_SELECTOR = '[data-phx-main]';
const OFFLINE_STATE_EVENT = 'hamster:offline-read-only';
const LIVE_VIEW_JOINED_EVENT = 'hamster:liveview-joined';
const RETRY_BUTTON_SELECTOR = '[data-connection-retry]';

const ATTEMPT_TIMEOUT_MS = 5000;
const RETRY_DELAY_MS = 250;
const PARKED_RETRY_MS = 60_000;

// Phoenix 1.7.24's Socket and LiveView 1.2.10 pass these callbacks through.
// The controller cancels parked retries with disconnect() when its 5s attempt
// deadline expires, keeping Phoenix's independent retry timers from outliving it.
export const connectionSocketOptions = {
  timeout: ATTEMPT_TIMEOUT_MS,
  reconnectAfterMs: () => PARKED_RETRY_MS,
  rejoinAfterMs: () => PARKED_RETRY_MS,
};

export function hasLiveViewRoot(documentRef = document) {
  return Boolean(documentRef.querySelector(LIVE_VIEW_ROOT_SELECTOR));
}

export function createConnectionController(
  liveSocket,
  {
    documentRef = document,
    windowRef = window,
    navigatorRef = navigator,
    timers = {
      setTimeout: (callback, delay) => windowRef.setTimeout(callback, delay),
      clearTimeout: (timer) => windowRef.clearTimeout(timer),
    },
    timeoutMs = ATTEMPT_TIMEOUT_MS,
    retryDelayMs = RETRY_DELAY_MS,
  } = {},
) {
  const managed = hasLiveViewRoot(documentRef);
  let phase = 'idle';
  let attempts = 0;
  let attemptTimer = null;
  let retryTimer = null;
  let disconnecting = false;
  let pendingManualRetry = false;
  let offlinePaused = navigatorRef.onLine === false;
  let offlineAttemptPending = false;
  let connectionUnavailableWhileOffline = false;
  let listenersInstalled = false;
  let originalReloadWithJitter = null;

  function emitState(state) {
    windowRef.dispatchEvent(
      new CustomEvent('hamster:connection-state', {
        detail: { state },
      }),
    );
  }

  function clearTimer(name) {
    if (name === 'attempt' && attemptTimer !== null) {
      timers.clearTimeout(attemptTimer);
      attemptTimer = null;
    } else if (name === 'retry' && retryTimer !== null) {
      timers.clearTimeout(retryTimer);
      retryTimer = null;
    }
  }

  function clearAttemptTimers() {
    clearTimer('attempt');
    clearTimer('retry');
  }

  function startAttempt() {
    if (phase === 'failed' || phase === 'connected' || disconnecting) {
      return;
    }

    clearTimer('retry');
    clearTimer('attempt');
    attempts += 1;
    phase = 'connecting';
    emitState('connecting');

    if (navigatorRef.onLine === false) {
      offlineAttemptPending = true;
      return;
    }

    beginSocketAttempt();
  }

  function beginSocketAttempt() {
    offlineAttemptPending = false;

    attemptTimer = timers.setTimeout(() => {
      attemptTimer = null;
      failAttempt('timeout');
    }, timeoutMs);

    liveSocket.connect();
  }

  function flushDisconnect() {
    disconnecting = false;

    if (pendingManualRetry && phase === 'failed') {
      pendingManualRetry = false;
      attempts = 0;
      phase = 'retry_wait';
      emitState('connecting');
      startAttempt();
      return;
    }

    if (phase === 'retry_wait') {
      startAttempt();
    }
  }

  function disconnectSocket() {
    if (disconnecting) {
      return;
    }

    disconnecting = true;
    let completed = false;
    const finish = () => {
      if (completed) {
        return;
      }

      completed = true;
      flushDisconnect();
    };

    try {
      liveSocket.disconnect(finish);
    } catch (_error) {
      finish();
    }
  }

  function failAttempt(_reason) {
    if (phase !== 'connecting') {
      return;
    }

    clearTimer('attempt');

    if (attempts < 2) {
      phase = 'retry_wait';
      emitState('connecting');
      retryTimer = timers.setTimeout(() => {
        retryTimer = null;
        disconnectSocket();
      }, retryDelayMs);
      return;
    }

    phase = 'failed';
    clearAttemptTimers();
    emitState('failed');
    disconnectSocket();
  }

  function beginRecovery() {
    if (phase === 'failed' || phase === 'connecting' || phase === 'retry_wait') {
      return;
    }

    attempts = 0;
    phase = 'retry_wait';
    emitState('connecting');
    retryTimer = timers.setTimeout(() => {
      retryTimer = null;
      disconnectSocket();
    }, retryDelayMs);
  }

  function joined(event) {
    if (!managed || phase === 'idle' || phase === 'failed' || disconnecting) {
      event?.preventDefault?.();
      return;
    }

    clearAttemptTimers();
    phase = 'connected';
    attempts = 0;
    emitState('connected');
  }

  function connectionLost() {
    if (!managed) {
      return;
    }

    if (navigatorRef.onLine === false || offlinePaused) {
      connectionUnavailableWhileOffline = true;
      return;
    }

    if (phase === 'connected') {
      beginRecovery();
    } else if (phase === 'connecting') {
      failAttempt('liveview-unavailable');
    }
  }

  function onOffline() {
    offlinePaused = true;

    if (phase === 'connecting') {
      clearTimer('attempt');
    } else if (phase === 'retry_wait') {
      clearTimer('retry');
    }
  }

  function onOnline() {
    offlinePaused = false;

    if (phase === 'connected' && connectionUnavailableWhileOffline) {
      connectionUnavailableWhileOffline = false;
      beginRecovery();
      return;
    }

    if (phase === 'connecting' && offlineAttemptPending) {
      beginSocketAttempt();
      return;
    }

    if (phase === 'connecting' && attemptTimer === null) {
      attemptTimer = timers.setTimeout(() => {
        attemptTimer = null;
        failAttempt('timeout');
      }, timeoutMs);
    } else if (phase === 'retry_wait' && retryTimer === null && !disconnecting) {
      retryTimer = timers.setTimeout(() => {
        retryTimer = null;
        disconnectSocket();
      }, retryDelayMs);
    }
    // A failed budget stays failed until the user presses Retry.
  }

  function manualRetry() {
    if (!managed || phase !== 'failed') {
      return;
    }

    if (disconnecting) {
      pendingManualRetry = true;
      return;
    }

    attempts = 0;
    phase = 'retry_wait';
    emitState('connecting');
    startAttempt();
  }

  function onRetryClick(event) {
    const button = event.target?.closest?.(RETRY_BUTTON_SELECTOR);

    if (button) {
      event.preventDefault();
      manualRetry();
    }
  }

  function interceptHardReload(view, log) {
    if (!managed) {
      return originalReloadWithJitter.call(liveSocket, view, log);
    }

    // In LiveView 1.2.10 main-view join failures and push timeouts call this
    // internal method to hard-reload repeatedly. The controller owns retries
    // for managed pages, so translate that request into a bounded attempt.
    if (phase === 'connected') {
      beginRecovery();
    } else if (phase === 'connecting') {
      failAttempt('liveview-recovery');
    }
  }

  function installListeners() {
    if (listenersInstalled) {
      return;
    }

    listenersInstalled = true;
    windowRef.addEventListener(LIVE_VIEW_JOINED_EVENT, joined);
    windowRef.addEventListener('offline', onOffline);
    windowRef.addEventListener('online', onOnline);
    windowRef.addEventListener(OFFLINE_STATE_EVENT, (event) => {
      if (event.detail?.connectionState === 'unavailable') {
        connectionLost();
      }
    });
    documentRef.addEventListener('click', onRetryClick);

    originalReloadWithJitter = liveSocket.reloadWithJitter;
    if (typeof originalReloadWithJitter === 'function') {
      liveSocket.reloadWithJitter = interceptHardReload;
    }
  }

  function connect() {
    if (!managed) {
      liveSocket.connect();
      return false;
    }

    if (phase !== 'idle') {
      return false;
    }

    installListeners();
    startAttempt();
    return true;
  }

  return {
    connect,
    getState: () => ({ phase, attempts, managed }),
    retry: manualRetry,
  };
}
