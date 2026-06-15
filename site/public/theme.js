// Wires up the header theme toggle button.
// The first-paint <script> in each <head> is inlined separately so it runs
// before <body> renders and prevents flash-of-wrong-theme.
(function () {
  const button = document.querySelector('button.theme-toggle');
  if (!button) return;

  function currentTheme() {
    return document.documentElement.getAttribute('data-theme') || 'dark';
  }

  function syncLabel() {
    const t = currentTheme();
    const next = t === 'dark' ? 'light' : 'dark';
    button.setAttribute('aria-label', `Switch to ${next} theme`);
    button.textContent = t === 'dark' ? '☀' : '☾';
  }

  button.addEventListener('click', () => {
    const next = currentTheme() === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    try { localStorage.setItem('theme', next); } catch (_) {}
    syncLabel();
  });

  syncLabel();
})();
