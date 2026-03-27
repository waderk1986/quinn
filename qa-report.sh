#!/bin/bash
# qa-report.sh — runs all QA tools, collects output, generates HTML report
# Usage: bash qa-report.sh

set -euo pipefail

REPORT_DIR="qa-report"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
mkdir -p "$REPORT_DIR"

echo "🔍 Running QA suite..."
echo ""

# ── ESLint ──────────────────────────────────────────────────
echo "  [1/5] ESLint (JS)..."
npx eslint main.js --format json > "$REPORT_DIR/eslint.json" 2>&1 || true

# ── Stylelint ────────────────────────────────────────────────
echo "  [2/5] Stylelint (CSS)..."
npx stylelint style.css --formatter json > "$REPORT_DIR/stylelint.json" 2>&1 || true

# ── html-validate ────────────────────────────────────────────
echo "  [3/5] html-validate (HTML)..."
npx html-validate index.html story.html caucus.html endorsements.html --formatter json > "$REPORT_DIR/htmlvalidate.json" 2>&1 || true

# ── Prettier ─────────────────────────────────────────────────
echo "  [4/5] Prettier (format check)..."
npx prettier --check main.js style.css 2>&1 | tee "$REPORT_DIR/prettier.txt" || true

# ── pa11y ────────────────────────────────────────────────────
echo "  [5/5] pa11y skipped (needs live server — run separately with: npm run a11y)"
echo "[]" > "$REPORT_DIR/pa11y.json"

# ── Generate HTML report ──────────────────────────────────────
echo ""
echo "  Generating HTML report..."

node - <<'EOF'
const fs   = require('fs');
const path = require('path');

const dir  = 'qa-report';
const ts   = process.env.QA_TIMESTAMP || new Date().toLocaleString();

function safeRead(file) {
  try { return fs.readFileSync(path.join(dir, file), 'utf8'); } catch { return ''; }
}
function safeJSON(file) {
  try { return JSON.parse(safeRead(file)); } catch { return null; }
}

const eslint      = safeJSON('eslint.json')      || [];
const stylelint   = safeJSON('stylelint.json')   || [];
const htmlval     = safeJSON('htmlvalidate.json') || {};
const prettierRaw = safeRead('prettier.txt');

// ── Count helpers ──────────────────────────────────────────
function countESLint(data) {
  let errors = 0, warnings = 0;
  (Array.isArray(data) ? data : []).forEach(f => {
    errors   += f.errorCount   || 0;
    warnings += f.warningCount || 0;
  });
  return { errors, warnings };
}

function countStylelint(data) {
  let errors = 0, warnings = 0;
  const arr = Array.isArray(data) ? data : (data?.results || []);
  arr.forEach(f => {
    (f.warnings || []).forEach(w => {
      if (w.severity === 2) errors++; else warnings++;
    });
  });
  return { errors, warnings };
}

function countHTML(data) {
  let errors = 0, warnings = 0;
  const results = data?.results || (Array.isArray(data) ? data : []);
  results.forEach(f => {
    (f.messages || []).forEach(m => {
      if (m.severity === 2 || m.severity === 'error') errors++;
      else warnings++;
    });
  });
  return { errors, warnings };
}

const eslintCounts   = countESLint(eslint);
const stylelintCounts = countStylelint(stylelint);
const htmlCounts     = countHTML(htmlval);
const prettierClean  = !prettierRaw.includes('Code style issues');
const prettierCount  = prettierClean ? 0 : (prettierRaw.match(/Code style issues/g) || []).length;

const totalErrors   = eslintCounts.errors + stylelintCounts.errors + htmlCounts.errors + (prettierClean ? 0 : 1);
const totalWarnings = eslintCounts.warnings + stylelintCounts.warnings + htmlCounts.warnings;

// ── Render helpers ─────────────────────────────────────────
function badge(errors, warnings) {
  if (errors > 0)   return `<span class="badge err">${errors} error${errors!==1?'s':''}</span>`;
  if (warnings > 0) return `<span class="badge warn">${warnings} warning${warnings!==1?'s':''}</span>`;
  return `<span class="badge pass">✓ clean</span>`;
}

function eslintRows(data) {
  const arr = Array.isArray(data) ? data : [];
  const rows = [];
  arr.forEach(f => {
    const file = path.basename(f.filePath);
    (f.messages || []).forEach(m => {
      const sev = m.severity === 2 ? 'err' : 'warn';
      rows.push(`<tr class="${sev}">
        <td>${file}</td>
        <td>${m.line}:${m.column}</td>
        <td>${m.severity === 2 ? '✖ error' : '⚠ warn'}</td>
        <td>${escHtml(m.message)}</td>
        <td class="rule">${m.ruleId || ''}</td>
      </tr>`);
    });
  });
  return rows.length ? rows.join('') : '<tr><td colspan="5" class="clean">No issues found</td></tr>';
}

function stylelintRows(data) {
  const arr = Array.isArray(data) ? data : (data?.results || []);
  const rows = [];
  arr.forEach(f => {
    const file = path.basename(f.source || '');
    (f.warnings || []).forEach(w => {
      const sev = w.severity === 2 ? 'err' : 'warn';
      rows.push(`<tr class="${sev}">
        <td>${file}</td>
        <td>${w.line}:${w.column}</td>
        <td>${w.severity === 2 ? '✖ error' : '⚠ warn'}</td>
        <td>${escHtml(w.text || w.message || '')}</td>
        <td class="rule">${w.rule || ''}</td>
      </tr>`);
    });
  });
  return rows.length ? rows.join('') : '<tr><td colspan="5" class="clean">No issues found</td></tr>';
}

function htmlRows(data) {
  const results = data?.results || (Array.isArray(data) ? data : []);
  const rows = [];
  results.forEach(f => {
    const file = path.basename(f.filePath || f.filename || '');
    (f.messages || []).forEach(m => {
      const isErr = m.severity === 2 || m.severity === 'error';
      const sev = isErr ? 'err' : 'warn';
      rows.push(`<tr class="${sev}">
        <td>${file}</td>
        <td>${m.line || '—'}:${m.column || '—'}</td>
        <td>${isErr ? '✖ error' : '⚠ warn'}</td>
        <td>${escHtml(m.message)}</td>
        <td class="rule">${m.ruleId || m.rule || ''}</td>
      </tr>`);
    });
  });
  return rows.length ? rows.join('') : '<tr><td colspan="5" class="clean">No issues found</td></tr>';
}

function escHtml(s) {
  return String(s)
    .replace(/&/g,'&amp;')
    .replace(/</g,'&lt;')
    .replace(/>/g,'&gt;')
    .replace(/"/g,'&quot;');
}

// ── HTML ───────────────────────────────────────────────────
const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>QA Report — Quinn for Sheriff</title>
<style>
  :root {
    --navy: #1a2333; --gold: #c9a84c; --cream: #f5f0e8;
    --err: #9e2a2b; --warn: #b07d2a; --pass: #2d6a4f;
    --err-bg: #fdf0f0; --warn-bg: #fdf7ed; --pass-bg: #edf7f2;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
         background: var(--cream); color: var(--navy); font-size: 14px; }

  /* Header */
  .header { background: var(--navy); padding: 2rem 2.5rem; border-bottom: 3px solid var(--gold); }
  .header h1 { font-size: 1.3rem; color: #fff; font-weight: 700; }
  .header h1 span { color: var(--gold); }
  .header-meta { color: rgba(255,255,255,0.45); font-size: 0.78rem; margin-top: 0.3rem; letter-spacing: 0.05em; }

  /* Summary row */
  .summary { display: flex; gap: 1px; background: rgba(0,0,0,0.08); }
  .summary-card { flex: 1; background: #fff; padding: 1.5rem 2rem; }
  .summary-card-label { font-size: 0.68rem; letter-spacing: 0.15em; text-transform: uppercase;
                        color: #8a9bb0; margin-bottom: 0.5rem; }
  .summary-card-value { font-size: 2rem; font-weight: 800; line-height: 1; }
  .summary-card-value.err  { color: var(--err); }
  .summary-card-value.warn { color: var(--warn); }
  .summary-card-value.pass { color: var(--pass); }

  /* Tool sections */
  .section { margin: 2rem 2.5rem; }
  .section-header { display: flex; align-items: center; gap: 1rem;
                    margin-bottom: 0.75rem; }
  .section-title { font-size: 0.9rem; font-weight: 700; letter-spacing: 0.05em;
                   text-transform: uppercase; color: var(--navy); }
  .section-sub { font-size: 0.75rem; color: #8a9bb0; }

  /* Badges */
  .badge { display: inline-block; font-size: 0.7rem; font-weight: 700;
           letter-spacing: 0.08em; text-transform: uppercase;
           padding: 0.2rem 0.6rem; border-radius: 2px; }
  .badge.err  { background: var(--err-bg);  color: var(--err); }
  .badge.warn { background: var(--warn-bg); color: var(--warn); }
  .badge.pass { background: var(--pass-bg); color: var(--pass); }

  /* Tables */
  .tbl-wrap { overflow-x: auto; border-radius: 3px; border: 1px solid rgba(0,0,0,0.08); }
  table { width: 100%; border-collapse: collapse; font-size: 0.82rem; background: #fff; }
  th { background: var(--navy); color: rgba(255,255,255,0.7); font-weight: 600;
       text-transform: uppercase; font-size: 0.65rem; letter-spacing: 0.1em;
       padding: 0.6rem 0.9rem; text-align: left; }
  td { padding: 0.55rem 0.9rem; border-bottom: 1px solid rgba(0,0,0,0.05);
       vertical-align: top; line-height: 1.5; }
  tr:last-child td { border-bottom: none; }
  tr.err td:first-child { border-left: 3px solid var(--err); }
  tr.warn td:first-child { border-left: 3px solid var(--warn); }
  .rule { font-family: monospace; font-size: 0.75rem; color: #8a9bb0; }
  td.clean { color: var(--pass); font-style: italic; text-align: center;
             padding: 1.2rem; }

  /* Prettier */
  .prettier-output { background: #fff; border: 1px solid rgba(0,0,0,0.08);
                     border-radius: 3px; padding: 1rem 1.2rem;
                     font-family: monospace; font-size: 0.8rem; white-space: pre-wrap;
                     color: var(--navy); line-height: 1.6; }
  .prettier-output.clean { color: var(--pass); }

  /* a11y note */
  .a11y-note { background: #fff; border: 1px solid rgba(0,0,0,0.08); border-radius: 3px;
               padding: 1.2rem 1.5rem; color: #8a9bb0; font-style: italic; }
  .a11y-note code { background: rgba(0,0,0,0.06); padding: 0.1rem 0.4rem; border-radius: 2px;
                    font-style: normal; font-size: 0.82rem; color: var(--navy); }

  /* Footer */
  .footer { margin: 3rem 0 0; background: var(--navy);
            padding: 1.25rem 2.5rem; border-top: 2px solid var(--gold); }
  .footer p { font-size: 0.72rem; color: rgba(255,255,255,0.3);
              font-family: 'Barlow Condensed', sans-serif; letter-spacing: 0.05em; }
</style>
</head>
<body>

<div class="header">
  <h1>QA Report — <span>Quinn Archibeque for Sheriff</span></h1>
  <div class="header-meta">Generated ${ts}</div>
</div>

<div class="summary">
  <div class="summary-card">
    <div class="summary-card-label">Total Errors</div>
    <div class="summary-card-value ${totalErrors > 0 ? 'err' : 'pass'}">${totalErrors}</div>
  </div>
  <div class="summary-card">
    <div class="summary-card-label">Total Warnings</div>
    <div class="summary-card-value ${totalWarnings > 0 ? 'warn' : 'pass'}">${totalWarnings}</div>
  </div>
  <div class="summary-card">
    <div class="summary-card-label">Prettier</div>
    <div class="summary-card-value ${prettierClean ? 'pass' : 'warn'}">${prettierClean ? 'OK' : 'Fix'}</div>
  </div>
  <div class="summary-card">
    <div class="summary-card-label">A11y / Lighthouse</div>
    <div class="summary-card-value warn">—</div>
  </div>
</div>

<!-- ESLint -->
<div class="section">
  <div class="section-header">
    <div class="section-title">ESLint</div>
    <div class="section-sub">main.js</div>
    ${badge(eslintCounts.errors, eslintCounts.warnings)}
  </div>
  <div class="tbl-wrap">
    <table>
      <thead><tr><th>File</th><th>Line</th><th>Severity</th><th>Message</th><th>Rule</th></tr></thead>
      <tbody>${eslintRows(eslint)}</tbody>
    </table>
  </div>
</div>

<!-- Stylelint -->
<div class="section">
  <div class="section-header">
    <div class="section-title">Stylelint</div>
    <div class="section-sub">style.css</div>
    ${badge(stylelintCounts.errors, stylelintCounts.warnings)}
  </div>
  <div class="tbl-wrap">
    <table>
      <thead><tr><th>File</th><th>Line</th><th>Severity</th><th>Message</th><th>Rule</th></tr></thead>
      <tbody>${stylelintRows(stylelint)}</tbody>
    </table>
  </div>
</div>

<!-- html-validate -->
<div class="section">
  <div class="section-header">
    <div class="section-title">html-validate</div>
    <div class="section-sub">index.html · story.html · caucus.html</div>
    ${badge(htmlCounts.errors, htmlCounts.warnings)}
  </div>
  <div class="tbl-wrap">
    <table>
      <thead><tr><th>File</th><th>Line</th><th>Severity</th><th>Message</th><th>Rule</th></tr></thead>
      <tbody>${htmlRows(htmlval)}</tbody>
    </table>
  </div>
</div>

<!-- Prettier -->
<div class="section">
  <div class="section-header">
    <div class="section-title">Prettier</div>
    <div class="section-sub">format check · main.js · style.css</div>
    ${prettierClean
      ? '<span class="badge pass">✓ clean</span>'
      : '<span class="badge warn">needs formatting</span>'}
  </div>
  <div class="prettier-output ${prettierClean ? 'clean' : ''}">${
    prettierClean
      ? '✓ All files match Prettier formatting.'
      : escHtml(prettierRaw)
  }</div>
</div>

<!-- a11y -->
<div class="section">
  <div class="section-header">
    <div class="section-title">Accessibility (pa11y)</div>
    <div class="section-sub">requires live server</div>
    <span class="badge warn">not run</span>
  </div>
  <div class="a11y-note">
    pa11y needs a running server to test against. Start one with
    <code>npx serve . -p 8080</code> in a separate terminal, then run
    <code>npm run a11y</code>. Re-run <code>bash qa-report.sh</code> afterward
    to include results in the next report.
  </div>
</div>

<div class="footer">
  <p>Paid for by the Committee to Elect Quinn Archibeque for Delta County Sheriff.</p>
</div>

</body>
</html>`;

fs.writeFileSync(path.join(dir, 'index.html'), html);
console.log('  Report written to qa-report/index.html');
EOF

export QA_TIMESTAMP="$TIMESTAMP"

echo ""
echo "✅ Done. Open the report:"
echo "   open qa-report/index.html"
echo ""
