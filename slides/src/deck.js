/* Attendo slide deck runtime. No framework, no network.
   Keys: → Space PageDown next · ← PageUp back · Home End · N notes · P presenter window · T timer
   K show every proof mark · D light/dark · O overview · F fullscreen · ? help. Click a dotted number for its source. */
(() => {
  'use strict';
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const deck = $('.deck');
  const slides = $$('.slide', deck);
  const total = slides.length;
  const TITLE = document.body.dataset.deck || document.title;
  const PROOFS = window.PROOFS || {};
  const chan = 'BroadcastChannel' in window ? new BroadcastChannel('attendo-deck-' + TITLE) : null;
  const presenter = new URLSearchParams(location.search).has('presenter');
  let cur = 0, step = 0, t0 = null;

  // ---------- chrome on every slide ----------
  slides.forEach((s, i) => {
    s.querySelectorAll('[data-step]').forEach((el) => el.classList.add('hide'));
    if (s.dataset.bare !== undefined) return;
    const bar = document.createElement('div');
    bar.className = 'bar';
    bar.innerHTML = `<span class="mark">attend<i></i></span><span class="sec"></span><span class="num"></span>`;
    bar.querySelector('.sec').textContent = s.dataset.sec || '';
    bar.querySelector('.num').textContent = `${String(i + 1).padStart(2, '0')} / ${String(total).padStart(2, '0')}`;
    s.prepend(bar);
    const p = document.createElement('div');
    p.className = 'progress';
    p.style.width = `${((i + 1) / total) * 100}%`;
    s.append(p);
  });

  // ---------- diagrams: <svg class="dia" data-seq> sequence diagrams from a tiny text spec ----------
  // Spec (inside <script type="text/plain" class="seq-src">): first line actors separated by |,
  // then one message per line: "0>2 text" (solid), "2->0 text" (dashed reply), "1: note text".
  $$('.seq').forEach((host) => {
    const src = host.querySelector('.seq-src').textContent.trim().split('\n').map((l) => l.trim()).filter(Boolean);
    const actors = src.shift().split('|').map((a) => a.trim());
    const W = +(host.dataset.w || 1400), colW = W / actors.length, rowH = +(host.dataset.row || 50), top = 76;
    const x = (i) => colW * i + colW / 2;
    const H = top + src.length * rowH + 20;
    let svg = `<svg class="dia" viewBox="0 0 ${W} ${H}" role="img">`;
    svg += `<defs><marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse"><path class="head brand" d="M0 0L10 5L0 10z"/></marker></defs>`;
    actors.forEach((a, i) => {
      const bw = Math.min(colW - 24, 260);
      svg += `<line class="life" x1="${x(i)}" y1="${top - 8}" x2="${x(i)}" y2="${H - 6}"/>`;
      svg += `<rect class="box${i === 0 ? ' brand' : ''}" x="${x(i) - bw / 2}" y="0" width="${bw}" height="52" rx="10"/>`;
      svg += `<text x="${x(i)}" y="33" text-anchor="middle" font-weight="600">${a}</text>`;
    });
    src.forEach((l, r) => {
      const y = top + r * rowH + rowH / 2 + 6;
      let m;
      if ((m = l.match(/^(\d+):\s*(.*)$/))) {
        const i = +m[1];
        svg += `<rect class="box warn" x="${x(i) - 150}" y="${y - 24}" width="300" height="36" rx="8"/>`;
        svg += `<text x="${x(i)}" y="${y}" text-anchor="middle" font-size="16">${m[2]}</text>`;
      } else if ((m = l.match(/^(\d+)(-?)>(\d+)\s+(.*)$/))) {
        const a = +m[1], b = +m[3], dash = m[2] === '-';
        const x1 = x(a) + (b > a ? 6 : -6), x2 = x(b) + (b > a ? -6 : 6);
        if (a === b) {
          svg += `<path class="ln brand" d="M${x(a)} ${y - 12} h70 v24 h-64" marker-end="url(#ah)"/>`;
          svg += `<text x="${x(a) + 84}" y="${y + 6}" font-size="17">${m[4]}</text>`;
        } else {
          svg += `<line class="ln brand" x1="${x1}" y1="${y}" x2="${x2}" y2="${y}" ${dash ? 'stroke-dasharray="7 6"' : ''} marker-end="url(#ah)"/>`;
          svg += `<text x="${(x1 + x2) / 2}" y="${y - 10}" text-anchor="middle" font-size="17">${m[4]}</text>`;
        }
      }
    });
    host.insertAdjacentHTML('beforeend', svg + '</svg>');
  });

  // ---------- proof marks ----------
  let pop = null;
  const closePop = () => { pop?.remove(); pop = null; };
  document.addEventListener('click', (e) => {
    const el = e.target.closest('.pf');
    if (!el) { if (!e.target.closest('.pop')) closePop(); return; }
    e.preventDefault();
    closePop();
    const p = PROOFS[el.dataset.p];
    if (!p) return;
    pop = document.createElement('div');
    pop.className = 'pop';
    pop.innerHTML = `<div class="k">${p.k || 'Bằng chứng'}</div><b></b><div class="d"></div>`;
    pop.querySelector('b').textContent = p.t;
    pop.querySelector('.d').textContent = p.d || '';
    if (p.img) pop.insertAdjacentHTML('beforeend', `<img alt="" src="${p.img}">`);
    if (p.href) pop.insertAdjacentHTML('beforeend', `<div style="margin-top:10px"><a target="_blank" rel="noopener" href="${p.href}">Mở nguồn ↗</a></div>`);
    document.body.append(pop);
    const r = el.getBoundingClientRect();
    const left = Math.min(Math.max(16, r.left), innerWidth - pop.offsetWidth - 16);
    const below = r.bottom + 12 + pop.offsetHeight < innerHeight;
    pop.style.left = left + 'px';
    pop.style.top = (below ? r.bottom + 12 : Math.max(16, r.top - 12 - pop.offsetHeight)) + 'px';
  });

  // ---------- navigation ----------
  const fit = () => {
    const s = Math.min(innerWidth / 1600, innerHeight / 900);
    document.documentElement.style.setProperty('--s', s);
  };
  const stepsOf = (i) => Math.max(0, ...$$('[data-step]', slides[i]).map((e) => +e.dataset.step));
  function show(i, st = 0, from = 'local') {
    i = Math.max(0, Math.min(total - 1, i));
    slides[cur].classList.remove('on');
    cur = i; step = Math.max(0, Math.min(stepsOf(i), st));
    slides[cur].classList.add('on');
    $$('[data-step]', slides[cur]).forEach((e) => e.classList.toggle('hide', +e.dataset.step > step));
    if (location.hash !== '#' + (cur + 1)) history.replaceState(null, '', '#' + (cur + 1));
    closePop();
    renderNotes();
    if (from === 'local') chan?.postMessage({ i: cur, st: step });
    if (presenter) renderPresenter();
  }
  const next = () => (step < stepsOf(cur) ? show(cur, step + 1) : show(cur + 1, 0));
  const prev = () => (step > 0 ? show(cur, step - 1) : show(cur - 1, stepsOf(cur - 1)));
  chan && (chan.onmessage = (e) => { if (e.data && 'i' in e.data) show(e.data.i, e.data.st, 'remote'); });

  // ---------- notes ----------
  let notesOn = false;
  const notesText = (i) => slides[i]?.querySelector('.notes')?.innerHTML || '<span class="muted">(Không có ghi chú)</span>';
  function renderNotes() {
    $('.notepanel')?.remove();
    if (!notesOn || presenter) return;
    const n = document.createElement('div');
    n.className = 'notepanel';
    n.innerHTML = `<div class="k">Ghi chú · slide ${cur + 1}</div>${notesText(cur)}`;
    document.body.append(n);
  }

  // ---------- presenter window (?presenter): notes, next slide, timer; synced both ways ----------
  function renderPresenter() {
    let p = $('#presenter');
    if (!p) {
      document.body.style.overflow = 'auto';
      deck.style.display = 'none';
      p = document.createElement('div');
      p.id = 'presenter';
      p.style.cssText = 'padding:28px 36px;font-family:var(--sans);max-width:1100px';
      document.body.append(p);
      setInterval(() => { const c = $('#clock'); if (c) c.textContent = clock(); }, 500);
    }
    const nx = slides[cur + 1];
    p.innerHTML = `<div style="display:flex;gap:24px;align-items:baseline;font-family:var(--mono);color:var(--muted-fg)"><span>Slide ${cur + 1}/${total}${stepsOf(cur) ? ` · bước ${step}/${stepsOf(cur)}` : ''}</span><span id="clock" style="font-size:42px;color:var(--fg);margin-left:auto">${clock()}</span></div>
      <h2 style="font-size:34px;margin:16px 0 8px">${slides[cur].dataset.title || ''}</h2>
      <div style="font-size:22px;line-height:1.6">${notesText(cur)}</div>
      <p class="sm" style="margin-top:28px">Tiếp theo: ${nx ? nx.dataset.title || '' : '(hết)'}</p>
      <p class="sm">→ / ← chuyển · T bắt đầu / dừng đồng hồ</p>`;
  }
  const clock = () => {
    if (!t0) return '00:00';
    const s = Math.floor((Date.now() - t0) / 1000);
    return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
  };

  // ---------- overview ----------
  function toggleOverview() {
    const on = document.body.classList.toggle('overview');
    if (on) {
      const os = (innerWidth - 56 - 66) / 4 / 1600;
      document.documentElement.style.setProperty('--os', os);
      slides.forEach((s, i) => { const c = document.createElement('div'); c.className = 'cell'; s.before(c); c.append(s); s.onclick = () => { toggleOverview(); show(i); }; });
      $$('[data-step]').forEach((e) => e.classList.remove('hide'));
    } else {
      $$('.cell').forEach((c) => { c.before(c.firstElementChild); c.remove(); });
      slides.forEach((s) => (s.onclick = null));
      show(cur, step);
    }
  }

  // ---------- help ----------
  function toggleHelp() {
    const h = $('.help');
    if (h) return h.remove();
    const d = document.createElement('div');
    d.className = 'help';
    d.innerHTML = [['→ Space', 'tiếp'], ['←', 'lùi'], ['N', 'ghi chú'], ['P', 'cửa sổ người nói'], ['T', 'đồng hồ'], ['K', 'soi bằng chứng'], ['D', 'sáng / tối'], ['O', 'xem tổng quan'], ['F', 'toàn màn hình'], ['Ctrl+P', 'in PDF']]
      .map(([k, v]) => `<div><kbd>${k}</kbd>${v}</div>`).join('');
    document.body.append(d);
  }

  // ---------- keys ----------
  document.addEventListener('keydown', (e) => {
    if (e.ctrlKey || e.metaKey || e.altKey) return;
    const k = e.key;
    if (['ArrowRight', 'ArrowDown', ' ', 'PageDown', 'Enter'].includes(k)) { e.preventDefault(); next(); }
    else if (['ArrowLeft', 'ArrowUp', 'PageUp', 'Backspace'].includes(k)) { e.preventDefault(); prev(); }
    else if (k === 'Home') show(0);
    else if (k === 'End') show(total - 1);
    else if (k === 'n' || k === 'N') { notesOn = !notesOn; renderNotes(); }
    else if (k === 'p' || k === 'P') window.open(location.pathname + '?presenter#' + (cur + 1), 'attendo-presenter', 'width=1100,height=760');
    else if (k === 't' || k === 'T') { t0 = t0 ? null : Date.now(); if (presenter) renderPresenter(); }
    else if (k === 'k' || k === 'K') document.body.classList.toggle('soi');
    else if (k === 'd' || k === 'D') { const r = document.documentElement; r.dataset.theme = r.dataset.theme === 'dark' ? 'light' : 'dark'; try { localStorage.setItem('deck-theme', r.dataset.theme); } catch {} }
    else if (k === 'o' || k === 'O') toggleOverview();
    else if (k === 'f' || k === 'F') (document.fullscreenElement ? document.exitFullscreen() : document.documentElement.requestFullscreen?.());
    else if (k === '?' || k === 'h' || k === 'H') toggleHelp();
    else if (k === 'Escape') { closePop(); $('.help')?.remove(); if (document.body.classList.contains('overview')) toggleOverview(); }
  });
  // click / tap on the right two thirds = next, left third = back (not on links or proof marks)
  deck.addEventListener('click', (e) => {
    if (document.body.classList.contains('overview') || e.target.closest('a, .pf, button')) return;
    (e.clientX > innerWidth / 3 ? next : prev)();
  });

  try { const th = localStorage.getItem('deck-theme'); if (th) document.documentElement.dataset.theme = th; } catch {}
  addEventListener('resize', fit);
  addEventListener('hashchange', () => { const n = parseInt(location.hash.slice(1), 10); if (Number.isFinite(n) && n - 1 !== cur) show(n - 1); });
  fit();
  const h = parseInt(location.hash.slice(1), 10);
  show(Number.isFinite(h) ? h - 1 : 0);
  if (!presenter) {
    const hint = document.createElement('div');
    hint.className = 'hint';
    hint.textContent = '? phím tắt · K soi bằng chứng · N ghi chú';
    document.body.append(hint);
  }
})();
