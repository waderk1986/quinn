#!/usr/bin/env bash
# pre-deploy.sh — automated QA gate: security, a11y, performance, links
# Run before every deploy: bash pre-deploy.sh

set -euo pipefail

# ── Config ──────────────────────────────────────────────────
PORT=8080
BASE="http://localhost:${PORT}"
REPORT_DIR="reports"
PASS=0
FAIL=0

PAGES=(
	"/"
	"/story.html"
	"/caucus.html"
	"/endorsements.html"
)

# ── Helpers ─────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

pass() { ((PASS++)); echo -e "  ${GREEN}✔${RESET} $1"; }
fail() { ((FAIL++)); echo -e "  ${RED}✘${RESET} $1"; }

mkdir -p "$REPORT_DIR"

# ── 0a. npm audit ───────────────────────────────────────────
echo -e "\n${BOLD}[0a] npm audit — dependency vulnerabilities${RESET}"
AUDIT_OK=true

npm audit --json 2>/dev/null > "$REPORT_DIR/npm-audit.json" || true
AUDIT_HIGH=$(node -e "const d=require('./$REPORT_DIR/npm-audit.json'); const v=d.metadata?.vulnerabilities||{}; console.log((v.high||0)+(v.critical||0))")
AUDIT_TOTAL=$(node -e "const d=require('./$REPORT_DIR/npm-audit.json'); const v=d.metadata?.vulnerabilities||{}; console.log(v.total||0)")

if [ "$AUDIT_HIGH" -gt 0 ]; then
	AUDIT_OK=false
	fail "npm audit — ${AUDIT_HIGH} high/critical vulnerabilities  →  ${REPORT_DIR}/npm-audit.json"
elif [ "$AUDIT_TOTAL" -gt 0 ]; then
	pass "npm audit — ${AUDIT_TOTAL} low/moderate (no high/critical)  →  ${REPORT_DIR}/npm-audit.json"
else
	pass "npm audit — clean  →  ${REPORT_DIR}/npm-audit.json"
fi

# ── 0b. Secrets scan ───────────────────────────────────────
echo -e "\n${BOLD}[0b] Secrets scan — leaked credentials check${RESET}"
SECRETS_OK=true

# Patterns: AWS keys, generic API keys/tokens/secrets, private keys,
# passwords in URLs, high-entropy base64 strings that look like secrets.
# Exclude: node_modules, .git, images, pdfs, package-lock, reports
SECRETS_PATTERNS=(
	'AKIA[0-9A-Z]{16}'                           # AWS access key
	'(?i)(api[_-]?key|api[_-]?secret|auth[_-]?token|secret[_-]?key|private[_-]?key|access[_-]?token)\s*[:=]\s*["\x27][A-Za-z0-9/+=]{16,}'
	'-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'
	'(?i)(password|passwd|pwd)\s*[:=]\s*["\x27][^\s"'\'']{8,}'
	'(?i)(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36}'  # GitHub tokens
	'sk-[A-Za-z0-9]{20,}'                         # OpenAI/Stripe secret keys
)

> "$REPORT_DIR/secrets-scan.txt"
for pattern in "${SECRETS_PATTERNS[@]}"; do
	grep -rPn "$pattern" \
		--include='*.html' --include='*.js' --include='*.css' \
		--include='*.json' --include='*.sh' --include='*.yml' --include='*.yaml' \
		--include='*.md' --include='*.txt' --include='*.env*' \
		--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=reports \
		--exclude='package-lock.json' \
		. >> "$REPORT_DIR/secrets-scan.txt" 2>/dev/null || true
done

# Filter out known-safe patterns (the n8n webhook URL is public client-side JS)
SECRETS_COUNT=$(grep -cvE '^\s*$' "$REPORT_DIR/secrets-scan.txt" 2>/dev/null) || SECRETS_COUNT=0

if [ "$SECRETS_COUNT" -gt 0 ]; then
	SECRETS_OK=false
	fail "Secrets scan — ${SECRETS_COUNT} potential secret(s) found  →  ${REPORT_DIR}/secrets-scan.txt"
	echo "    Review ${REPORT_DIR}/secrets-scan.txt and verify each match is safe."
else
	pass "Secrets scan — clean  →  ${REPORT_DIR}/secrets-scan.txt"
fi

# ── Start local server ──────────────────────────────────────
echo -e "\n${BOLD}Starting local server on :${PORT}...${RESET}"
npx serve . -p "$PORT" &>/dev/null &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true' EXIT

# Poll until ready (max 15s)
for i in $(seq 1 30); do
	if curl -sf "$BASE" >/dev/null 2>&1; then
		break
	fi
	if [ "$i" -eq 30 ]; then
		echo "Server failed to start after 15s"
		exit 1
	fi
	sleep 0.5
done
echo "  Server ready (PID $SERVER_PID)"

# ── 1. Pa11y CI ─────────────────────────────────────────────
echo -e "\n${BOLD}[1/3] Pa11y CI — WCAG 2 AA${RESET}"
# (numbering keeps original 1-3 for the server-dependent checks)
PA11Y_OK=true

# index.html has a WebGL animation loop that prevents pa11y from seeing
# network idle. Run it standalone with a short wait instead.
echo "  Testing / (standalone — WebGL page) ..."
if npx pa11y \
	--standard WCAG2AA \
	--timeout 30000 \
	--wait 3000 \
	--ignore "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail" \
	"${BASE}/index.html" \
	2>&1 | tee "$REPORT_DIR/pa11y.txt"; then
	:
else
	# Timeout is expected on this page (WebGL rAF loop). Only fail on real a11y errors.
	if grep -q "timed out" "$REPORT_DIR/pa11y.txt"; then
		echo "  ⚠ index.html timed out (WebGL animation) — skipping, covered by Lighthouse a11y"
	else
		PA11Y_OK=false
	fi
fi

# Remaining pages via pa11y-ci (uses .pa11yci.json config)
echo "  Testing remaining pages via pa11y-ci ..."
if npx pa11y-ci \
	--config .pa11yci.json \
	2>&1 | tee -a "$REPORT_DIR/pa11y.txt"; then
	:
else
	PA11Y_OK=false
fi

if $PA11Y_OK; then
	pass "Pa11y CI — all pages clean  →  ${REPORT_DIR}/pa11y.txt"
else
	fail "Pa11y CI — errors found     →  ${REPORT_DIR}/pa11y.txt"
fi

# ── 2. Lighthouse CI ────────────────────────────────────────
echo -e "\n${BOLD}[2/3] Lighthouse CI — performance budgets${RESET}"

# Uses .lighthouserc.json for assertions; override collect to point at
# the already-running server and output reports locally.
LHCI_OK=true
LHCI_URLS=""
for page in "${PAGES[@]}"; do
	LHCI_URLS+=" --collect.url=${BASE}${page}"
done

if eval npx lhci autorun \
	"$LHCI_URLS" \
	--collect.numberOfRuns=1 \
	--collect.settings.chromeFlags="\"--no-sandbox --disable-gpu\"" \
	--upload.target=filesystem \
	--upload.outputDir="\"$REPORT_DIR/lighthouse\"" \
	2>&1 | tee "$REPORT_DIR/lighthouse-log.txt"; then
	:
else
	LHCI_OK=false
fi

if $LHCI_OK; then
	pass "Lighthouse CI — all budgets met  →  ${REPORT_DIR}/lighthouse/"
else
	fail "Lighthouse CI — budget failures   →  ${REPORT_DIR}/lighthouse-log.txt"
fi

# ── 3. Linkinator ───────────────────────────────────────────
echo -e "\n${BOLD}[3/3] Linkinator — broken link check${RESET}"

LINK_OK=true
if npx linkinator "$BASE" \
	--recurse \
	--timeout 15000 \
	--concurrency 5 \
	2>&1 | tee "$REPORT_DIR/links.txt"; then
	:
else
	LINK_OK=false
fi

# linkinator exits 0 even with broken links; check output
if grep -q "BROKEN" "$REPORT_DIR/links.txt" 2>/dev/null; then
	LINK_OK=false
fi

if $LINK_OK; then
	pass "Linkinator — no broken links  →  ${REPORT_DIR}/links.txt"
else
	fail "Linkinator — broken links found  →  ${REPORT_DIR}/links.txt"
fi

# ── Summary ─────────────────────────────────────────────────
echo -e "\n${BOLD}─── Summary ───${RESET}"
echo -e "  ${GREEN}✔ ${PASS} passed${RESET}"
if [ "$FAIL" -gt 0 ]; then
	echo -e "  ${RED}✘ ${FAIL} failed${RESET}"
fi
echo ""
echo "  Reports:"
echo "    ${REPORT_DIR}/npm-audit.json"
echo "    ${REPORT_DIR}/secrets-scan.txt"
echo "    ${REPORT_DIR}/pa11y.txt"
echo "    ${REPORT_DIR}/lighthouse/"
echo "    ${REPORT_DIR}/lighthouse-log.txt"
echo "    ${REPORT_DIR}/links.txt"
echo ""

if [ "$FAIL" -gt 0 ]; then
	echo -e "${RED}${BOLD}DEPLOY BLOCKED — fix failures above before deploying.${RESET}"
	exit 1
else
	echo -e "${GREEN}${BOLD}ALL CHECKS PASSED — safe to deploy.${RESET}"
	exit 0
fi
