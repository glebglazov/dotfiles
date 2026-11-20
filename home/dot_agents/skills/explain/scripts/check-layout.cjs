const path = require('node:path');
const { chromium } = require('playwright');

const WIDTHS = [390, 1280];
const MIN_SVG_TEXT_PX = 11;
const MIN_TEXT_COLUMN_PX = 64;

function findProblems({ minSvgTextPx, minTextColumnPx }) {
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
  return problems;
}

(async () => {
  const browser = await chromium.launch();
  let failed = false;
  try {
    for (const file of process.argv.slice(2)) {
      for (const width of WIDTHS) {
        const page = await browser.newPage({ viewport: { width, height: 900 } });
        try {
          await page.goto('file://' + path.resolve(file), { waitUntil: 'networkidle' });
        } catch (error) {
          console.error(`cannot load ${file}: ${error.message.split('\n')[0]}`);
          process.exit(2);
        }
        await page.waitForTimeout(1000);
        const problems = await page.evaluate(findProblems, { minSvgTextPx: MIN_SVG_TEXT_PX, minTextColumnPx: MIN_TEXT_COLUMN_PX });
        await page.close();
        if (problems.length) {
          failed = true;
          console.log(`FAIL ${file} at ${width}px`);
          for (const p of problems) console.log(`  ${p}`);
        } else {
          console.log(`ok   ${file} at ${width}px`);
        }
      }
    }
  } finally {
    await browser.close();
  }
  process.exit(failed ? 1 : 0);
})();
