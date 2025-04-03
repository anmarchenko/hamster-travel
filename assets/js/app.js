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

// Define the dayRangeState component once
Alpine.data('dayRangeState', () => ({
  selection_step: 'start',
  start_selection: null,
  end_selection: null,
  isOpen: false,

  init() {
    // Initialize from LiveView's state
    const startInput = this.$el.querySelector(
      'input[type="hidden"][name*="start"]',
    );
    const endInput = this.$el.querySelector(
      'input[type="hidden"][name*="end"]',
    );

    this.start_selection = startInput?.value || null;
    this.end_selection = endInput?.value || null;
    this.selection_step = this.start_selection ? 'end' : 'start';

    // Set up click outside listener using Alpine's magic $watch
    this.$watch('isOpen', () => {
      if (this.isOpen) {
        // Add click outside listener when dropdown opens
        setTimeout(() => {
          document.addEventListener('click', this.handleClickOutside);
        });
      } else {
        // Remove click outside listener when dropdown closes
        document.removeEventListener('click', this.handleClickOutside);
      }
    });
  },

  handleClickOutside(e) {
    if (!this.$el.contains(e.target)) {
      this.isOpen = false;
    }
  },

  toggleDropdown() {
    this.isOpen = !this.isOpen;
  },

  handleDaySelection(day) {
    if (this.selection_step === 'start') {
      this.start_selection = day;
      this.selection_step = 'end';
    } else {
      this.end_selection = day;
      this.selection_step = 'start';

      // Close dropdown after end day selection
      this.isOpen = false;

      // Push event to LiveView only when end day is selected
      this.pushEventToLiveView({
        start_day: this.start_selection,
        end_day: this.end_selection,
      });
    }
  },

  pushEventToLiveView(data) {
    // Use the stored reference to the hook's pushEvent method
    this.$el
      .closest('.day-range-select')
      .__liveview_hook__.pushEventTo(
        this.$el.closest('.day-range-select-live-component'),
        'day_range_selected',
        data,
      );
  },
}));

Alpine.start();

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

let DayRangeSelect = {
  mounted() {
    // Store reference to the hook so we can use it to push events from the
    // Alpine component
    this.el.__liveview_hook__ = this;

    // Initialize Alpine component on the element
    Alpine.initTree(this.el);
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
