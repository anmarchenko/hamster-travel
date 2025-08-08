import flatpickr from "flatpickr";

let DateRangePicker = {
  mounted() {
    const input = this.el.querySelector('input[type="text"]');

    // Get initial values from the data attributes
    const startDate = this.el.dataset.startDate;
    const endDate = this.el.dataset.endDate;

    // Set up default date range if both values exist and are valid
    let defaultDate = null;
    if (startDate && endDate && startDate !== "" && endDate !== "") {
      // Validate date strings before passing to flatpickr
      const startDateObj = new Date(startDate);
      const endDateObj = new Date(endDate);

      if (!isNaN(startDateObj.getTime()) && !isNaN(endDateObj.getTime())) {
        defaultDate = [startDateObj, endDateObj];
      } else {
        console.warn("Invalid date strings from server:", {
          startDate,
          endDate,
        });
      }
    }

    // Initialize flatpickr
    this.flatpickr = flatpickr(input, {
      mode: "range",
      dateFormat: "d.m.Y",
      defaultDate: defaultDate,
      locale: this.el.dataset.userLocale,
      allowInput: false,
      clickOpens: true,
      onChange: (selectedDates, dateStr, instance) => {
        if (selectedDates.length === 2) {
          // Sort dates to ensure start is before end
          selectedDates.sort((a, b) => a - b);

          const startDate = this.flatpickr.formatDate(
            selectedDates[0],
            "Y-m-d",
          );
          const endDate = this.flatpickr.formatDate(selectedDates[1], "Y-m-d");

          // Update hidden inputs
          const startInput = document.querySelector(
            'input[name="trip[start_date]"]',
          );
          const endInput = document.querySelector(
            'input[name="trip[end_date]"]',
          );

          if (startInput) {
            startInput.value = startDate;
            // Trigger change event for LiveView
            startInput.dispatchEvent(new Event("input", { bubbles: true }));
          }

          if (endInput) {
            endInput.value = endDate;
            // Trigger change event for LiveView
            endInput.dispatchEvent(new Event("input", { bubbles: true }));
          }
        } else if (selectedDates.length === 0) {
          // Clear both inputs when range is cleared
          const startInput = document.querySelector(
            'input[name="trip[start_date]"]',
          );
          const endInput = document.querySelector(
            'input[name="trip[end_date]"]',
          );

          if (startInput) {
            startInput.value = "";
            startInput.dispatchEvent(new Event("input", { bubbles: true }));
          }

          if (endInput) {
            endInput.value = "";
            endInput.dispatchEvent(new Event("input", { bubbles: true }));
          }

          input.value = "";
        }
      },
    });
  },

  destroyed() {
    if (this.flatpickr) {
      this.flatpickr.destroy();
    }
  },
};

export default { DateRangePicker };
