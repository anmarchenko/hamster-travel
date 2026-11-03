const LOCK_SELECTOR = '[data-offline-lock]';
const NOTICE_SELECTOR = '[data-offline-notice]';
const MESSAGE_SELECTOR = '[data-connection-message]';
const RETRY_SELECTOR = '[data-connection-retry]';
const OFFLINE_MARKER = 'data-offline-readonly';
const ERROR_CLASSES = ['phx-error', 'phx-client-error', 'phx-server-error'];

let initialized = false;
let liveViewStatus = null;
let liveViewPage = false;
let readOnly = false;
let lastConnectionState = null;

function isElement(node) {
  return typeof Element !== 'undefined' && node instanceof Element;
}

function isHtmlElement(node) {
  return typeof HTMLElement !== 'undefined' && node instanceof HTMLElement;
}

function connectionState() {
  if (!liveViewPage) {
    return 'connected';
  }

  if (navigator.onLine === false) {
    return 'offline';
  }

  return liveViewStatus;
}

function shouldBeReadOnly() {
  return connectionState() !== 'connected';
}

function syncRegion(region, locked) {
  if (isHtmlElement(region)) {
    region.inert = locked;
  }
}

function syncNotice(notice, state) {
  if (!isHtmlElement(notice)) {
    return;
  }

  const hidden = state === 'connected';

  if (notice.hidden !== hidden) {
    notice.hidden = hidden;
  }

  if (notice.dataset.connectionState !== state) {
    notice.dataset.connectionState = state;
  }

  notice.querySelectorAll(MESSAGE_SELECTOR).forEach((message) => {
    if (isHtmlElement(message)) {
      const hidden = message.dataset.connectionMessage !== state;

      if (message.hidden !== hidden) {
        message.hidden = hidden;
      }
    }
  });

  notice.querySelectorAll(RETRY_SELECTOR).forEach((button) => {
    if (isHtmlElement(button)) {
      const hidden = state !== 'failed';

      if (button.hidden !== hidden) {
        button.hidden = hidden;
      }
    }
  });
}

function syncNode(node, state) {
  if (!isElement(node)) {
    return;
  }

  if (node.matches(NOTICE_SELECTOR)) {
    syncNotice(node, state);
  }

  node.querySelectorAll(NOTICE_SELECTOR).forEach((notice) => syncNotice(notice, state));

  if (node.matches(LOCK_SELECTOR)) {
    syncRegion(node, state !== 'connected');
  }

  node.querySelectorAll(LOCK_SELECTOR).forEach((region) => {
    syncRegion(region, state !== 'connected');
  });
}

function syncDom() {
  const state = connectionState();
  const nextReadOnly = shouldBeReadOnly();

  if (state === lastConnectionState && nextReadOnly === readOnly) {
    return;
  }

  lastConnectionState = state;
  readOnly = nextReadOnly;
  document.body.toggleAttribute(OFFLINE_MARKER, readOnly);

  document.querySelectorAll(LOCK_SELECTOR).forEach((region) => {
    syncRegion(region, readOnly);
  });

  document.querySelectorAll(NOTICE_SELECTOR).forEach((notice) => {
    syncNotice(notice, state);
  });

  window.dispatchEvent(
    new CustomEvent('hamster:offline-read-only', {
      detail: { readOnly, connectionState: state },
    }),
  );
}

function rootHasLiveViewError(root) {
  return root && ERROR_CLASSES.some((className) => root.classList.contains(className));
}

function refreshReadOnly() {
  syncDom();
}

function setLiveViewStatus(status) {
  if (!['connecting', 'unavailable', 'connected', 'failed'].includes(status)) {
    return;
  }

  // A deliberate disconnect after the retry budget is exhausted must not
  // replace the terminal failure state with the ordinary disconnect state.
  if (liveViewStatus === 'failed' && status === 'unavailable') {
    return;
  }

  liveViewStatus = status;
  refreshReadOnly();
}

function signalSuccessfulJoin() {
  const event = new CustomEvent('hamster:liveview-joined', { cancelable: true });
  window.dispatchEvent(event);

  if (!event.defaultPrevented) {
    setLiveViewStatus('connected');
  }
}

export const OfflineReadOnly = {
  mounted() {
    signalSuccessfulJoin();
  },

  disconnected() {
    setLiveViewStatus('unavailable');
  },

  reconnected() {
    signalSuccessfulJoin();
  },
};

export function preserveOfflineLock(_from, to) {
  if (to.matches?.(LOCK_SELECTOR)) {
    to.toggleAttribute('inert', readOnly);
  }
}

export function lockAddedOfflineRegion(node) {
  syncNode(node, connectionState());
}

export function initOfflineReadOnly() {
  if (initialized) {
    return;
  }

  initialized = true;
  const liveViewRoot = document.querySelector('[data-phx-main]');
  liveViewPage = Boolean(liveViewRoot);
  liveViewStatus = liveViewPage ? 'connecting' : 'connected';
  window.addEventListener('offline', refreshReadOnly);
  window.addEventListener('online', refreshReadOnly);
  window.addEventListener('hamster:connection-state', (event) => {
    setLiveViewStatus(event.detail?.state);
  });

  const observer = new MutationObserver((records) => {
    const rootFailedToJoin = records.some(
      (record) => record.target === liveViewRoot && record.attributeName === 'class',
    );

    if (rootFailedToJoin && rootHasLiveViewError(liveViewRoot) && liveViewStatus === 'connecting') {
      liveViewStatus = 'unavailable';
    }

    records.forEach((record) => {
      record.addedNodes.forEach((node) => syncNode(node, connectionState()));

      const notice = record.target.matches?.(NOTICE_SELECTOR)
        ? record.target
        : record.target.closest?.(NOTICE_SELECTOR);

      if (notice) {
        syncNotice(notice, connectionState());
      }
    });

    refreshReadOnly();
  });

  observer.observe(document.body, {
    attributes: true,
    attributeFilter: ['hidden', 'data-connection-message', 'data-connection-state'],
    childList: true,
    subtree: true,
  });

  if (liveViewRoot) {
    observer.observe(liveViewRoot, {
      attributes: true,
      attributeFilter: ['class'],
    });
  }

  if (liveViewPage && rootHasLiveViewError(liveViewRoot) && liveViewStatus === 'connecting') {
    liveViewStatus = 'unavailable';
  }

  refreshReadOnly();
}
