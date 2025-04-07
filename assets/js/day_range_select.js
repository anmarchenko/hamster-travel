let DayRangeSelect = {
  mounted() {
    this.el.querySelectorAll('.day-item').forEach((item) => {
      item.addEventListener('click', (e) => {
        let dropdown = item.closest('.day-range-select-dropdown');
        if (
          item.hasAttribute('disabled') &&
          dropdown.dataset.selectionStep == 'end'
        ) {
          return;
        }
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
    let dropdown = this.el.closest('.day-range-select-dropdown');
    let dayNumber = parseInt(day);

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

  disableDay(item) {
    item.classList.add('opacity-70');
    item.setAttribute('disabled', 'true');
  },

  enableDay(item) {
    item.classList.remove('opacity-70');
    item.removeAttribute('disabled');
  },

  unselectDay(item) {
    item.classList.remove('bg-blue-500');
    item.classList.remove('text-white');
  },

  selectDay(item) {
    item.classList.add('bg-blue-500');
    item.classList.add('text-white');
  },

  updateSelection(selectionStart, selectionEnd) {
    this.el.querySelectorAll('.day-item').forEach((item) => {
      let dayNumber = parseInt(item.dataset.day);
      if (selectionStart && dayNumber < selectionStart) {
        this.disableDay(item);
        this.unselectDay(item);
      } else if (
        (selectionStart &&
          selectionEnd &&
          dayNumber >= selectionStart &&
          dayNumber <= selectionEnd) ||
        (selectionStart && dayNumber == selectionStart)
      ) {
        this.selectDay(item);
        this.enableDay(item);
      } else {
        this.unselectDay(item);
        this.enableDay(item);
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

export default { DayRangeSelect };
