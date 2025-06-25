let MoneyInput = {
  mounted() {
    // pick user locale or fall back
    const locale = this.el.dataset.userLocale || 'en';
    const fmtr = new Intl.NumberFormat(locale);
    const parts = fmtr.formatToParts(1.1);
    const decSep = parts.find((part) => part.type === 'decimal')?.value || '.';

    // Format initial value if present
    const initialValue = this.el.value;
    if (initialValue && !isNaN(parseFloat(initialValue))) {
      const numValue = parseFloat(initialValue);
      this.el.value = fmtr.format(numValue);
    }

    this.el.addEventListener('input', (e) => {
      const start = this.el.selectionStart;

      // Allow only digits & one decimal separator
      let raw = this.el.value
        .replace(new RegExp(`[^\\d${decSep}]`, 'g'), '')
        .replace(new RegExp(`${decSep}(?=.*${decSep})`, 'g'), '');

      // Split int/frac to preserve user-typed decimals
      const [intPart, fracPart] = raw.split(decSep);
      const formattedInt = fmtr.format(intPart || '0');

      this.el.value =
        fracPart === undefined
          ? formattedInt
          : `${formattedInt}${decSep}${fracPart}`;

      // restore caret so typing feels natural
      const diff = this.el.value.length - raw.length;
      this.el.setSelectionRange(start + diff, start + diff);
    });
  },
};

export default { MoneyInput };
