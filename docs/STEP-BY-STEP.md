# Step-by-Step Guide — From Zero to Running VPN

This guide walks you through everything: choosing a VPN, running the educational web app, setting up a VPN client, hosting your own VPN server, and connecting remotely.

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

- **Any PC or laptop** — for running the web app and VPN client
- **Raspberry Pi 3B+, 4, or 5** — for hosting a lightweight VPN server
- **Minimum RAM**: 512 MB (Pi), 2 GB (desktop)

### Network

- Active internet connection
- Router access for port forwarding (if hosting a server)
- Know your local IP and how to access your router admin panel

---

## Part 1: Choose Your VPN Type

Before downloading anything, understand the 3 types of VPN available:

### Option A: Free VPN Apps

Good for trying out, with some limitations.

| Provider | Data Limit | Servers | Notes |
|----------|-----------|---------|-------|
| **ProtonVPN Free** | Unlimited | 3 countries | No ads, Swiss privacy, open source |
| **Windscribe Free** | 10 GB/month | 10 countries | Good speeds, generous |
| **hide.me Free** | 10 GB/month | 5 countries | No logs, reliable |
| **VPN Gate** | Unlimited | ~5,000 servers worldwide | Free academic project (Univ. of Tsukuba, Japan). OpenVPN, L2TP, SoftEther. No signup! [vpngate.net](https://www.vpngate.net/) |

> ⚠️ **Warning:** Avoid unknown free VPNs — many sell your data to advertisers! Stick to trusted names above.

### Option B: Paid VPN Apps

Full power, faster, more servers, better privacy.

| Provider | Price | Servers | Protocols | Standout Feature |
|----------|-------|---------|-----------|-----------------|
| **NordVPN** | ~$3/mo | 6,000+ in 60 countries | WireGuard (NordLynx) | Fastest, double VPN |
| **ProtonVPN Plus** | ~$5/mo | 3,000+ in 70 countries | WireGuard, OpenVPN | Swiss privacy, open source |
| **Mullvad** | €5/mo flat | 700+ in 40 countries | WireGuard, OpenVPN | No email needed, privacy champion |
| **Surfshark** | ~$2/mo | 3,200+ in 100 countries | WireGuard, OpenVPN | Unlimited devices |

**What to look for in a paid VPN:**
- ✅ No-log policy (independently audited)
- ✅ WireGuard protocol support
- ✅ Kill switch feature
- ✅ DNS leak protection
- ✅ Based in a privacy-friendly country

### Option C: Built-in VPNs (No Download Needed!)

Some browsers and operating systems have VPN features **built right in**:

#### 🔴 Opera Browser — FREE Built-in VPN

The easiest way to start. No account, no download, no payment.

1. Download [Opera](https://www.opera.com/) if you don't have it
2. Open Opera → **Settings** (Alt+P on Windows, ⌘+, on Mac)
3. Go to **Privacy & Security**
4. Toggle **"Enable VPN"** → ON
5. A blue **VPN** badge appears in the address bar
6. Click it to choose a region: Americas, Europe, or Asia

> **Limitation:** Only protects Opera browser traffic, not your whole device.

#### 🦁 Brave Browser — Brave VPN

- Subscription-based (~$10/month)
- Protects the **entire device**, not just the browser
- Built on WireGuard protocol
- Includes a firewall
- Download [Brave](https://brave.com/) → Settings → Brave VPN

#### 🦊 Mozilla VPN

- Separate app (not built into Firefox)
- ~$5/month, made by the Firefox team
- Uses WireGuard protocol
- Available on Windows, macOS, Linux, Android, iOS
- Download from [vpn.mozilla.org](https://vpn.mozilla.org/)

#### 🍎 iCloud Private Relay (Apple)

- Built into Safari on iPhone, iPad, and Mac
- Requires iCloud+ subscription ($0.99/month)
- **Not a full VPN** — hides your IP and encrypts Safari traffic only
- Two-hop architecture: Apple sees your IP but not your destination; the relay server sees your destination but not your IP
- Enable: Settings → [Your Name] → iCloud → Private Relay → ON

#### 🤖 Android Built-in VPN

No app needed — Android has VPN support in Settings:

1. Go to **Settings → Network & Internet → VPN**
2. Tap the **"+"** button
3. Enter: Name, Type (IKEv2, L2TP/IPSec, PPTP), Server address, Username, Password
4. Tap **Save** → Tap the VPN name → **Connect**

> You need server details from a VPN provider or your own server.

#### 📱 iOS Built-in VPN

iPhone and iPad also have built-in VPN support:

1. Go to **Settings → General → VPN & Device Management**
2. Tap **"Add VPN Configuration"**
3. Choose Type: **IKEv2**, IPSec, or L2TP
4. Enter: Description, Server, Remote ID, Username, Password
5. Tap **Done** → Toggle the VPN **ON**

#### Comparison Table

| Type | Free? | Scope | Install? | Example |
|------|-------|-------|----------|---------|
| Browser VPN | Yes | Browser only | No | Opera |
| VPN App (Free) | Yes | Full device | Yes | ProtonVPN Free |
| VPN App (Paid) | No | Full device | Yes | NordVPN |
| OS Built-in | Yes | Full device | No | Android/iOS Settings |
| Private Relay | iCloud+ | Safari only | No | Apple iCloud |

### Decision Helper

Not sure which to choose? Follow this path:

```
Want free & instant? → Opera VPN (browser only, no signup)
Want free & full device? → ProtonVPN Free (unlimited data)
Want free + many servers? → VPN Gate (5000 servers, academic, OpenVPN)
Want maximum speed & features? → NordVPN or Mullvad (paid)
Already have iCloud+? → Enable Private Relay (Safari only)
Have a Freebox/Pi? → Host your own! (see Parts 4-5)
```

### VPN Gate — Free Academic VPN (Special Mention)

[VPN Gate](https://www.vpngate.net/) is a unique free VPN service run by the University of Tsukuba in Japan as an academic research project. It's worth highlighting because:

- **~5,000 volunteer servers** in 50+ countries
- **Completely free** — no signup, no email, no payment
- **Supports OpenVPN** — works with Freebox Revolution VPN Client!
- **Multiple protocols**: OpenVPN, L2TP/IPsec, SoftEther, MS-SSTP
- **No app needed** — just download an OpenVPN config file and import

**How to use VPN Gate:**
1. Go to [vpngate.net](https://www.vpngate.net/)
2. Browse the server list — pick a country/server with good speed
3. Click **"OpenVPN Config File"** next to a server
4. Download the `.ovpn` file (choose UDP for speed, TCP for reliability)
5. Import into your VPN client:
   - **Freebox Revolution**: VPN Client → Add → Upload .ovpn → Username: `vpn` / Password: `vpn`
   - **Phone**: OpenVPN Connect app → import .ovpn → User: `vpn` / Pass: `vpn`
   - **PC**: OpenVPN Connect → import → credentials: `vpn` / `vpn`
   - **Linux**: `sudo openvpn --config vpngate.ovpn` (enter `vpn`/`vpn` when prompted)

**Credentials for all VPN Gate servers:**
- Username: `vpn`
- Password: `vpn`

> ⚠️ VPN Gate servers are volunteer-run — speeds vary, servers come and go. For consistent service, use ProtonVPN Free or a paid provider. VPN Gate is great for testing and learning!

---

## Part 2: Download & Install

### 📱 iPhone / iPad

1. Open the **App Store**
2. Search for **"WireGuard"** (by WireGuard Development Team) or your chosen VPN app (e.g., "NordVPN", "ProtonVPN")
3. Tap **Get** → Confirm with Face ID / Touch ID
4. Wait for download → Tap **Open**

### 🤖 Android

1. Open **Google Play Store**
2. Search for **"WireGuard"** or your chosen VPN app
3. Tap **Install** → Wait for download
4. Tap **Open**

### 💻 Windows

1. Go to [wireguard.com/install](https://www.wireguard.com/install/)
2. Click **"Download Windows Installer"**
3. Run the `.msi` file → Click **Next → Install → Finish**
4. WireGuard appears in your system tray

For OpenVPN: Download from [openvpn.net/client](https://openvpn.net/client/) → Run installer → Finish.

### 🍎 macOS

**App Store method:**
1. Open **App Store** → Search **"WireGuard"**
2. Click **Get** → Install

**Homebrew method (terminal):**
```bash
brew install wireguard-tools
```

For OpenVPN: Download from [openvpn.net/client](https://openvpn.net/client/) or `brew install openvpn`.

### 🐧 Linux (Ubuntu/Debian)

```bash
# WireGuard
sudo apt update && sudo apt install wireguard

# OpenVPN
sudo apt install openvpn
```

Or use the launch script:
```bash
bash rocket-shield.sh
# Select option 2 → WireGuard or OpenVPN Client
# It will offer to install for you
```

### 🌐 Built-in Browser VPN (No Install!)

No download needed! Just:
1. Open **Opera** browser
2. Go to **Settings → Privacy & Security**
3. Toggle **"Enable VPN"** → ON
4. Done in 10 seconds!

---

## Part 3: Create Account & Connect

### Account Setup Tips

- 👨‍👩‍👧 Use a **parent's email** address for signup
- 🔐 Pick a **strong password** (long + unique, mix of letters/numbers/symbols)
- ⏭️ **Skip premium upsells** — for free VPNs, tap "Skip" or "Continue with Free"
- 🌐 **Built-in VPNs** (Opera, iCloud Relay): No account needed — just toggle ON!

### Connect to a Server

1. Open the VPN app
2. You'll see a **list of servers** (countries/cities)
3. Pick a server close to you for speed, or far away to access geo-blocked content
4. Tap/click **Connect**
5. Wait for the connection (usually 1-3 seconds with WireGuard)
6. You should see a **green indicator** or **"Connected"** status
7. A VPN icon (🔒 or key icon) appears in your status bar

### Built-in VPN Shortcut

For Opera: No account, no server picking — just toggle VPN ON in settings and choose a region (Americas, Europe, Asia). That's it!

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

The launch script handles this automatically:

```bash
bash rocket-shield.sh
# Select 3 > 1 (WireGuard Server)
```

It will:
- Install WireGuard if needed
- Generate keys
- Ask for your port (default: 51820) and public IP
- Create `/etc/wireguard/wg0.conf`

The generated config:

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

```bash
bash rocket-shield.sh
# Select 3 > 3 (Add Client Config)
# Enter a name (e.g., "phone", "laptop")
```

The script generates a `.conf` file in `./vpn-configs/` and shows a QR code for mobile devices.

---

## Part 5: Set Up VPN Server on Freebox

If you have a Freebox (French ISP "Free"), it has a built-in VPN server.

### Step 1: Access Freebox OS

1. Connect to your Freebox network (WiFi or Ethernet)
2. Open browser → go to `http://mafreebox.freebox.fr`
3. Log in with your Freebox admin password
4. Navigate to **Settings → VPN**

> ⚠️ First-time access requires physical confirmation on the Freebox LCD screen.

### Step 2: Enable VPN Server

Go to **VPN → VPN Server** and choose your protocol:
- **OpenVPN** — available on all Freebox models with VPN support
- **WireGuard** — available on newer models (One, Delta, Pop, Ultra)

### Step 3: Create a User

Click "Add a user" → Set a strong username and password.

### Step 4: Download Client Config

After creating the user, click the **download icon** to get the `.ovpn` or `.conf` file.

### Step 5: Connect from Outside

Import the downloaded config into your VPN client on your phone or laptop (see Part 6 below for detailed per-platform instructions).

See the [FREEBOX.md](FREEBOX.md) guide for complete details.

---

## Part 6: Connect Remotely

Once your VPN server is running, connect to it from anywhere.

### Step 1: Get Your Config File

- **From launch script**: Config files are saved in `./vpn-configs/` (e.g., `phone.conf`)
- **From Freebox**: Download from Freebox OS → VPN Server → Click your user → Download

### Step 2: Install the VPN App

| Platform | WireGuard App | OpenVPN App |
|----------|--------------|-------------|
| 📱 iPhone/iPad | App Store → search **"WireGuard"** (by WireGuard Development Team) | App Store → **"OpenVPN Connect"** |
| 🤖 Android | Play Store → search **"WireGuard"** | Play Store → **"OpenVPN Connect"** |
| 💻 macOS | [App Store](https://apps.apple.com/app/wireguard/id1451685025) or `brew install wireguard-tools` | [openvpn.net/client](https://openvpn.net/client/) |
| 💻 Windows | [wireguard.com/install](https://www.wireguard.com/install/) | [openvpn.net/client](https://openvpn.net/client/) |
| 🐧 Linux | `sudo apt install wireguard` | `sudo apt install openvpn` |

### Step 3a: Import WireGuard Config (.conf)

**📱 Phone (iOS/Android):**
1. Send the `.conf` file to your phone (email attachment, AirDrop, USB, cloud storage)
2. Tap the file → **"Open in WireGuard?"** → Tap **Yes**
3. Tap **"Allow"** to add the VPN tunnel
4. Alternative: Open WireGuard app → **"+"** → **"Create from file or archive"** → select file
5. QR method: WireGuard app → **"+"** → **"Create from QR code"** → scan the QR from the launch script

**💻 Windows:**
1. Open WireGuard app
2. Click **"Import tunnel(s) from file"**
3. Select your `.conf` file
4. The tunnel appears in the list
5. Click **"Activate"**

**🍎 macOS:**
1. Open WireGuard app
2. Click **"+"** → **"Import from file"**
3. Select your `.conf` file
4. Click **"Activate"**

**🐧 Linux:**
```bash
sudo cp your-config.conf /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf
sudo wg-quick up wg0

# Auto-start on boot:
sudo systemctl enable wg-quick@wg0
```

### Step 3b: Import OpenVPN Config (.ovpn)

**📱 iPhone/iPad:**
1. Send the `.ovpn` file to your phone
2. Tap the file → **"Open in OpenVPN Connect?"** → Tap **Yes**
3. Review the profile → Tap **"Add"**
4. Enter username/password if prompted
5. Tap the toggle to **connect**

**🤖 Android:**
1. Open OpenVPN Connect
2. Tap **"+"** → **"Upload File"**
3. Browse to your `.ovpn` file → Tap **"Import"**
4. Enter credentials if prompted
5. Tap **"Connect"**
6. Alternative: Tap the `.ovpn` file directly from your file manager

**💻 Windows:**
1. Open OpenVPN Connect
2. Click **"+"** → **"Upload File"**
3. Drag or browse to your `.ovpn` file
4. Click **"Connect"** → Enter credentials
5. **Note:** You may need to **Run as Administrator**

**🍎 macOS:**
1. Open OpenVPN Connect
2. Click **"+"** → **"Import from file"**
3. Select your `.ovpn` file
4. Enter credentials → Click **"Connect"**

**🐧 Linux:**
```bash
# Foreground (see output):
sudo openvpn --config your-config.ovpn

# Background (daemon):
sudo openvpn --config your-config.ovpn --daemon

# Auto-start on boot:
sudo cp your-config.ovpn /etc/openvpn/client.conf
sudo systemctl enable openvpn@client
```

### Step 4: Connect!

Open the VPN app → Tap/click the **toggle switch** next to your tunnel name → It turns **green** = connected!

When you're away from home, just toggle ON to securely access your home network.

---

## Part 7: Verify and Test

After connecting, verify that your VPN is working with these 5 checks:

### ✅ Check 1: IP Address Changed

Go to [whatismyip.com](https://www.whatismyip.com/). Your IP should show the VPN server's IP, not your real one.

**What changes:**
```
Before VPN: 203.0.113.42 (your real IP, your city)
After VPN:  10.8.0.1 (VPN server IP, server's city)
```

### ✅ Check 2: Location Changed

Connect to a server in another country (e.g., Japan). Visit [whatismyip.com](https://www.whatismyip.com/) — it should show Japan as your location.

### ✅ Check 3: Speed Test

Go to [fast.com](https://fast.com/) to check your speed through the VPN. A small drop (5-10% for WireGuard, 15-30% for OpenVPN) is normal.

### ✅ Check 4: DNS Leak Test

Go to [dnsleaktest.com](https://www.dnsleaktest.com/) → Click **"Extended Test"**. All DNS servers should belong to your VPN provider or your configured DNS (1.1.1.1, 8.8.8.8), **not** your ISP.

### ✅ Check 5: Geo-blocked Content

Try accessing content that's restricted to the VPN server's country. If it works, your VPN is functioning correctly!

### Server-Side Check

```bash
sudo wg show
```

This shows all connected peers, their last handshake time, and data transferred.

### Using the Launch Script

```bash
bash rocket-shield.sh
# Select option 4) Status & Diagnostics
```

It shows:
- System info (OS, architecture, memory, uptime)
- Local and public IP
- Web server status
- WireGuard and OpenVPN status
- DNS leak check (compares your public IP with what Cloudflare sees)
- Dependency check

---

## What's Next?

Now that you're protected, consider these next steps:

| Next Step | How |
|-----------|-----|
| 📦 Protect all home devices | Set up VPN on your Freebox router — see [FREEBOX.md](FREEBOX.md) |
| 🍓 Host your own server | Deploy on Raspberry Pi — see [RASPBERRY-PI.md](RASPBERRY-PI.md) |
| 🐳 Containerize everything | Use Docker — see [DOCKER.md](DOCKER.md) |
| 🧠 Learn more | Explore the Academy section in the web app |
| 📚 Deep dive | Read the [WIREGUARD.md](WIREGUARD.md) and [OPENVPN.md](OPENVPN.md) references |

---

## Quick Tips

- 🔋 **Disconnect VPN when not needed** — saves battery on phones
- 🛡️ **VPN doesn't make you invincible** — still avoid suspicious links and phishing!
- 🔄 **Keep your VPN app updated** for the latest security fixes
- 📱 **Use WireGuard on mobile** — it's faster and uses less battery than OpenVPN
- 🔑 **Rotate keys periodically** if hosting your own server

---

## Quick Reference

| Task | Command / Action |
|------|-----------------|
| Run web app | Double-click `index.html` or `bash rocket-shield.sh` → option 1 |
| Install WireGuard | `sudo apt install wireguard` or launch script option 2 |
| Connect as client | `sudo wg-quick up <config-name>` |
| Set up server | `bash rocket-shield.sh` → option 3 → WireGuard Server |
| Add client to server | `bash rocket-shield.sh` → option 3 → Add Client |
| Check status | `sudo wg show` or launch script option 4 |
| Stop everything | `bash rocket-shield.sh` → option 5 |
| Docker deployment | `docker-compose up -d` |
| Opera VPN (instant) | Open Opera → Settings → Privacy → Enable VPN |
