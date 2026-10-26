// Rendert die Logo-SVGs als PNG (für Vorschauen, Social-Preview und Store-Grafiken).
// Aufruf: node tools/logo/render_png.js   (braucht Playwright mit Chromium)
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const jobs = [
  ['docs/logo/kraxl-icon.svg', 'docs/logo/kraxl-icon-512.png', 512, 512, 'transparent'],
  ['docs/logo/kraxl-logo.svg', 'docs/logo/kraxl-logo.png', null, 420, '#FFFFFF'],
  ['docs/logo/kraxl-logo-dark.svg', 'docs/logo/kraxl-logo-dark.png', null, 420, '#0D1117'],
];

(async () => {
  const browser = await chromium.launch();
  for (const [src, out, w, h, bg] of jobs) {
    const svg = fs.readFileSync(path.join(root, src), 'utf8');
    const width = w || Number(/viewBox="0 0 (\d+)/.exec(svg)[1]);
    const page = await browser.newPage({ viewport: { width, height: h } });
    await page.setContent(
      `<html><body style="margin:0;background:${bg}">${svg}</body></html>`);
    await page.screenshot({ path: path.join(root, out), omitBackground: bg === 'transparent' });
    await page.close();
    console.log('geschrieben:', out);
  }
  await browser.close();
})();
