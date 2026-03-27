# Quinn Archibeque for Delta County Sheriff — Website Project Instructions

---

## Project Overview

A multi-page campaign website for Quinn Archibeque, candidate for Delta County Sheriff 2026. The site is hosted on Hostinger and built with plain HTML, CSS, and JavaScript (no framework). The visual identity uses a navy, gold, and cream palette with Playfair Display, Source Serif 4, and Barlow Condensed typefaces.

---

## File Structure

```
public_html/
├── index.html          # Home page
├── story.html          # Quinn's full biography page
├── caucus.html         # County Assembly info page (post-caucus)
├── style.css           # Main stylesheet (shared by index.html)
├── main.js             # Main JavaScript (hero canvas animation, nav, scroll reveals, contact form)
├── .htaccess           # Removes .html from URLs
└── images/
    ├── quinn.jpeg                              # Candidate photo used in About section
    └── Screenshot 2026-02-23 at 6.32.23 PM.png  # Mesa landscape divider image
```

---

## URL Structure

Clean URLs are handled via `.htaccess`. The live URLs are:

| File          | URL       |
| ------------- | --------- |
| `index.html`  | `/`       |
| `story.html`  | `/story`  |
| `caucus.html` | `/caucus` |

**Live domain:** `quinn4deltacountysheriff.com`

### .htaccess content

```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^([^.]+)$ $1.html [L]
```

---

## Pages

### 1. `index.html` — Home Page

The main campaign landing page. Uses `style.css` and `main.js`. Contains the following sections in order:

- **Nav** — fixed top bar with logo, links, and mobile hamburger menu
- **Hero** — full-screen section with animated WebGL canvas background, candidate name, slogan, and CTA buttons
- **About** — candidate photo, bio copy, stats (28+ years in law enforcement, 18+ years at Sheriff's Office), and link to `/story`
- **Values** — three-card grid: Homegrown Values, Proven Service, Leading with Experience
- **Experience Timeline** — three career milestones
- **Quote Break** — full-width pull quote
- **Mesa Divider** — landscape image divider above footer
- **Contact Form** — name, email, interest dropdown, message textarea (wired to n8n webhook)
- **Footer** — slogan and legal disclaimer

**Nav links:**

- About → `#about`
- Quinn's Story → `/story.html`
- Values → `#values`
- Experience → `#experience`
- Caucus Info → `/caucus.html` (styled as a pulsing red button)
- Contact → `#contact`
- Get Involved → `#contact` (gold CTA button)

**Inline styles in `index.html`:** A `<style>` block handles `.btn-story-link`, `.nav-caucus` (pulsing red), `.caucus-alert` (not currently used but retained), and `.mesa-divider`.

**Cache busting:** The script tag uses a version parameter: `<script src="main.js?v=2"></script>`. Increment the version number (`?v=3`, `?v=4`, etc.) any time `main.js` is updated to bypass browser and Hostinger LiteSpeed cache.

---

### 2. `story.html` — Quinn's Story

A standalone biography page. All CSS is self-contained (no external stylesheet). Links back to `/` in the nav.

**Sections:**

- Page header with eyebrow, H1, and subheading
- **The Beginning** — family roots, farm heritage, kids, wife
- **Rising Through the Ranks** — full career narrative with a formatted career ladder table
- **Always Learning** — FTO program, POST Driving Board, GCU bachelor's degree (4.0 GPA)
- **The County We Deserve** — vision on accountability, victims, criminal justice, legislative advocacy
- Closing quote section
- CTA bar linking to `/#contact` and `/`
- Mesa landscape divider
- Footer

**Career ladder entries:**
| Year | Role | Agency |
|---|---|---|
| 1998 | Patrol Officer & Patrol Sergeant | Cedaredge Police Department |
| Mid Career | Patrol Officer | Delta Police Department |
| 2008 | Reserve Deputy → Patrol Deputy | Delta County Sheriff's Office |
| — | Investigator | Delta County Sheriff's Office |
| — | Investigations Sergeant | Delta County Sheriff's Office |
| 2019 | Undersheriff | Delta County Sheriff's Office |

> Note: Exact years for Investigator and Investigations Sergeant promotions have not been provided yet. Update when available.

---

### 3. `caucus.html` — County Assembly (Updated March 2026)

This page was originally built for both Caucus Night (March 3rd) and the County Assembly. Following the caucus on March 3rd, it was updated to focus exclusively on the upcoming County Assembly.

**Current state (post-caucus):**

- Red urgent banner replaced with a quieter navy banner focused on March 21st
- Page header updated to "Republican County Assembly"
- Caucus Night event card removed — only the County Assembly card remains
- Intro copy thanks caucus attendees and directs delegates to the assembly
- "How It Works" steps updated: Show Up → Vote for Quinn → Questions?
- Action buttons: Delta County GOP (primary) + Contact the Campaign
- Bottom info box addresses delegates specifically

**Event:**

| Event           | Date                 | Location                                             |
| --------------- | -------------------- | ---------------------------------------------------- |
| County Assembly | Saturday, March 21st | Delta Center for the Performing Arts (All Precincts) |

**Action button links:**
| Button | URL |
|---|---|
| Delta County GOP | https://www.deltacoloradogop.com/ |
| Contact the Campaign | /#contact |

> After March 21st this page should be archived or redirected. See Outstanding Items.

---

## Design System

### Colors

| Variable    | Hex       | Usage                    |
| ----------- | --------- | ------------------------ |
| `--navy`    | `#1a2333` | Primary background, text |
| `--navy-lt` | `#243147` | Secondary navy           |
| `--gold`    | `#c9a84c` | Accents, links, borders  |
| `--gold-lt` | `#e2c47a` | Hover states             |
| `--cream`   | `#f5f0e8` | Page background          |
| `--warm`    | `#ede7d9` | Card backgrounds         |
| `--red`     | `#9e2a2b` | Urgency elements         |

### Typography

| Font             | Usage                                  |
| ---------------- | -------------------------------------- |
| Playfair Display | Headlines, pull quotes, candidate name |
| Source Serif 4   | Body copy                              |
| Barlow Condensed | Eyebrows, labels, nav, buttons, stats  |

All fonts loaded via Google Fonts in each file's `<head>`.

---

## SEO & Search Visibility

All three pages have been updated with meta descriptions and Open Graph tags.

### Meta descriptions

| Page          | Description                                                                                                                                                                                                   |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `index.html`  | "Quinn Archibeque is running for Delta County Sheriff in 2026. Nearly 28 years in law enforcement, 18 years at the Delta County Sheriff's Office. Homegrown values, proven service, leading with experience." |
| `story.html`  | "Read Quinn Archibeque's full story — born and raised in Delta County, nearly 28 years in law enforcement, and ready to serve as Delta County Sheriff in 2026."                                               |
| `caucus.html` | "The Delta County Republican Assembly is Saturday, March 21st at the Delta Center for the Performing Arts. Delegates — here's everything you need to know to support Quinn Archibeque for Sheriff."           |

### Search visibility tasks (in progress)

- **Google Business Profile** — being set up to improve visibility in local search. Not a traditional business listing — used to ensure the campaign surfaces prominently when Delta County residents search Quinn's name or the race.
- **Google Search Console** — domain verification and sitemap submission in progress. Free tool; ensures all three pages are properly indexed by Google.
- **Facebook** — social media team should post consistently in local Delta County Facebook groups for direct community reach.

---

## Contact Form & n8n Integration

### Form Fields

- `fname` — First Name (required)
- `lname` — Last Name (required)
- `email` — Email Address (required)
- `interest` — Dropdown: Volunteer, Yard Sign, Donate, Just want more info
- `message` — Optional message textarea

### How It Works

The contact form on `index.html` submits via `fetch()` POST to an n8n webhook. The form does not redirect on submit — it shows inline success/error messages.

### n8n Webhook

- **URL:** `https://n8n.srv1427028.hstgr.cloud/webhook/efd6356f-aa9b-4cf8-aaeb-fb49f8ceca89`
- **Method:** POST
- **Content-Type:** application/json
- **Payload:** `{ fname, lname, email, interest, message }`

### n8n Workflow

The n8n instance is hosted on a Hostinger VPS. The workflow is:

```
Webhook (trigger)
  ├── Send Email → to submitter (confirmation)
  ├── Send Email → to Quinn (notification)
  └── Google Sheets → Append row to contact log
```

### Google Sheets Integration

Form submissions are automatically logged to a shared Google Sheet.

- **Sheet URL:** `https://docs.google.com/spreadsheets/d/18KZ_OrPtwBPpprsRSxViL9n9wsPfdrmGt5i0JmBkE0o/edit`
- **Shared with:** Quinn and Darnell
- **Columns:** First Name, Last Name, Email, Interest, Message, Submitted At
- **n8n node:** Google Sheets — Append or Update Row, connected via OAuth2
- **OAuth credential:** Google Sheets account authorized via Google Cloud Console (project 249500384349), External OAuth consent screen, test user: waderk1986@gmail.com

### SMTP / Email Configuration

- **SMTP Host:** `smtp.hostinger.com`
- **Port:** `465` (SSL)
- **Sender Address:** `quinn@quinn4deltacountysheriff.com`
- **From Display Name:** `Quinn Archibeque <quinn@quinn4deltacountysheriff.com>`
- **Important:** Hostinger SMTP rejects sending from any address not owned by the authenticated account. Always use the Hostinger email as the From address.

### Email Templates

**Confirmation email (to submitter):**

- **From:** `Quinn Archibeque <quinn@quinn4deltacountysheriff.com>`
- **To:** `{{ $json.email }}`
- **Subject:** `Thank you for reaching out, {{ $json.fname }}!`
- **Body:** HTML template with personalized greeting, campaign branding (navy/gold/cream), campaign quote, and legal disclaimer.

**Notification email (to Quinn):**

- **From:** `Quinn Archibeque <quinn@quinn4deltacountysheriff.com>`
- **To:** Quinn's email address
- **Subject:** `New Campaign Contact: {{ $json.fname }} {{ $json.lname }}`
- **Body:** HTML template displaying all form fields in a formatted table with a "Reply to {{ $json.fname }}" mailto button.

### Form Error Handling

- On success: form resets, green "Thank you" message shows for 5 seconds
- On failure: red error message shows for 5 seconds, error logged to console
- Button shows "Sending..." and disables during request

---

## Campaign Email

- **Address:** `quinn@quinn4deltacountysheriff.com`
- **Setup:** Hosted on Hostinger Email, configured to forward to Quinn's personal Gmail
- **Status:** Forwarding configured — Quinn must click the verification link in the confirmation email from Hostinger to activate

---

## Hosting & Infrastructure

### Hostinger Shared Hosting

- **Domain:** `quinn4deltacountysheriff.com`
- **Server:** LiteSpeed
- **Email:** Hostinger Email (`quinn@quinn4deltacountysheriff.com`)
- **Cache:** LiteSpeed automatic cache, clears every 30 minutes. No manual purge button available. Use `?v=N` cache busting on static assets when updating.

### Hostinger VPS

- **n8n instance:** `https://n8n.srv1427028.hstgr.cloud`
- **Purpose:** Hosts the n8n automation platform for form processing, email delivery, and Google Sheets logging

---

## Campaign Content

### Candidate Bio Summary

- Born and raised in Delta County on a family farm homesteaded by his great-great-grandfather
- Parents still live on the farm between Delta and Olathe
- Raised by farmers, ranchers, and miners
- Two adult children: son in oil and gas, daughter is a nurse
- Wife; enjoys travel and the outdoors
- Kids raised in Cedaredge, graduated Cedaredge High School
- Currently finishing bachelor's degree in law enforcement leadership at Grand Canyon University, 4.0 GPA

### Career Summary

- Nearly 28 years in law enforcement across three agencies
- 18 years at the Delta County Sheriff's Office as of May 2026
- Started career in 1998 at Cedaredge Police Department
- Served at Delta Police Department before joining the Sheriff's Office
- Joined Sheriff's Office in 2008 as Reserve Deputy
- Appointed Undersheriff by Sheriff Taylor in 2019
- Currently serves on the Colorado POST Driving Board as a Subject Matter Expert
- Served as Field Training Officer; developed first formal FTO program for Cedaredge PD
- Use of Force Instructor, Driving Instructor

### Campaign Slogan

**Homegrown Values · Proven Service · Leading with Experience**

### Primary Quote

> "Accountability under the law. Protection of constitutional rights. Leadership rooted in Western Colorado values. That is my commitment to the people of Delta County."

### Secondary Quote

> "I believe in a justice system that prioritizes victims, demands accountability, and is led by experience."

---

## Legal

All pages include the following disclaimer in the footer:

> Paid for by the Committee to Elect Quinn Archibeque for Delta County Sheriff. Registered Agent: Quinn Archibeque.

---

## Outstanding Items

- [ ] Quinn to click Hostinger email forwarding verification link to activate forwarding
- [ ] Complete Google Business Profile setup for campaign
- [ ] Complete Google Search Console domain verification and sitemap submission
- [ ] Social media team to post consistently in local Delta County Facebook groups
- [ ] Confirm and update exact years for Investigator and Investigations Sergeant promotions in `story.html` career ladder
- [ ] Archive or redirect `caucus.html` after March 21st County Assembly
- [ ] Add additional pages as campaign progresses (e.g. Issues, Endorsements, Events)
- [ ] Add a favicon to the site (currently returns 404)
