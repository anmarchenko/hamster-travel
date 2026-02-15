let MoneyInput = {
  mounted() {
    // pick user locale or fall back
    const locale = this.el.dataset.userLocale || 'en';
    const parts = new Intl.NumberFormat(locale).formatToParts(1.1);
    const decSep = parts.find((part) => part.type === 'decimal')?.value || '.';
    const altDecSep = decSep === ',' ? '.' : ',';

    this.el.addEventListener('input', (e) => {
      // Accept both "," and "." as decimal separators and keep only one decimal separator.
      let raw = this.el.value.replace(/[^\d.,]/g, '').replaceAll(altDecSep, decSep);
      const firstDecimal = raw.indexOf(decSep);
      if (firstDecimal !== -1) {
        raw =
          raw.slice(0, firstDecimal + 1) +
          raw.slice(firstDecimal + 1).replaceAll(decSep, '');
      }

      // Let users fully clear the field.
      if (raw === '') {
        this.el.value = '';
        return;
      }

      // Keep normalized editable value without grouping separators.
      this.el.value = raw.startsWith(decSep) ? `0${raw}` : raw;
    });
  },
};

export default { MoneyInput };
