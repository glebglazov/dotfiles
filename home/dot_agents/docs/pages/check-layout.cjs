const path = require('node:path');
const { chromium } = require('playwright');

const WIDTHS = [390, 1280];
const MIN_SVG_TEXT_PX = 11;
const MIN_TEXT_COLUMN_PX = 64;
const SCHEMES = ['light', 'dark'];

function findProblems({ minSvgTextPx, minTextColumnPx, checkContrast }) {
  const problems = [];
  const viewport = document.documentElement.clientWidth;
  const describe = (el) => {
    const parts = [];
    for (let e = el; e && e !== document.body && parts.length < 4; e = e.parentElement) {
      const id = e.id ? `#${e.id}` : '';
      const cls = typeof e.className === 'string' && e.className.trim()
        ? '.' + e.className.trim().split(/\s+/).slice(0, 2).join('.') : '';
      parts.unshift(e.tagName.toLowerCase() + id + cls);
    }
    const section = el.closest('section, article');
    const heading = section && section.querySelector('h1, h2, h3');
    return `${heading ? `[${heading.textContent.trim().slice(0, 60)}] ` : ''}${parts.join(' > ')}`;
  };
  const scrollsSideways = (el) => {
    for (let e = el.parentElement; e && e !== document.body; e = e.parentElement) {
      const x = getComputedStyle(e).overflowX;
      if (x === 'auto' || x === 'scroll') return true;
    }
    return false;
  };

  if (document.documentElement.scrollWidth > viewport + 1) {
    problems.push(`page is ${document.documentElement.scrollWidth}px wide, wider than the ${viewport}px viewport`);
    for (const el of document.body.querySelectorAll('*')) {
      const r = el.getBoundingClientRect();
      if (r.width && r.right > viewport + 1 && !scrollsSideways(el) &&
          !(el.parentElement && el.parentElement.getBoundingClientRect().right > viewport + 1)) {
        problems.push(`  overflows by ${Math.round(r.right - viewport)}px: ${describe(el)}`);
      }
    }
  }

  for (const el of document.body.querySelectorAll('*')) {
    if (el.closest('svg')) continue;
    const ownText = [...el.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent).join('').trim();
    const text = el.tagName === 'CODE' || el.tagName === 'KBD' ? el.textContent.trim() : ownText;
    if (text.length < 8) continue;
    const r = el.getBoundingClientRect();
    const lineHeight = parseFloat(getComputedStyle(el).lineHeight) || parseFloat(getComputedStyle(el).fontSize) * 1.4;
    if (r.width > 0 && r.width < minTextColumnPx && r.height > lineHeight * 2.5) {
      problems.push(`text squeezed into a ${Math.round(r.width)}px column, ${Math.round(r.height)}px tall: ${describe(el)} "${text.slice(0, 40)}"`);
    }
  }

  for (const svg of document.querySelectorAll('svg')) {
    const sizes = [];
    for (const t of svg.querySelectorAll('text')) {
      const ctm = t.getScreenCTM();
      if (!ctm || !t.getBBox().width) continue;
      sizes.push(parseFloat(getComputedStyle(t).fontSize) * Math.hypot(ctm.a, ctm.b));
    }
    const small = sizes.filter((s) => s < minSvgTextPx);
    if (small.length) {
      problems.push(`SVG text renders at ${Math.min(...small).toFixed(1)}px (${small.length} of ${sizes.length} labels under ${minSvgTextPx}px): ${describe(svg)}`);
    }
  }
  if (checkContrast) problems.push(...lowContrast(describe));
  return problems;

  // WCAG 2.2 contrast of each text element against the background it is drawn on. The canvas turns any CSS colour
  // (oklch, color-mix…) into sRGB, and backgrounds with alpha are blended over the ones below them.
  function lowContrast(describe) {
    const ctx = document.createElement('canvas').getContext('2d', { willReadFrequently: true });
    const rgba = (css) => {
      ctx.clearRect(0, 0, 1, 1);
      ctx.fillStyle = '#000';
      ctx.fillStyle = css;
      ctx.fillRect(0, 0, 1, 1);
      const [r, g, b, a] = ctx.getImageData(0, 0, 1, 1).data;
      return [r, g, b, a / 255];
    };
    const over = (top, below) => top.slice(0, 3).map((c, i) => c * top[3] + below[i] * (1 - top[3])).concat(1);
    const backdrop = (el) => {
      const layers = [];
      for (let e = el; e; e = e.parentElement) {
        const c = rgba(getComputedStyle(e).backgroundColor);
        if (c[3] > 0) layers.push(c);
        if (c[3] >= 1) break;
      }
      return layers.reduceRight((below, top) => over(top, below), [255, 255, 255, 1]);
    };
    const luminance = (c) => {
      const [r, g, b] = c.slice(0, 3).map((v) => { v /= 255; return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; });
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    };
    const groups = new Map();
    for (const el of document.body.querySelectorAll('*')) {
      // A mockup shows the product's own colours; their contrast is the product's, not the page's.
      if (el.closest('svg') || el.closest('[aria-hidden="true"]') || el.closest('[data-mockup]')) continue;
      const text = [...el.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent).join('').trim();
      if (!text) continue;
      const style = getComputedStyle(el);
      const r = el.getBoundingClientRect();
      if (!r.width || !r.height || style.visibility === 'hidden' || parseFloat(style.opacity) === 0) continue;
      const bg = backdrop(el);
      const fg = over(rgba(style.color), bg);
      const [hi, lo] = [luminance(fg), luminance(bg)].sort((a, b) => b - a);
      const ratio = (hi + 0.05) / (lo + 0.05);
      const size = parseFloat(style.fontSize);
      const large = size >= 24 || (size >= 18.66 && parseInt(style.fontWeight, 10) >= 700);
      const need = large ? 3 : 4.5;
      if (ratio >= need) continue;
      const key = `${fg.slice(0, 3).map(Math.round)} on ${bg.slice(0, 3).map(Math.round)}`;
      const group = groups.get(key) || { ratio, need, count: 0, example: `${describe(el)} "${text.slice(0, 40)}"` };
      group.count += 1;
      groups.set(key, group);
    }
    return [...groups].map(([key, g]) =>
      `text contrast ${g.ratio.toFixed(1)}:1, needs ${g.need}:1 (rgb ${key}), ${g.count} element(s), first: ${g.example}`);
  }
}

// Loads the page and waits until it is drawn as a reader sees it: the CDN Tailwind runtime has written its styles,
// the fonts are in, and two frames have passed. Answers an error message when the page cannot get there, so a slow
// network is reported as "cannot check" and never as a layout problem.
async function render(page, file) {
  try {
    await page.goto('file://' + path.resolve(file), { waitUntil: 'load', timeout: 60000 });
    if (await page.$('script[src*="tailwindcss"]')) {
      await page.waitForFunction(() => [...document.querySelectorAll('style')].some((s) => /tailwindcss v\d/.test(s.textContent)),
        null, { timeout: 30000 }).catch(() => { throw new Error('the Tailwind runtime did not write its styles within 30 s'); });
    }
    await page.evaluate(() => document.fonts.ready.then(() => new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done)))));
    return null;
  } catch (error) {
    return error.message.split('\n')[0];
  }
}

(async () => {
  const browser = await chromium.launch();
  let failed = false;
  let unchecked = false;
  try {
    for (const file of process.argv.slice(2)) {
      for (const width of WIDTHS) for (const scheme of SCHEMES) {
        const page = await browser.newPage({ viewport: { width, height: 900 }, colorScheme: scheme });
        const error = await render(page, file);
        if (error) {
          unchecked = true;
          console.log(`CANNOT CHECK ${file} at ${width}px, ${scheme}: ${error}`);
          await page.close();
          continue;
        }
        // Contrast does not depend on the width, so it is checked once per scheme, at the first width.
        const problems = await page.evaluate(findProblems, { minSvgTextPx: MIN_SVG_TEXT_PX, minTextColumnPx: MIN_TEXT_COLUMN_PX, checkContrast: width === WIDTHS[0] });
        await page.close();
        if (problems.length) {
          failed = true;
          console.log(`FAIL ${file} at ${width}px, ${scheme}`);
          for (const p of problems) console.log(`  ${p}`);
        } else {
          console.log(`ok   ${file} at ${width}px, ${scheme}`);
        }
      }
    }
  } finally {
    await browser.close();
  }
  // 1: a layout problem to fix. 2: some render could not be checked; run the check again.
  process.exit(failed ? 1 : unchecked ? 2 : 0);
})();
