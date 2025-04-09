import flatpickr from 'flatpickr';
import { _ } from 'flatpickr/dist/l10n/ru.js';

function calculateDaysBetween(startDate, endDate) {
  const diffTime = endDate - startDate;
  return Math.round(diffTime / (1000 * 60 * 60 * 24));
}

let DayRangeSelect = {
  mounted() {
    this.initialState();

    // known trip dates, show flatpickr
    if (this.el.dataset.startDate) {
      let flatpickr_element = this.el.querySelector('.day-range-flatpickr');

      let tripStartDate = new Date(this.el.dataset.startDate);
      let defaultStartDate = new Date(tripStartDate);
      let defaultEndDate = new Date(tripStartDate);
      let defaultDate = null;

      if (this.el.dataset.selectionStart && this.el.dataset.selectionEnd) {
        defaultStartDate.setDate(
          tripStartDate.getDate() + parseInt(this.el.dataset.selectionStart),
        );
        defaultEndDate.setDate(
          tripStartDate.getDate() + parseInt(this.el.dataset.selectionEnd),
        );

        // use these dates as preselected in flatpickr
        // we need to remove the time part of the date for flatpickr to work correctly
        defaultDate = [
          defaultStartDate.toISOString().split('T')[0],
          defaultEndDate.toISOString().split('T')[0],
        ];
      }

      console.log(this.el.dataset.userLocale);

      this.flatpickr = flatpickr(flatpickr_element, {
        mode: 'range',
        dateFormat: 'Y-m-d',
        inline: true,
        minDate: this.el.dataset.startDate,
        maxDate: this.el.dataset.endDate,
        defaultDate: defaultDate,
        locale: this.el.dataset.userLocale,
        onChange: (selectedDates, _dateStr, _instance) => {
          if (selectedDates.length === 2) {
            selectedDates.sort((a, b) => a - b);
            let startDate = selectedDates[0];
            let endDate = selectedDates[1];

            this.el.dataset.selectionStart = calculateDaysBetween(
              tripStartDate,
              startDate,
            );
            this.el.dataset.selectionEnd = calculateDaysBetween(
              tripStartDate,
              endDate,
            );

            this.submitSelectedDays(
              this.el.dataset.selectionStart,
              this.el.dataset.selectionEnd,
            );

            this.closeDropdown();
          }
        },
      });
    }

    // unknown trip dates, show our days range selector
    if (!this.el.dataset.startDate) {
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

      this.handleEvent('closeDropdown', () => {
        this.closeDropdown();
      });
    }
    this.handleOutsideClick = (e) => {
      if (!this.el.contains(e.target)) {
        this.closeDropdown();
      }
    };

    document.addEventListener('click', this.handleOutsideClick);
  },

  destroyed() {
    document.removeEventListener('click', this.handleOutsideClick);
    if (this.flatpickr) {
      this.flatpickr.destroy();
    }
  },

  submitSelectedDays(startDay, endDay) {
    this.pushEventTo(
      this.el.closest('.day-range-select-live-component'),
      'day_range_selected',
      { start_day: startDay, end_day: endDay },
    );
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

      this.submitSelectedDays(
        dropdown.dataset.selectionStart,
        dropdown.dataset.selectionEnd,
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
    item.classList.remove('dark:bg-blue-800');
    item.classList.remove('text-white');
  },

  selectDay(item) {
    item.classList.add('bg-blue-500');
    item.classList.add('dark:bg-blue-800');
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
