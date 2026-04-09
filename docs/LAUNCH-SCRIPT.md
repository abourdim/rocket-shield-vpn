# Launch Script Reference

Complete reference for `rocket-shield.sh` (Bash) and `rocket-shield.ps1` (PowerShell).

---

## Overview

The project includes two launch scripts that provide an interactive menu for serving the educational web app and managing real VPN infrastructure.

| Script | Platform | Shell | Requirements |
|--------|----------|-------|-------------|
| `rocket-shield.sh` | Linux, macOS, Raspberry Pi | Bash | Python3 or Node.js (for web server) |
| `rocket-shield.ps1` | Windows | PowerShell | Python or Node.js (for web server) |

Both scripts offer similar functionality, but `rocket-shield.sh` has full VPN server capabilities while `rocket-shield.ps1` focuses on the web app and client setup (VPN server hosting on Windows is not recommended).

---

## Usage

### Linux / macOS / Raspberry Pi

```bash
chmod +x rocket-shield.sh
bash rocket-shield.sh
```

### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File rocket-shield.ps1
```

---

## Menu Options Reference

### Main Menu

| Option | Name | Description | Requires sudo |
|--------|------|-------------|:---:|
| 1 | Launch Web App | Serve `index.html` on a local HTTP server | No |
| 2 | VPN Client Setup | Install and configure WireGuard or OpenVPN client | Yes (for import/activate) |
| 3 | VPN Server Setup | Set up a WireGuard/OpenVPN server, add clients, Docker | Yes |
| 4 | Status & Diagnostics | System info, network, VPN status, dependency check | Yes (for wg show) |
| 5 | Stop All Services | Stop web server, WireGuard, and OpenVPN | Yes (for VPN stop) |
| 6 | Exit | Quit the script | No |

### Option 2 Sub-Menu (VPN Client)

| Sub-Option | Description |
|------------|-------------|
| 1 | WireGuard Client -- install, import `.conf`, activate, enable on boot |
| 2 | OpenVPN Client -- install, import `.ovpn`, connect |
| 3 | Show Client Status -- display active WireGuard interfaces and OpenVPN processes |
| 4 | Back to main menu |

### Option 3 Sub-Menu (VPN Server)

| Sub-Option | Description |
|------------|-------------|
| 1 | WireGuard Server -- install, generate keys, create config, IP forwarding, firewall, systemd |
| 2 | OpenVPN Server -- install, provide guidance (recommends WireGuard or Docker) |
| 3 | Add Client Config -- generate keys, create client `.conf`, display QR code |
| 4 | Show Server Status -- display WireGuard server info, OpenVPN server info, client configs |
| 5 | Docker Setup -- start/stop/status/logs for docker-compose |
| 6 | Back to main menu |

---

## Option 1: Launch Web App

Serves `index.html` using the best available HTTP server on your system.

### Auto-Detection Priority

The script tries these in order:

1. **Python3** (`python3 -m http.server`) -- most common on Linux/macOS/Pi
2. **npx** (`npx serve`) -- if Node.js is installed
3. **Node.js** (`node -e "..."`) -- inline HTTP server fallback

On Windows (PowerShell), the order is:
1. **Python** (`python -m http.server`)
2. **npx** (`npx serve`)

### Port Configuration

Default port is **8080**. The script prompts you to change it.

### LAN Binding

The Bash script asks whether to bind to `0.0.0.0` (all interfaces, accessible from other devices on your network) or `127.0.0.1` (localhost only).

### QR Code for Mobile

If `qrencode` is installed and binding to all interfaces, the script generates a terminal QR code. Scan it with your phone's camera to open the web app.

### Auto-Open Browser

After starting the server, the script offers to open the URL in your default browser using `xdg-open` (Linux), `open` (macOS), or `Start-Process` (Windows).

---

## Option 2: VPN Client Setup

### WireGuard Client

1. **Install**: If `wg` is not found, offers to install via the system package manager.
2. **Import config**: Prompts for the path to a `.conf` file (from your VPN provider).
3. **Activate**: Copies the config to `/etc/wireguard/`, sets permissions to 600, and runs `wg-quick up`.
4. **Enable on boot**: Optionally enables the `wg-quick@<name>` systemd service.

### OpenVPN Client

1. **Install**: If `openvpn` is not found, offers to install it.
2. **Import config**: Prompts for the path to a `.ovpn` file.
3. **Connect**: Copies the config to `/etc/openvpn/` and starts OpenVPN in daemon mode.

### Show Client Status

Displays:
- Active WireGuard interfaces (`sudo wg show`)
- Running OpenVPN processes (`pgrep -a openvpn`)

---

## Option 3: VPN Server Setup

### WireGuard Server

The script performs these steps:

1. **Install WireGuard** if not present.
2. **Check for existing config** at `/etc/wireguard/wg0.conf` and warn if it exists.
3. **Prompt for port** (default: 51820).
4. **Generate server key pair** using `wg genkey` and `wg pubkey`.
5. **Detect public IP** using `curl ifconfig.me` (allows manual override).
6. **Detect default network interface** from the routing table.
7. **Create server config** (`/etc/wireguard/wg0.conf`) with:
   - Address: `10.66.66.1/24`
   - ListenPort: chosen port
   - PrivateKey: generated server key
   - PostUp/PostDown: iptables rules for NAT/masquerade
8. **Enable IP forwarding** (`net.ipv4.ip_forward=1` in sysctl).
9. **Configure UFW firewall** to allow the WireGuard port (if UFW is installed).
10. **Start the server** with `wg-quick up wg0`.
11. **Enable on boot** with `systemctl enable wg-quick@wg0`.
12. **Save server info** (public key, IP, port) to `./vpn-configs/` for client generation.
13. **Show Raspberry Pi tips** if running on a Pi.

### OpenVPN Server

The script installs OpenVPN and `easy-rsa` if needed, then recommends using WireGuard or Docker instead. It offers to switch to WireGuard server setup.

### Add Client

1. Prompts for a client name (e.g., "phone", "laptop").
2. Finds the next available IP in the `10.66.66.0/24` subnet.
3. Generates a client key pair.
4. Adds a `[Peer]` block to the server config.
5. Creates a client `.conf` file in `./vpn-configs/<name>.conf`.
6. Reloads the server config (if running) using `wg syncconf`.
7. Displays a QR code (if `qrencode` is installed) for mobile import.
8. Prints the full client config to the terminal.

### Docker Setup Sub-Menu

| Sub-Option | Command |
|------------|---------|
| 1 - Start | `docker-compose up -d` |
| 2 - Stop | `docker-compose down` |
| 3 - Status | `docker-compose ps` |
| 4 - Logs | `docker-compose logs --tail=50` |
| 5 - Back | Return to server menu |

---

## Option 4: Status and Diagnostics

Displays a comprehensive system and network report:

### System Info
- Operating system and kernel version
- CPU architecture
- Raspberry Pi detection
- System uptime
- Memory usage (total / used)

### Network
- Local IP address (via `hostname -I` on Linux or `ipconfig getifaddr` on macOS)
- Public IP address (via `curl ifconfig.me`)

### VPN Status
- **WireGuard**: Active interfaces, connected peers, endpoints, latest handshake, data transferred
- **OpenVPN**: Running processes

### DNS Leak Check
- Queries Cloudflare (`https://1.1.1.1/cdn-cgi/trace`) for the IP they see
- Compares it with your public IP
- If they match, warns that VPN may not be active
- If they differ, confirms VPN is working

### Dependency Check
Reports installed/missing status for: Python3, Node.js, WireGuard, OpenVPN, Docker, qrencode.

---

## Option 5: Stop All Services

Stops all services started by the script:

1. **Web server**: Kills the background HTTP server process (by PID).
2. **WireGuard**: Asks for confirmation, then runs `wg-quick down wg0`.
3. **OpenVPN**: Asks for confirmation, then runs `killall openvpn`.

The script also registers a cleanup trap (`trap cleanup EXIT`) that kills the web server process on script exit.

---

## Platform Detection

The Bash script detects the platform at startup:

### OS Detection

Uses `uname -s` to determine:
- `Linux` -- checks `/etc/os-release` for distro info
- `Darwin` -- macOS

### Raspberry Pi Detection

Checks `/proc/cpuinfo` for "raspberry", "bcm27", or "bcm28" identifiers. Sets `IS_PI=true` if found, which enables:
- Raspberry Pi-specific tips during server setup
- Pi indicator in the banner display
- ARM optimization suggestions

### ARM Detection

Checks `uname -m` for `arm*` or `aarch64`. Sets `IS_ARM=true`.

### Package Manager Detection

Checks for available package managers in this order:

| Package Manager | Distros |
|----------------|---------|
| `apt` (`apt-get`) | Ubuntu, Debian, Raspberry Pi OS |
| `dnf` | Fedora, RHEL, CentOS Stream |
| `pacman` | Arch Linux, Manjaro |
| `brew` | macOS |

### Dependency Detection

Checks for these commands at startup:

| Dependency | Command Checked | Used For |
|-----------|----------------|----------|
| Python3 | `python3` | HTTP server |
| Node.js | `node` | HTTP server (fallback) |
| npx | `npx` | HTTP server (via `npx serve`) |
| WireGuard | `wg` | VPN client/server |
| OpenVPN | `openvpn` | VPN client |
| qrencode | `qrencode` | QR codes for mobile |
| curl | `curl` | Public IP detection, DNS leak check |
| UFW | `ufw` | Firewall configuration |
| Docker | `docker` | Docker setup sub-menu |

---

## Environment Variables

The Bash script uses these internal variables (set at the top of the script):

| Variable | Default | Description |
|----------|---------|-------------|
| `WEB_PORT` | `8080` | HTTP server port |
| `WG_INTERFACE` | `wg0` | WireGuard interface name |
| `WG_PORT` | `51820` | WireGuard server port |
| `WG_SUBNET` | `10.66.66` | First three octets of the VPN subnet |
| `WG_CONFIG_DIR` | `/etc/wireguard` | WireGuard configuration directory |
| `OVPN_CONFIG_DIR` | `/etc/openvpn` | OpenVPN configuration directory |
| `CLIENT_CONFIG_DIR` | `./vpn-configs` | Directory for generated client configs |

These are not read from the environment -- they are hardcoded defaults in the script. You can modify them by editing the script directly, or the script will prompt you to override the port values interactively.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Normal exit (user selected Exit or pressed q/Q) |
| Non-zero | Unexpected error (due to `set -euo pipefail`) |

The script uses `set -euo pipefail` which means:
- `set -e`: Exit on any command failure
- `set -u`: Exit on undefined variable usage
- `set -o pipefail`: Pipeline fails if any command in the pipe fails

In practice, the script handles most errors gracefully with confirmation prompts and fallbacks, so a non-zero exit typically indicates a system-level problem.

---

## Windows Script Differences

The PowerShell script (`rocket-shield.ps1`) provides the same menu structure but with these differences:

| Feature | Bash Script | PowerShell Script |
|---------|------------|-------------------|
| VPN Server setup | Full WireGuard server | Info only (recommends Pi, Docker, or WSL2) |
| VPN Client | WireGuard + OpenVPN | WireGuard + OpenVPN (GUI-based) |
| QR code generation | Terminal QR via qrencode | Not available |
| LAN binding option | Yes (0.0.0.0 vs 127.0.0.1) | Not prompted (serves on localhost) |
| Docker sub-menu | Yes | Not included |
| WSL detection | N/A | Detects WSL and suggests using Bash script via WSL |
| Package manager | apt, dnf, pacman, brew | Manual download links |

For full VPN server functionality on Windows, the PowerShell script recommends using WSL2:

```powershell
wsl bash rocket-shield.sh
```
