const colors = require('tailwindcss/colors');
// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex',
    '../deps/petal_components/**/*.*ex',
  ],
  theme: {
    extend: {
      colors: {
        primary: colors.violet,
        secondary: colors.blue,
      },
    },
  },
  plugins: [require('@tailwindcss/forms')],
};
