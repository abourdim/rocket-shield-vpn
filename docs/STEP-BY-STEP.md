# Step-by-Step Guide -- From Zero to Running VPN

This guide walks you through everything: running the educational web app, setting up a VPN client, hosting your own VPN server, and connecting remotely.

---

## Prerequisites

### Operating System

| OS | Version | Notes |
|----|---------|-------|
| Ubuntu / Debian | 20.04+ | Recommended for server setup |
| macOS | 12 (Monterey)+ | Client setup and web app |
| Raspberry Pi OS | Bullseye+ | Ideal lightweight VPN server |
| Windows | 10/11 | Web app and client only (use WSL2 for server) |

### Hardware

- **Any PC or laptop** -- for running the web app and VPN client
- **Raspberry Pi 3B+, 4, or 5** -- for hosting a lightweight VPN server
- **Minimum RAM**: 512 MB (Pi), 2 GB (desktop)

### Network

- Active internet connection
- Router access for port forwarding (if hosting a server)
- Know your local IP and how to access your router admin panel

---

## Part 1: Run the Educational Web App

The web app is a single HTML file. There are three ways to run it.

### Method A: Double-Click (Simplest)

1. Download or clone the repository.
2. Open the project folder.
3. Double-click `index.html`.
4. The app opens in your default browser. Done.

No server, no installation, no dependencies.

### Method B: Use the Launch Script

The launch script serves the app over your local network so other devices (phones, tablets) can access it.

**Linux / macOS / Raspberry Pi:**

```bash
chmod +x rocket-shield.sh
bash rocket-shield.sh
```

Select option **1) Launch Web App** from the menu. The script will:
- Auto-detect Python3, Node.js, or npx
- Ask you for a port (default: 8080)
- Ask if you want LAN access (bind to 0.0.0.0)
- Show a QR code for mobile access (if `qrencode` is installed)
- Offer to open your browser automatically

**Windows (PowerShell):**

```powershell
powershell -ExecutionPolicy Bypass -File rocket-shield.ps1
```

Select option **1) Launch Web App**. It uses Python or npx to serve the file.

### Method C: Docker

```bash
docker-compose up -d
```

This builds an nginx container and serves the app on port **8080**. Open `http://localhost:8080` in your browser.

To stop:

```bash
docker-compose down
```

---

## Part 2: Set Up a VPN Client with WireGuard

Use this to connect to a commercial VPN provider (NordVPN, ProtonVPN, Mullvad, etc.) or to your own VPN server.

### Step 1: Install WireGuard

| Platform | Command |
|----------|---------|
| Ubuntu/Debian | `sudo apt install wireguard` |
| Fedora | `sudo dnf install wireguard-tools` |
| Arch | `sudo pacman -S wireguard-tools` |
| macOS | `brew install wireguard-tools` |
| Windows | Download from [wireguard.com/install](https://www.wireguard.com/install/) |
| Android/iOS | Install "WireGuard" from your app store |

Or use the launch script: run `bash rocket-shield.sh`, select option **2 > 1** (WireGuard Client). It will offer to install WireGuard for you.

### Step 2: Get a Config File from Your Provider

Each VPN provider gives you a `.conf` file. Here is how to get one:

- **NordVPN**: Log in to your account > Manual Setup > WireGuard > Download config
- **ProtonVPN**: Log in > Downloads > WireGuard configuration > Generate and download
- **Mullvad**: Log in > WireGuard configuration > Generate key and download config

The file will look something like:

```ini
[Interface]
PrivateKey = <your-private-key>
Address = 10.x.x.x/32
DNS = 1.1.1.1

[Peer]
PublicKey = <server-public-key>
Endpoint = <server-ip>:51820
AllowedIPs = 0.0.0.0/0
```

### Step 3: Import the Config

**Using the launch script:**

```bash
bash rocket-shield.sh
# Select 2 > 1 (WireGuard Client)
# Enter the path to your .conf file when prompted
```

The script copies the config to `/etc/wireguard/`, sets permissions, and optionally activates it.

**Manual method:**

```bash
sudo cp ~/Downloads/my-vpn.conf /etc/wireguard/my-vpn.conf
sudo chmod 600 /etc/wireguard/my-vpn.conf
```

### Step 4: Connect and Verify

```bash
# Bring up the tunnel
sudo wg-quick up my-vpn

# Check status
sudo wg show

# Enable on boot
sudo systemctl enable wg-quick@my-vpn
```

On Windows, open the WireGuard app, click "Import tunnel(s) from file", select your `.conf`, and click "Activate".

---

## Part 3: Set Up a VPN Client with OpenVPN

### Step 1: Install OpenVPN

| Platform | Command |
|----------|---------|
| Ubuntu/Debian | `sudo apt install openvpn` |
| Fedora | `sudo dnf install openvpn` |
| macOS | `brew install openvpn` |
| Windows | Download OpenVPN Connect from [openvpn.net/client](https://openvpn.net/client/) |

Or use the launch script: option **2 > 2** (OpenVPN Client).

### Step 2: Get a .ovpn File

Download the `.ovpn` configuration file from your VPN provider's website. Most providers offer this under "Manual Setup" or "OpenVPN configuration".

### Step 3: Import and Connect

**Using the launch script:**

```bash
bash rocket-shield.sh
# Select 2 > 2 (OpenVPN Client)
# Enter the path to your .ovpn file
```

**Manual method:**

```bash
sudo cp ~/Downloads/my-vpn.ovpn /etc/openvpn/client/my-vpn.conf
sudo openvpn --config /etc/openvpn/client/my-vpn.conf --daemon
```

On Windows, open OpenVPN Connect, import the `.ovpn` file, enter your credentials, and click Connect.

---

## Part 4: Set Up a VPN Server on Linux or Raspberry Pi

Host your own WireGuard VPN server so you can connect from anywhere.

### Step 1: Install WireGuard

```bash
sudo apt update && sudo apt install wireguard
```

### Step 2: Generate Server Keys

```bash
wg genkey | tee server_private.key | wg pubkey > server_public.key
```

### Step 3: Create Server Config

The launch script handles this automatically. Run:

```bash
bash rocket-shield.sh
# Select 3 > 1 (WireGuard Server)
```

It will:
- Install WireGuard if needed
- Generate keys
- Ask for your port (default: 51820) and public IP
- Create `/etc/wireguard/wg0.conf`

The generated config looks like:

```ini
[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = <server-private-key>
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

### Step 4: Enable IP Forwarding

```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```

### Step 5: Configure Firewall

```bash
sudo ufw allow 51820/udp
```

### Step 6: Start and Enable on Boot

```bash
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

### Step 7: Create Client Configs

Use the launch script:

```bash
bash rocket-shield.sh
# Select 3 > 3 (Add Client Config)
# Enter a name (e.g., "phone", "laptop")
```

The script generates a `.conf` file in `./vpn-configs/` and shows a QR code for mobile devices (if `qrencode` is installed).

---

## Part 5: Set Up VPN Server on Freebox

If you have a Freebox (French ISP "Free"), it has a built-in VPN server.

### Step 1: Access Freebox OS

Open your browser and go to `http://mafreebox.freebox.fr`. Log in with your Freebox password.

### Step 2: Enable VPN Server

Navigate to **Freebox OS > VPN Server** (or "Serveur VPN").

### Step 3: Choose Protocol

- **OpenVPN** -- available on all Freebox models with VPN support
- **WireGuard** -- available on newer models (Delta, Pop, Ultra)

### Step 4: Create a User

Click "Add a user" (or "Ajouter un utilisateur"). Set a username and password.

### Step 5: Download Client Config

After creating the user, click the download icon to get the `.ovpn` or `.conf` file.

### Step 6: Connect from Outside

Import the downloaded config into your VPN client (WireGuard app or OpenVPN Connect) on your phone or laptop. Connect while on mobile data or another Wi-Fi network to test.

See the [FREEBOX.md](FREEBOX.md) guide for detailed instructions.

---

## Part 6: Connect Remotely

Once your VPN server is running, connect to it from anywhere.

### From Your Phone

1. Install the **WireGuard** app (iOS or Android).
2. Tap the **+** button.
3. Choose **Scan from QR Code** (the launch script shows one) or **Import from file**.
4. Toggle the connection on.

### From Your Laptop

1. Install WireGuard or OpenVPN.
2. Import the client `.conf` or `.ovpn` file.
3. Activate the tunnel.

### QR Code Method

If you set up the server using `rocket-shield.sh` and have `qrencode` installed, the script displays a QR code when you add a client. Scan it with the WireGuard mobile app for instant setup -- no file transfer needed.

---

## Part 7: Verify and Test

After connecting, verify that your VPN is working.

### Check Your IP

Go to [whatismyip.com](https://www.whatismyip.com/). Your IP should show the VPN server's IP, not your real one.

### DNS Leak Test

Go to [dnsleaktest.com](https://www.dnsleaktest.com/) and run the extended test. All DNS servers should belong to your VPN provider or your server's DNS, not your ISP.

### Speed Test

Go to [fast.com](https://fast.com/) to check your connection speed through the VPN.

### Check Connected Clients (Server Side)

```bash
sudo wg show
```

This shows all connected peers, their last handshake time, and data transferred.

### Using the Launch Script

Run `bash rocket-shield.sh` and select option **4) Status & Diagnostics**. It shows:
- System info (OS, architecture, memory, uptime)
- Local and public IP
- Web server status
- WireGuard and OpenVPN status
- DNS leak check (compares your public IP with what Cloudflare sees)
- Dependency check

---

## Quick Reference

| Task | Command / Action |
|------|-----------------|
| Run web app | Double-click `index.html` or `bash rocket-shield.sh` > option 1 |
| Install WireGuard | `sudo apt install wireguard` or launch script option 2 |
| Connect as client | `sudo wg-quick up <config-name>` |
| Set up server | `bash rocket-shield.sh` > option 3 > sub-option 1 |
| Add client to server | `bash rocket-shield.sh` > option 3 > sub-option 3 |
| Check status | `sudo wg show` or launch script option 4 |
| Stop everything | `bash rocket-shield.sh` > option 5 |
| Docker deployment | `docker-compose up -d` |
