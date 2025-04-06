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
    this.el.querySelectorAll('.day-item').forEach((item) => {
      item.addEventListener('click', (e) => {
        this.handleDaySelection(item.dataset.day);
      });
    });

    this.initialState();

    this.handleEvent('closeDropdown', () => {
      this.closeDropdown();
    });

    this.handleOutsideClick = (e) => {
      if (!this.el.contains(e.target)) {
        this.closeDropdown();
      }
    };

    document.addEventListener('click', this.handleOutsideClick);
  },

  destroyed() {
    document.removeEventListener('click', this.handleOutsideClick);
  },

  handleDaySelection(day) {
    // find here the dropdown element
    const dropdown = this.el.closest('.day-range-select-dropdown');
    const dayNumber = parseInt(day);

    console.log(
      'dropdown.dataset.selectionStep',
      dropdown.dataset.selectionStep,
    );

    if (dropdown.dataset.selectionStep === 'start') {
      dropdown.dataset.selectionStart = dayNumber;
      dropdown.dataset.selectionEnd = null;
      dropdown.dataset.selectionStep = 'end';
    } else {
      dropdown.dataset.selectionEnd = dayNumber;
      dropdown.dataset.selectionStep = 'start';

      this.pushEventTo(
        this.el.closest('.day-range-select-live-component'),
        'day_range_selected',
        {
          start_day: dropdown.dataset.selectionStart,
          end_day: dropdown.dataset.selectionEnd,
        },
      );
    }

    this.updateSelection(
      dropdown.dataset.selectionStart,
      dropdown.dataset.selectionEnd,
    );
  },

  updateSelection(selectionStart, selectionEnd) {
    this.el.querySelectorAll('.day-item').forEach((item) => {
      let dayNumber = parseInt(item.dataset.day);
      if (
        (selectionStart &&
          selectionEnd &&
          dayNumber >= selectionStart &&
          dayNumber <= selectionEnd) ||
        (selectionStart && dayNumber == selectionStart)
      ) {
        item.querySelector('input').checked = true;
      } else {
        item.querySelector('input').checked = false;
      }
    });
  },

  closeDropdown() {
    liveSocket.execJS(this.el, this.el.getAttribute('data-close-dropdown'));

    this.initialState();
  },

  initialState() {
    this.el.dataset.selectionStart = this.el.dataset.selectionStartInit;
    this.el.dataset.selectionEnd = this.el.dataset.selectionEndInit;
    this.el.dataset.selectionStep = 'start';

    this.updateSelection(
      this.el.dataset.selectionStart,
      this.el.dataset.selectionEnd,
    );
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
