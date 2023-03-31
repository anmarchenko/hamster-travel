const colors = require('tailwindcss/colors');
const plugin = require('tailwindcss/plugin');

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
        success: colors.green,
        danger: colors.red,
        warning: colors.yellow,
        info: colors.sky,

        // Options: slate, gray, zinc, neutral, stone
        gray: colors.gray,
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    plugin(({ addVariant }) =>
      addVariant('phx-no-feedback', [
        '.phx-no-feedback&',
        '.phx-no-feedback &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-click-loading', [
        '.phx-click-loading&',
        '.phx-click-loading &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-submit-loading', [
        '.phx-submit-loading&',
        '.phx-submit-loading &',
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-change-loading', [
        '.phx-change-loading&',
        '.phx-change-loading &',
      ]),
    ),
  ],
};
