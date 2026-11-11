// Loaded by index.html and by every slide file. One copy of the settings
// means a slide opened alone (in a browser or in Lavish) looks the same as
// it does in the full deck.

const REVEAL_CONFIG = {
  width: 1920,
  height: 1080,
  margin: 0,
  center: false,
  hash: true,
  plugins: [RevealNotes],
};

const fetchText = async url => (await fetch(url, { cache: 'no-store' })).text();

(async () => {
  let slidesEl = document.querySelector('.reveal .slides');

  if (slidesEl) {
    // index.html: slides.txt holds the order, one file per line.
    // Copy each slide file's <style> blocks and <section> in that order.
    // DOMParser does not run scripts, so deck.js inside a slide file stays inert here.
    const files = (await fetchText('slides.txt'))
      .split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('#'));
    for (const url of files) {
      const doc = new DOMParser().parseFromString(await fetchText(url), 'text/html');
      doc.querySelectorAll('head style').forEach(s => document.head.appendChild(document.importNode(s, true)));
      slidesEl.appendChild(document.importNode(doc.querySelector('body > section'), true));
    }
  } else {
    // A slide file opened alone: wrap its <section> in a one-slide deck.
    // Only the sections move, so anything a host page injects into <body> stays put.
    const reveal = document.createElement('div');
    reveal.className = 'reveal';
    slidesEl = document.createElement('div');
    slidesEl.className = 'slides';
    reveal.appendChild(slidesEl);
    document.querySelectorAll('body > section').forEach(s => slidesEl.appendChild(s));
    document.body.prepend(reveal);
  }

  Reveal.initialize(REVEAL_CONFIG);
})();
