const LOCK_SELECTOR = '[data-offline-lock]';
const OFFLINE_MARKER = 'data-offline-readonly';

let initialized = false;
let liveViewConnected = true;
let readOnly = false;

function lockRegion(region, locked) {
  if (region instanceof HTMLElement) {
    region.inert = locked;
  }
}

function lockAllRegions(locked) {
  document.querySelectorAll(LOCK_SELECTOR).forEach((region) => {
    lockRegion(region, locked);
  });
}

function shouldBeReadOnly() {
  return navigator.onLine === false || liveViewConnected === false;
}

function setReadOnly(nextReadOnly) {
  readOnly = nextReadOnly;
  document.body.toggleAttribute(OFFLINE_MARKER, readOnly);
  lockAllRegions(readOnly);

  window.dispatchEvent(
    new CustomEvent('hamster:offline-read-only', {
      detail: { readOnly },
    }),
  );
}

function refreshReadOnly() {
  setReadOnly(shouldBeReadOnly());
}

export const OfflineReadOnly = {
  mounted() {
    liveViewConnected = true;
    refreshReadOnly();
  },

  disconnected() {
    liveViewConnected = false;
    refreshReadOnly();
  },

  reconnected() {
    liveViewConnected = true;
    refreshReadOnly();
  },
};

export function preserveOfflineLock(_from, to) {
  if (readOnly && to.matches?.(LOCK_SELECTOR)) {
    to.setAttribute('inert', '');
  }
}

export function lockAddedOfflineRegion(node) {
  if (!readOnly || !(node instanceof Element)) {
    return;
  }

  if (node.matches(LOCK_SELECTOR)) {
    lockRegion(node, true);
  }

  node.querySelectorAll(LOCK_SELECTOR).forEach((region) => {
    lockRegion(region, true);
  });
}

export function initOfflineReadOnly() {
  if (initialized) {
    return;
  }

  initialized = true;
  window.addEventListener('offline', refreshReadOnly);
  window.addEventListener('online', refreshReadOnly);
  refreshReadOnly();
}
