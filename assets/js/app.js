// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html';
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from '../vendor/topbar';

// alpinejs for interactivity and persist plugin for local storage
import Alpine from 'alpinejs';
import persist from '@alpinejs/persist';

// live_select UI component
import live_select from 'live_select';

Alpine.plugin(persist);

window.Alpine = Alpine;
Alpine.start();

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

let DayRangeSelect = {
  mounted() {
    const dropdown = this.el.querySelector('#day-range-dropdown');
    console.log(this.el);
    console.log(dropdown);

    const trigger = this.el.querySelector('#day-range-trigger');
    console.log(trigger);

    trigger.addEventListener('click', (e) => {
      e.preventDefault();
      dropdown.classList.toggle('hidden');
    });

    // Close dropdown when clicking outside
    document.addEventListener('click', (e) => {
      if (!this.el.contains(e.target)) {
        dropdown.classList.add('hidden');
      }
    });

    // Close dropdown when day is selected (for end selection) - ????????
    dropdown.addEventListener('click', (e) => {
      const dayItem = e.target.closest('.day-item');
      if (
        dayItem &&
        this.el
          .querySelector('#selection-step-badge')
          .textContent.includes('Select end day')
      ) {
        // Add a small delay to allow the server to process the selection
        setTimeout(() => {
          dropdown.classList.add('hidden');
        }, 100);
      }
    });
  },
};

let hooks = {
  ...live_select,
  DayRangeSelect,
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
