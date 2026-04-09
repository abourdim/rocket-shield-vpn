# Rocket Shield VPN -- Documentation

Welcome to the **Rocket Shield VPN** documentation. This project is an educational web app that teaches kids and teens how VPNs and internet security work through a space-themed adventure. It also includes launch scripts for real VPN setup (WireGuard/OpenVPN), Docker support, a Freebox VPN guide, and Raspberry Pi deployment.

Everything you need to understand, configure, deploy, and extend the project is covered here.

---

## Table of Contents

| Document | Description |
|----------|-------------|
| [FAQ.md](FAQ.md) | Frequently asked questions (30+ Q&As by category) |
| [STEP-BY-STEP.md](STEP-BY-STEP.md) | Beginner-friendly walkthrough to get started |
| [WIREGUARD.md](WIREGUARD.md) | WireGuard VPN client and server setup guide |
| [OPENVPN.md](OPENVPN.md) | OpenVPN client and server setup guide |
| [FREEBOX.md](FREEBOX.md) | Configuring VPN on a Free (Freebox) router |
| [RASPBERRY-PI.md](RASPBERRY-PI.md) | Deploying Rocket Shield VPN on a Raspberry Pi |
| [DOCKER.md](DOCKER.md) | Docker and Docker Compose deployment |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Technical architecture and codebase reference |
| [LAUNCH-SCRIPT.md](LAUNCH-SCRIPT.md) | Reference for rocket-shield.sh and rocket-shield.ps1 |

---

## Quick Links

**Most common tasks:**

- **Run the web app locally** -- See [STEP-BY-STEP.md](STEP-BY-STEP.md) or just open `index.html` in a browser.
- **Deploy with Docker** -- See [DOCKER.md](DOCKER.md) (`docker-compose up -d`).
- **Set up a WireGuard VPN server** -- See [WIREGUARD.md](WIREGUARD.md).
- **Set up VPN on your Freebox** -- See [FREEBOX.md](FREEBOX.md).
- **Deploy on a Raspberry Pi** -- See [RASPBERRY-PI.md](RASPBERRY-PI.md).
- **Understand the codebase** -- See [ARCHITECTURE.md](ARCHITECTURE.md).
- **Troubleshooting** -- See the Troubleshooting section in [FAQ.md](FAQ.md).

---

## Project Overview

```
rocket-shield-vpn/
  index.html              -- The entire web app (single HTML file)
  icon-512.png            -- App icon
  rocket-shield.sh        -- Launch script (Linux/macOS/Pi)
  rocket-shield.ps1       -- Launch script (Windows PowerShell)
  Dockerfile              -- Docker container for web app
  docker-compose.yml      -- Docker Compose (web + optional WireGuard)
  docs/                   -- This documentation folder
```

The web app is a single self-contained HTML file with zero dependencies (except Google Fonts loaded via CDN). The launch scripts provide real VPN infrastructure on top of the educational app.

---

*Stay safe out there, Commander!*
