// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html';

// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from '../vendor/topbar';

// alpinejs for interactivity and persist plugin for local storage
import Alpine from 'alpinejs';
import persist from '@alpinejs/persist';
import collapse from '@alpinejs/collapse';

// live_select UI component
import live_select from 'live_select';

// hamster travel components
import DayRangeSelect from './day_range_select';
import DateRangePicker from './date_range_picker';
import MoneyInput from './money_input';
import TransferDragDrop from './transfer_drag_drop';
import ActivityDragDrop from './activity_drag_drop';
import PackingDragDrop from './packing_drag_drop';
import FormattedTextArea from './formatted_text_area';
import UserMap from './user_map';

Alpine.plugin(persist);
Alpine.plugin(collapse);
window.Alpine = Alpine;

Alpine.start();

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

let hooks = {
  ...live_select,
  ...DayRangeSelect,
  ...DateRangePicker,
  ...MoneyInput,
  ...TransferDragDrop,
  ...ActivityDragDrop,
  ...PackingDragDrop,
  ...FormattedTextArea,
  ...UserMap,
};

let liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  hooks: hooks,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    },
  },
});

function socketDiagnosticsEnabled() {
  if (window.location.hostname === 'hamster-travel.fly.dev') {
    return true;
  }

  try {
    return window.localStorage.getItem('hamster_socket_diagnostics') === '1';
  } catch (_error) {
    return false;
  }
}

function describeElement(element) {
  if (!element || !element.tagName) {
    return undefined;
  }

  let description = element.tagName.toLowerCase();

  if (element.id) {
    description += `#${element.id}`;
  }

  if (element.getAttribute('phx-click')) {
    description += `[phx-click="${element.getAttribute('phx-click')}"]`;
  }

  if (element.getAttribute('data-phx-link')) {
    description += `[data-phx-link]`;
  }

  return description;
}

function sanitizedHref(element) {
  let href = element?.getAttribute?.('href');

  if (!href) {
    return undefined;
  }

  try {
    let url = new URL(href, window.location.origin);
    return `${url.pathname}${url.hash}`;
  } catch (_error) {
    return href.split('?')[0];
  }
}

function initSocketDiagnostics(liveSocket) {
  if (!socketDiagnosticsEnabled()) {
    return;
  }

  let startedAt = performance.now();
  let socket = liveSocket.socket;

  let socketState = () => ({
    connected: liveSocket.isConnected(),
    state: socket.connectionState?.(),
    protocol: socket.protocol?.(),
    endpoint: socket.endPoint,
  });

  let log = (event, metadata = {}) => {
    console.info('[hamster:socket]', {
      event: event,
      timestamp: new Date().toISOString(),
      elapsedMs: Math.round(performance.now() - startedAt),
      ...socketState(),
      ...metadata,
    });
  };

  socket.onOpen(() => log('socket:open'));

  socket.onClose((event) =>
    log('socket:close', {
      code: event?.code,
      reason: event?.reason,
      wasClean: event?.wasClean,
    }),
  );

  socket.onError((event) =>
    log('socket:error', {
      message: event?.message,
      type: event?.type,
    }),
  );

  ['phx:connected', 'phx:disconnected', 'phx:error'].forEach((eventName) => {
    window.addEventListener(eventName, (event) =>
      log(eventName, {
        target: describeElement(event.target),
      }),
    );
  });

  document.addEventListener(
    'click',
    (event) => {
      if (liveSocket.isConnected()) {
        return;
      }

      let element = event.target?.closest?.(
        '[phx-click], [data-phx-link], button, a, input[type="submit"]',
      );

      if (!element) {
        return;
      }

      log('click:while-disconnected', {
        target: describeElement(element),
        href: sanitizedHref(element),
      });
    },
    true,
  );

  log('diagnostics:enabled');
}

// Show progress bar on live navigation and form submits after 200ms of waiting
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });

let topBarScheduled = undefined;
window.addEventListener('phx:page-loading-start', () => {
  if (!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 200);
  }
});

window.addEventListener('phx:page-loading-stop', () => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

initSocketDiagnostics(liveSocket);

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
