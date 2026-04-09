# Rocket Shield VPN — Documentation

Welcome to the **Rocket Shield VPN** documentation. This project is an educational web app that teaches kids and teens how VPNs and internet security work through a space-themed adventure. It also includes interactive tools, games, launch scripts for real VPN setup, Docker support, and more.

---

## Table of Contents

### Guides

| Document | Description |
|----------|-------------|
| [FAQ.md](FAQ.md) | Frequently asked questions (30+ Q&As by category) |
| [STEP-BY-STEP.md](STEP-BY-STEP.md) | Beginner-friendly walkthrough — choose, install, connect, test |
| [WIREGUARD.md](WIREGUARD.md) | WireGuard complete reference — all config params, examples |
| [OPENVPN.md](OPENVPN.md) | OpenVPN complete reference — server/client params, certificates |

### Freebox

| Document | Description |
|----------|-------------|
| [FREEBOX.md](FREEBOX.md) | Freebox VPN overview — all models, client vs server |
| [FREEBOX-REVOLUTION.md](FREEBOX-REVOLUTION.md) | **Freebox Revolution** — Complete OpenVPN setup (client + server) |
| [FREEBOX-WIREGUARD.md](FREEBOX-WIREGUARD.md) | **Freebox WireGuard** — Complete setup for Delta/Pop/Ultra/One |

### Deployment

| Document | Description |
|----------|-------------|
| [RASPBERRY-PI.md](RASPBERRY-PI.md) | Raspberry Pi deployment with security hardening |
| [DOCKER.md](DOCKER.md) | Docker and Docker Compose deployment |
| [LAUNCH-SCRIPT.md](LAUNCH-SCRIPT.md) | Launch script reference (rocket-shield.sh / .ps1) |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Technical architecture and codebase reference |

---

## Interactive Tools

| Page | Description |
|------|-------------|
| [start-here.html](../start-here.html) | 🚀 Server-first VPN setup guide — the recommended starting point |
| [packet-journey.html](../packet-journey.html) | 🎬 Watch a packet travel through a VPN tunnel with encryption animation |
| [attack-simulator.html](../attack-simulator.html) | 🎮 10-level defense game — block hackers with VPN, firewall, 2FA |
| [config-generator.html](../config-generator.html) | ⚙️ Generate WireGuard/OpenVPN configs with QR codes in browser |
| [speed-test.html](../speed-test.html) | ⚡ Speed test dashboard — before/after VPN comparison |
| [vpn-status.html](../vpn-status.html) | 🛡️ Live VPN status checker — IP, location, WebRTC leak detection |
| [password-generator.html](../password-generator.html) | 🔐 Password & passphrase generator with strength meter |
| [dns-explorer.html](../dns-explorer.html) | 🌐 Animated DNS resolution visualizer |
| [encryption-playground.html](../encryption-playground.html) | 🔒 Caesar/XOR/AES-256 encryption playground with crack demos |
| [crypto-quiz.html](../crypto-quiz.html) | 🧪 50-question timed cybersecurity quiz with leaderboard |
| [phishing-detector.html](../phishing-detector.html) | 🎣 Spot the phishing email — 15 scenarios training game |
| [firewall-builder.html](../firewall-builder.html) | 🧱 Build firewall rules, see iptables commands, test with packets |
| [vpn-dashboard.html](../vpn-dashboard.html) | 📡 See real connected VPN devices — Freebox API, wg show parser, demo |
| [docs.html](../docs.html) | 📚 Full HTML documentation hub with search and sidebar |

---

## Quick Links

**Most common tasks:**

- **Start here** — Open [start-here.html](../start-here.html) for the recommended setup path
- **Run the web app** — Open `index.html` in a browser, or `bash rocket-shield.sh` → option 1
- **Deploy with Docker** — `docker-compose up -d` (see [DOCKER.md](DOCKER.md))
- **Set up WireGuard server** — See [WIREGUARD.md](WIREGUARD.md) or [FREEBOX-WIREGUARD.md](FREEBOX-WIREGUARD.md)
- **Set up OpenVPN (Revolution)** — See [FREEBOX-REVOLUTION.md](FREEBOX-REVOLUTION.md)
- **Deploy on Raspberry Pi** — See [RASPBERRY-PI.md](RASPBERRY-PI.md)
- **Troubleshooting** — See [FAQ.md](FAQ.md)

---

## Project Structure

```
rocket-shield-vpn/
├── index.html                 # Main educational app (PWA)
├── start-here.html            # Server-first setup guide
├── docs.html                  # HTML documentation hub
│
├── packet-journey.html        # Packet animation
├── attack-simulator.html      # Defense game
├── config-generator.html      # Config + QR generator
├── speed-test.html            # Speed test dashboard
├── vpn-status.html            # Live VPN status checker
├── password-generator.html    # Password generator
├── dns-explorer.html          # DNS visualizer
├── encryption-playground.html # Encryption playground
├── crypto-quiz.html           # Cybersecurity quiz
├── phishing-detector.html     # Phishing detection game
├── firewall-builder.html      # Firewall rule builder
│
├── icon-512.png               # App icon
├── manifest.json              # PWA manifest
├── sw.js                      # Service worker
├── rocket-shield.sh           # Launch script (Linux/macOS/Pi)
├── rocket-shield.ps1          # Launch script (Windows)
├── Dockerfile                 # Docker container
├── docker-compose.yml         # Docker Compose
│
├── .github/workflows/
│   └── deploy.yml             # GitHub Pages auto-deploy
│
└── docs/
    ├── README.md              # This file
    ├── FAQ.md
    ├── STEP-BY-STEP.md
    ├── WIREGUARD.md
    ├── OPENVPN.md
    ├── FREEBOX.md
    ├── FREEBOX-REVOLUTION.md
    ├── FREEBOX-WIREGUARD.md
    ├── RASPBERRY-PI.md
    ├── DOCKER.md
    ├── ARCHITECTURE.md
    └── LAUNCH-SCRIPT.md
```

---

*Stay safe out there, Commander! 🚀🛡️*
