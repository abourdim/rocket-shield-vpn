# Rocket Shield VPN -- Technical Architecture

This document describes the internal architecture of the Rocket Shield VPN project: the single-file web app, its CSS and JavaScript systems, the i18n and theming layers, the Freebox section, the launch scripts, and the Docker setup.

---

## Overview

The web app is a **single self-contained HTML file** (`index.html`, ~2100 lines, ~170 KB). It contains all HTML structure, CSS styles, JavaScript logic, translations, and even the logo (base64-embedded). There are **zero build steps** and **zero runtime dependencies** (Google Fonts are loaded via CDN but the app falls back gracefully to system fonts).

```
+-----------------------------------------------------+
|                    index.html                        |
|  +-----------------------------------------------+  |
|  |  <style>   CSS themes, layout, animations     |  |
|  +-----------------------------------------------+  |
|  |  <body>    HTML structure, 4 page containers   |  |
|  +-----------------------------------------------+  |
|  |  <script>  i18n data, state, all JS functions  |  |
|  +-----------------------------------------------+  |
+-----------------------------------------------------+
```

---

## File Structure

| File | Purpose |
|------|---------|
| `index.html` | Complete web app (HTML + CSS + JS + translations + embedded logo) |
| `icon-512.png` | App icon (used as favicon and Open Graph image) |
| `rocket-shield.sh` | Launch script for Linux, macOS, and Raspberry Pi |
| `rocket-shield.ps1` | Launch script for Windows PowerShell |
| `Dockerfile` | Nginx-based Docker image for the web app |
| `docker-compose.yml` | Compose file for web app + optional WireGuard server |
| `docs/` | Documentation folder |

---

## HTML Structure

The app uses a tab-based single-page layout with four page containers. Only one page is visible at a time, controlled by the `.active` class.

```
<html lang="en" dir="ltr">
  <head>
    <meta> tags, fonts, <style> block
  </head>
  <body>
    .stars-container          -- Animated star background
    .app                      -- Main wrapper (max-width: 920px)
      .header                 -- Sticky header (logo, status chip, dropdowns)
      .nav                    -- Tab navigation (4 buttons)
      #page-command           -- Command Center (VPN simulator)
      #page-academy           -- Mission Academy (learning cards)
      #page-launchpad         -- Launch Pad (real VPN install guide)
      #page-freebox           -- Freebox VPN guide
    #modal                    -- Modal overlay for concept cards
  </body>
  <script> block              -- All JavaScript
</html>
```

### Page IDs and Navigation

| Page ID | Nav Button data-page | Description |
|---------|---------------------|-------------|
| `page-command` | `command` | VPN simulation cockpit |
| `page-academy` | `academy` | Interactive learning cards |
| `page-launchpad` | `launchpad` | Step-by-step real VPN install |
| `page-freebox` | `freebox` | Freebox router VPN configuration |

Navigation is handled by `showPage(page)` which toggles the `.active` class on both the page container and its corresponding nav button.

---

## CSS System

### Theme Variables

Themes are implemented using CSS custom properties on the `:root` and `[data-theme]` selectors. Switching themes just sets the `data-theme` attribute on `<html>`.

| Theme | Selector | Primary Accent |
|-------|----------|----------------|
| Space Commander | `:root`, `[data-theme="space"]` | `#44e5a0` (green) |
| Sunset Desert | `[data-theme="desert"]` | `#ff8c42` (orange) |
| Synthwave | `[data-theme="synthwave"]` | `#f472b6` (pink) |
| Paper Light | `[data-theme="paper"]` | `#22966a` (teal) |

**Key CSS variables:**

```css
--bg, --bg2, --bg3           /* Background layers */
--card, --card-hover          /* Card backgrounds (rgba) */
--border, --border-hover      /* Border colors */
--text, --text2, --text3      /* Text hierarchy */
--accent, --accent2, --accent3 /* Primary, secondary, tertiary accents */
--accent-soft, --accent-glow  /* Soft fill and glow variants */
--gradient-hero               /* Hero gradient (4-color) */
--gradient-btn                /* Button gradient (2-color) */
--radius, --radius-sm, --radius-pill /* Border radii */
--shadow                      /* Box shadow */
--font-display                /* Fredoka (headings) */
--font-body                   /* Nunito (body) */
--star-opacity                /* Star background visibility (0 for paper) */
```

### How to Create a New Theme

1. Add a new `[data-theme="yourname"]` block in the `<style>` section.
2. Override all the CSS variables listed above.
3. Add an `<option>` to the theme `<select>` in the header HTML.

### Responsive Breakpoints

| Breakpoint | Target |
|------------|--------|
| `max-width: 640px` | Mobile layout (stacked nav, smaller fonts, card columns) |
| `max-width: 600px` | Settings grid collapse to single column |

The layout is mobile-first with flexbox and grid used throughout.

### Animation Keyframes

| Keyframe | Element | Effect |
|----------|---------|--------|
| `twinkle` | `.star` | Stars fade in/out and scale |
| `gradientShift` | Logo text | Animated gradient background |
| `pulse` | `.status-dot` | Status indicator breathing |
| `fadeUp` | `.page` | Page entrance (fade + slide up) |
| `float` | ByteBot, Freebox router | Gentle vertical float |
| `blink-light` | Robot indicator light | Blinking light effect |
| `spin` | Orb ring | Continuous rotation |
| `ring-pulse` | Orb pulse rings | Expanding/fading rings |
| `fadeIn` | Modal overlay | Simple fade in |
| `slideUp` | Modal content | Slide up entrance |
| `confetti-fall` | Confetti particles | Confetti falling down |
| `sweep` | Radar sweep | 360-degree rotation |
| `packetFlow` | Freebox packet | Data packet animation (left to right) |
| `packetFlowRev` | Freebox packet | Data packet animation (right to left) |
| `threatBounce` | Threat indicator | Bouncing threat icon |

---

## JavaScript Modules

All JavaScript lives in a single `<script>` block. There is no module system or bundler. The code is organized into logical sections separated by comment banners.

### State Management

Global state is managed with plain variables at the top of the script:

```
lang             -- Current language ('en', 'fr', 'ar')
connected        -- VPN simulation active (boolean)
connecting       -- Connection in progress (boolean)
elapsed          -- Seconds since connection
downloaded       -- Bytes received (simulated)
uploaded         -- Bytes sent (simulated)
timer            -- setInterval reference for tick()
currentMode      -- Academy difficulty ('newbie', 'explorer', 'advanced')
currentStep      -- Current step in Launch Pad (0-4)
completedCards   -- Set of completed card IDs per mode
bytebotClicks    -- Click counter for easter egg
selectedServer   -- Index into servers array
checks           -- Launch Pad test checkboxes (array of booleans)
freeboxStep      -- Current Freebox guide step (0-6)
freeboxChecks    -- Freebox checklist (array of booleans)
konamiSeq        -- Konami code key sequence tracker
fbxVpnOn         -- Freebox VPN toggle state
```

### Key Functions

| Function | Purpose |
|----------|---------|
| `init()` | App entry point, called on load. Sets up stars, renders UI, attaches Konami listener |
| `generateStars()` | Creates random star elements in `.stars-container` |
| `setLang(l)` | Changes language, sets `dir` attribute, re-renders all content |
| `updateI18n()` | Walks all `[data-i18n]` elements and applies translations |
| `setTheme(theme)` | Sets `data-theme` attribute on `<html>` |
| `showPage(page)` | Switches visible page, updates nav buttons |
| `toggleConnection()` | Starts/stops VPN simulation with 2-second launch delay |
| `tick()` | Runs every second while "connected", updates stats |
| `updateConnectionUI()` | Syncs all UI elements to current connection state |
| `renderServers()` | Renders the server selection list |
| `renderConceptGrid()` | Renders learning cards for current mode |
| `openCard(id)` | Opens a concept card in the modal |
| `answerQuiz(id, chosen, el)` | Handles quiz answer, tracks completion |
| `checkBadge()` | Checks if all cards in current mode are complete |
| `renderStep()` | Renders current Launch Pad step |
| `renderFreeboxStep()` | Renders current Freebox guide step (0-6) |
| `fireConfetti()` | Creates confetti particle animation |
| `bytebotClick()` | Handles ByteBot click, triggers dance at 5 clicks |
| `fbxToggleVpn()` | Toggles Freebox VPN simulation state |

### Render Functions

Several functions dynamically build HTML using template literals and `innerHTML`:

- `renderConceptGrid()` -- Builds the card grid for the selected difficulty mode.
- `renderStep()` -- Builds the current Launch Pad step content.
- `renderFreeboxStep()` -- Builds the current Freebox guide step with diagrams.
- `renderServers()` -- Builds the server list with ping and load indicators.
- `renderShipColors()` -- Builds the ship color selector buttons.
- `openCard(id)` -- Builds the modal content for a concept card (metaphor, fun fact, quiz).

### Event Handlers

Events are attached via inline `onclick` attributes in the HTML and through `addEventListener` in `init()`. The Konami code listener is a `keydown` event on `document`.

---

## i18n System

Translations are stored in a `const i18n` object with language codes as top-level keys:

```
i18n = {
  en: { key: "English text", ... },
  fr: { key: "Texte en francais", ... },
  ar: { key: "النص بالعربية", ... }
}
```

### How Translation Works

1. HTML elements that need translation have a `data-i18n="key"` attribute.
2. `updateI18n()` queries all `[data-i18n]` elements and sets their `textContent` to `t(key)`.
3. The `t(key)` function returns `i18n[lang][key]`, falling back to English if a key is missing.
4. Dynamic content (rendered by JS functions) calls `t(key)` directly in template literals.

### How to Add a New Language

1. Add a new language object to the `i18n` const (e.g., `es: { ... }`).
2. Translate all keys from the `en` object.
3. Add an `<option>` to the language `<select>` in the header HTML.
4. If the language is RTL, add a condition in `setLang()` to set `dir="rtl"`.

---

## Theme System

### How Themes Work

1. Each theme is a CSS block under `[data-theme="name"]` that overrides all custom properties.
2. `setTheme(theme)` sets `document.documentElement.setAttribute('data-theme', theme)`.
3. All colors, gradients, shadows, and the star background opacity are controlled by variables.
4. Transitions on `background` and `color` (0.4s) provide smooth theme switching.

### How to Create a New Theme

1. Copy an existing `[data-theme="..."]` CSS block.
2. Rename the selector to `[data-theme="yourtheme"]`.
3. Adjust all variable values (backgrounds, accents, gradients, etc.).
4. Set `--star-opacity` to `0` for light themes, `0.6`-`1` for dark themes.
5. Add an `<option value="yourtheme">` to the theme dropdown in the header.

---

## Freebox Section

The Freebox page (`#page-freebox`) is a 7-step interactive guide for configuring VPN on a Freebox router. It is rendered dynamically by `renderFreeboxStep()`.

### CSS Classes (fbx-* prefix)

| Class | Purpose |
|-------|---------|
| `.fbx-diagram` | Container for the Freebox router diagram |
| `.fbx-router` | Animated router icon (uses `float` animation) |
| `.fbx-router-label` | Label below the router icon |
| `.fbx-vs-lanes` | Two-column grid for client vs server comparison |
| `.fbx-lane` | A single lane (client or server) |
| `.fbx-lane-client` | Client lane variant (green accent on hover) |
| `.fbx-lane-server` | Server lane variant (blue accent on hover) |
| `.fbx-lane-hdr` | Lane header text |
| `.fbx-lane-flow` | Animated data flow with packet visualization |
| `.fbx-node` | Emoji node in the flow diagram |
| `.fbx-pipe` | Animated pipe connecting nodes |
| `.fbx-packet` | Animated data packet inside the pipe |
| `.fbx-browser` | Mock browser window for Freebox OS |
| `.fbx-bbar` | Browser bar (dots + URL) |
| `.fbx-bdots` | Browser window dots (red, yellow, green) |
| `.fbx-url` | URL bar content |
| `.fbx-bbody` | Browser body content |
| `.fbx-os-menu` | Freebox OS menu items |
| `.fbx-os-item` | Individual menu item |
| `.fbx-os-active` | Active/highlighted menu item |
| `.fbx-path` | Step-by-step path visualization |
| `.fbx-path-step` | Individual step in the path |

### Diagram System

The Freebox section uses ASCII-style flow diagrams built with emoji nodes (`.fbx-node`), animated pipes (`.fbx-pipe`), and packet elements (`.fbx-packet`) to visualize how data flows through a VPN. The `packetFlow` and `packetFlowRev` keyframes animate packets moving left-to-right or right-to-left.

---

## Launch Scripts

### Architecture of rocket-shield.sh (Bash)

The Bash script (~800 lines) is a cross-platform interactive menu for Linux, macOS, and Raspberry Pi.

```
rocket-shield.sh
  |
  +-- Platform Detection
  |     detect_platform()    -- OS, arch, Pi detection, package manager
  |     detect_deps()        -- Python, Node, WireGuard, OpenVPN availability
  |
  +-- Interactive Menu (5 options)
  |     1. Launch Web App    -- Python/Node HTTP server + browser open + QR
  |     2. VPN Client Setup  -- Install + import WireGuard or OpenVPN configs
  |     3. VPN Server Setup  -- WireGuard server with key generation + QR codes
  |     4. Status & Diagnostics -- Public IP, DNS leak check, VPN status
  |     5. Stop All Services -- Kill web server, disconnect VPN
  |
  +-- Globals
  |     WEB_PORT=8080, WG_PORT=51820, WG_SUBNET=10.66.66
  |     WG_CONFIG_DIR, OVPN_CONFIG_DIR, CLIENT_CONFIG_DIR
  |
  +-- Helper Functions
        info(), success(), warn(), error(), header()
        confirm(), press_enter()
```

**Key features:**

- Detects Raspberry Pi via `/proc/cpuinfo` and optimizes for ARM.
- Supports apt, dnf, and pacman package managers.
- Generates WireGuard keypairs and client configs with QR codes.
- Serves the web app using Python (`http.server`) or Node (`npx serve`).

### Architecture of rocket-shield.ps1 (PowerShell)

The PowerShell script (~400 lines) mirrors the Bash script for Windows.

```
rocket-shield.ps1
  |
  +-- Helper Functions
  |     Write-Info, Write-Ok, Write-Warn, Write-Err
  |     Test-Command, Get-LocalIP, Get-PublicIP
  |
  +-- Interactive Menu (6 options)
  |     1. Launch Web App       -- Python or npx serve
  |     2. VPN Client Setup     -- WireGuard/OpenVPN guide
  |     3. VPN Server Info      -- WireGuard server guide
  |     4. Status & Diagnostics -- Public IP, VPN check
  |     5. Stop All Services    -- Stop web server
  |     6. Exit
  |
  +-- Globals
        $WebPort = 8080, $ScriptDir
```

---

## Docker

### Dockerfile Structure

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
COPY icon-512.png /usr/share/nginx/html/icon-512.png
# Custom nginx config (gzip, SPA fallback)
EXPOSE 80
HEALTHCHECK (wget --spider http://localhost/)
```

The Dockerfile creates a minimal Nginx container that serves the single HTML file. Gzip compression is enabled for HTML, CSS, and JavaScript content types.

### docker-compose.yml Structure

```
services:
  webapp:
    build: .                    # Builds from Dockerfile
    container_name: rocket-shield-web
    ports: 8080:80
    restart: unless-stopped
    healthcheck: wget spider

  # wireguard (commented out by default):
  #   image: lscr.io/linuxserver/wireguard:latest
  #   cap_add: NET_ADMIN, SYS_MODULE
  #   environment:
  #     PEERS=3                 # Number of client configs
  #     SERVERPORT=51820
  #     PEERDNS=1.1.1.1,8.8.8.8
  #     INTERNAL_SUBNET=10.66.66.0/24
  #   volumes: ./vpn-configs:/config
  #   ports: 51820:51820/udp
```

To enable the WireGuard VPN server, uncomment the `wireguard` section and run `docker-compose up -d`. Client configs and QR codes will be generated in `./vpn-configs/`.

### Volume Mapping

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./vpn-configs/` | `/config` | WireGuard client configs and QR codes |
| `/lib/modules` | `/lib/modules:ro` | Kernel modules (read-only, required by WireGuard) |

---

## Summary Diagram

```
                    +-------------------+
                    |   User's Browser  |
                    +--------+----------+
                             |
              +--------------+--------------+
              |                             |
     Open index.html directly    OR    HTTP server
     (file:// protocol)                (port 8080)
                                            |
                              +-------------+-------------+
                              |             |             |
                         Python         Node.js       Docker/Nginx
                      http.server      npx serve      (Dockerfile)
                              |             |             |
                              +------+------+------+------+
                                     |             |
                              rocket-shield.sh   docker-compose.yml
                              rocket-shield.ps1       |
                                     |          +-----+-----+
                                     |          |           |
                              Real VPN Setup  webapp    wireguard
                              (WireGuard /    service    service
                               OpenVPN)
```
