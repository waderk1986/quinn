# Pre-Deploy Checklist

**Workflow:**
`lint-staged` (every commit, auto) → `gitleaks` (every commit, auto) → `bash pre-deploy.sh` (every deploy, automated — npm audit, secrets scan, pa11y, Lighthouse, linkinator) → this checklist (every deploy, manual) → post-deploy spot check

---

## Visual Pass

- [ ] index.html — desktop and mobile, no spacing/overflow issues
- [ ] story.html — desktop and mobile
- [ ] caucus.html — desktop and mobile
- [ ] endorsements.html — desktop and mobile
- [ ] Nav links work on every page (all links land correctly)
- [ ] Images load, no broken/missing assets
- [ ] Fonts render correctly (no FOUT flash lasting more than ~1s)

## Responsive Breakpoints

Test each page at these widths — no horizontal scroll, no overlapping elements:

- [ ] 1920px (large desktop)
- [ ] 1440px (desktop)
- [ ] 1024px (tablet landscape)
- [ ] 768px (tablet portrait)
- [ ] 390px (mobile)

## Forms

- [ ] Submit contact form with valid data — confirm success message appears
- [ ] Submit with empty required fields — confirm validation prevents submission
- [ ] Submit with invalid email — confirm validation catches it
- [ ] Verify submission actually arrives (n8n webhook → email/spreadsheet)

## Post-Deploy Verification (after uploading to Hostinger)

- [ ] Test on a real phone (not DevTools) — pages load, nav works, form submits
- [ ] Hard refresh (`Ctrl+Shift+R` / clear cache) — no stale CSS/JS
- [ ] Submit contact form again from production URL
- [ ] Check all pages load over HTTPS with no mixed-content warnings
- [ ] Verify DNS/CDN is serving correctly (check response headers)

## Security Headers (check via browser DevTools Network tab or securityheaders.com)

- [ ] `Strict-Transport-Security` present (HSTS)
- [ ] `X-Content-Type-Options: nosniff`
- [ ] `X-Frame-Options: DENY` or `SAMEORIGIN`
- [ ] `Referrer-Policy` set (e.g., `strict-origin-when-cross-origin`)
- [ ] No `Server` header leaking version info (or at least not detailed)
- [ ] HTTPS redirect working (http:// → https://)
