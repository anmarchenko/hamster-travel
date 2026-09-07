const storageKey = 'theme';
const darkModePreference = window.matchMedia('(prefers-color-scheme: dark)');

const getStoredTheme = () => {
  try {
    return window.localStorage.getItem(storageKey);
  } catch (_error) {
    return null;
  }
};

const preferredTheme = () => {
  const storedTheme = getStoredTheme();

  if (storedTheme === 'dark' || storedTheme === 'light') {
    return storedTheme;
  }

  return darkModePreference.matches ? 'dark' : 'light';
};

const syncThemeControls = (theme) => {
  const darkMode = theme === 'dark';

  document.querySelectorAll('[data-theme-toggle]').forEach((button) => {
    button.setAttribute('aria-pressed', darkMode.toString());

    const label = darkMode
      ? button.dataset.lightLabel
      : button.dataset.darkLabel;

    if (label) {
      button.setAttribute('aria-label', label);
      button.setAttribute('title', label);
    }
  });
};

const applyTheme = (theme, persist = false) => {
  const darkMode = theme === 'dark';

  document.documentElement.classList.toggle('dark', darkMode);
  document.documentElement.style.colorScheme = theme;
  syncThemeControls(theme);

  if (persist) {
    try {
      window.localStorage.setItem(storageKey, theme);
    } catch (_error) {
      // The selected theme still applies when storage is unavailable.
    }
  }
};

export const initTheme = () => {
  applyTheme(preferredTheme());

  document.addEventListener('click', (event) => {
    const button = event.target.closest('[data-theme-toggle]');

    if (!button) {
      return;
    }

    const nextTheme = document.documentElement.classList.contains('dark')
      ? 'light'
      : 'dark';

    applyTheme(nextTheme, true);
  });

  darkModePreference.addEventListener('change', (event) => {
    if (!getStoredTheme()) {
      applyTheme(event.matches ? 'dark' : 'light');
    }
  });

  window.addEventListener('phx:page-loading-stop', () => {
    syncThemeControls(
      document.documentElement.classList.contains('dark') ? 'dark' : 'light',
    );
  });
};
