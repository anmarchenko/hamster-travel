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
        item.classList.add('bg-blue-500');
        item.classList.add('text-white');
      } else {
        item.classList.remove('bg-blue-500');
        item.classList.remove('text-white');
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
