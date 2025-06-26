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
import MoneyInput from './money_input';

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
  ...MoneyInput,
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

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// Load the appropriate Flatpickr theme based on OS color scheme
function loadFlatpickrTheme() {
  const head = document.head;
  const existingLink = document.querySelector(
    'link[rel="stylesheet"][href*="flatpickr"]',
  );
  if (existingLink) {
    head.removeChild(existingLink);
  }

  const themeLink = document.createElement('link');
  themeLink.rel = 'stylesheet';
  themeLink.type = 'text/css';

  if (
    window.matchMedia &&
    window.matchMedia('(prefers-color-scheme: dark)').matches
  ) {
    themeLink.href = 'https://npmcdn.com/flatpickr/dist/themes/dark.css';
  } else {
    themeLink.href = 'https://npmcdn.com/flatpickr/dist/themes/light.css';
  }

  head.appendChild(themeLink);
}

// Initial theme load
loadFlatpickrTheme();

// Listen for changes in the OS color scheme
window
  .matchMedia('(prefers-color-scheme: dark)')
  .addEventListener('change', loadFlatpickrTheme);
