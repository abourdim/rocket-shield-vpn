# Freebox WireGuard -- Complete Setup Guide (Delta / Pop / Ultra / One)

Configure WireGuard on your newer Freebox router. This guide covers both VPN Client mode (route home traffic through an external VPN) and VPN Server mode (access your home network remotely from anywhere). WireGuard is the modern, high-performance alternative to OpenVPN and is natively supported on Delta, Pop, Ultra, and One models running Freebox OS 4.x or later.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Accessing Freebox OS](#3-accessing-freebox-os)
4. [VPN Client Mode -- Route Home Traffic Through External VPN](#4-vpn-client-mode--route-home-traffic-through-external-vpn)
5. [VPN Server Mode -- Host WireGuard Server](#5-vpn-server-mode--host-wireguard-server)
6. [Connect from Phone (WireGuard)](#6-connect-from-phone-wireguard)
7. [Connect from Laptop (WireGuard)](#7-connect-from-laptop-wireguard)
8. [Performance Comparison](#8-performance-comparison)
9. [Advanced: Split Tunneling](#9-advanced-split-tunneling)
10. [Combining with Raspberry Pi](#10-combining-with-raspberry-pi)
11. [Troubleshooting (WireGuard-Specific)](#11-troubleshooting-wireguard-specific)
12. [Security Best Practices](#12-security-best-practices)
13. [Freebox OS Navigation (French to English)](#13-freebox-os-navigation-french-to-english)

---

## 1. Overview

### Which Models Support WireGuard

| Model | Freebox OS | WireGuard Client | WireGuard Server | OpenVPN Client | OpenVPN Server |
|---|:-:|:-:|:-:|:-:|:-:|
| Freebox One | 4.x+ | Yes | Yes | Yes | Yes |
| Freebox Delta | 4.x+ | Yes | Yes | Yes | Yes |
| Freebox Pop | 4.x+ | Yes | Yes | Yes | Yes |
| Freebox Ultra | 4.x+ | Yes | Yes | Yes | Yes |
| Freebox Revolution | 3.x / 4.x | No | No | Yes | Yes |
| Freebox Mini 4K | 3.x / 4.x | No | No | Yes | Yes |

WireGuard support was introduced in Freebox OS 4.x. If your Freebox is on an older firmware, update it first (see [Prerequisites](#2-prerequisites)).

### Why WireGuard Over OpenVPN

- **Faster connections**: WireGuard establishes tunnels in under 100ms compared to 5-10 seconds for OpenVPN.
- **Higher throughput**: Less overhead means more of your bandwidth is usable.
- **Lower battery drain**: On phones, WireGuard uses significantly less CPU, extending battery life.
- **Simpler configuration**: A WireGuard config is typically 10-15 lines versus 50-100+ lines for OpenVPN.
- **Modern cryptography**: ChaCha20 for encryption, Poly1305 for authentication, Curve25519 for key exchange, BLAKE2s for hashing.
- **Smaller attack surface**: The entire WireGuard codebase is roughly 4,000 lines of code versus over 100,000 for OpenVPN.
- **Instant reconnect**: When switching between Wi-Fi and mobile data, WireGuard reconnects seamlessly without dropping the tunnel.

### Modes of Operation

- **VPN Client**: The Freebox connects to an external VPN provider (NordVPN, ProtonVPN, Mullvad, etc.). All devices on your home network are automatically protected without installing anything on each device.
- **VPN Server**: The Freebox acts as a WireGuard server. You connect to your home network from outside (phone on 4G/5G, laptop at a coffee shop, etc.) to access home devices securely.

### Performance Comparison at a Glance

| Metric | WireGuard | OpenVPN |
|---|---|---|
| Connection time | < 100 ms | 5-10 seconds |
| Throughput (typical on Freebox Delta) | 800-950 Mbps | 200-400 Mbps |
| CPU usage | Very low | Moderate to high |
| Battery drain (mobile, 1 hour active) | ~2-3% | ~8-12% |
| Reconnect after sleep/network change | Instant (< 1s) | 10-30 seconds |
| Config file size | 10-15 lines | 50-100+ lines |
| Codebase size | ~4,000 lines | ~100,000+ lines |
| Protocol | UDP only | UDP or TCP |
| Encryption | ChaCha20-Poly1305 | AES-256-GCM (typical) |

---

## 2. Prerequisites

Before you begin, make sure you have:

1. **A compatible Freebox model**: One, Delta, Pop, or Ultra. The Revolution and Mini 4K do not support WireGuard.
2. **Freebox OS 4.x or later**: Check your version at `http://mafreebox.freebox.fr` after logging in. If you are on an older version, go to **Parametres de la Freebox > Mise a jour du Freebox OS** and update.
3. **Admin password**: You set this the first time you accessed Freebox OS. If you have forgotten it, you can reset it by pressing and holding the reset button on the Freebox for 15 seconds (this resets the admin password only, not your configuration).
4. **A device on the Freebox network**: You must be connected to the Freebox (Ethernet or Wi-Fi) to access the admin interface.
5. **For VPN Client mode**: A subscription to a VPN provider that supports WireGuard (NordVPN, ProtonVPN, Mullvad, Surfshark, IVPN, etc.).
6. **For VPN Server mode**: A public IP address. If your Freebox is behind CGNAT (some newer fiber installations), VPN Server mode will not work. You can check by comparing the WAN IP shown in Freebox OS with the IP shown at `https://whatismyip.com`.

---

## 3. Accessing Freebox OS

### Step-by-Step

1. Open any web browser on a device connected to your Freebox network.
2. Navigate to:
   ```
   http://mafreebox.freebox.fr
   ```
   Or use the IP address directly:
   ```
   http://192.168.1.254
   ```
3. Enter your admin password and click **Connexion**.
4. You will see the Freebox OS home screen with various application tiles.

### Navigating to VPN Settings

On the newer Freebox models (Delta, Pop, Ultra, One), the interface is slightly different from the Revolution:

1. Click **Parametres de la Freebox** (the gear icon, or "Freebox Settings").
2. In the left sidebar, you will see two VPN-related sections:
   - **Client VPN** -- for routing your home traffic through an external VPN provider.
   - **Serveur VPN** -- for hosting your own VPN server on the Freebox.
3. On Freebox OS 4.x, the VPN section may also show a **WireGuard** tab alongside the **OpenVPN** tab. Click the appropriate tab for the protocol you want to configure.

> **Note**: The exact layout may vary slightly between firmware versions. If you do not see a WireGuard option, update your Freebox OS first.

---

## 4. VPN Client Mode -- Route Home Traffic Through External VPN

VPN Client mode routes all traffic from every device on your home network through an external VPN provider. This means your Smart TV, gaming console, IoT devices, and every phone and laptop on the network are protected without installing any software.

### 4.1 Get WireGuard Config from Your Provider

Each VPN provider has a slightly different process for generating a WireGuard configuration file. Below are detailed instructions for the most popular providers.

#### NordVPN (NordLynx)

1. Log in to your NordVPN account at `https://my.nordaccount.com`.
2. Go to **NordVPN** in the left sidebar.
3. Click **Manual Setup** or **Set up NordVPN manually**.
4. Select the **WireGuard** tab (NordVPN calls their WireGuard implementation "NordLynx").
5. Click **Generate new key pair**. NordVPN will generate a private key and show you the corresponding public key.
6. **Important**: Copy and save the private key immediately. NordVPN will not show it again.
7. Select a server (e.g., France #123, Netherlands #456).
8. Download the `.conf` file, or note the server hostname, public key, and endpoint information displayed.

The config will look something like this:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = 10.5.0.2/16
DNS = 103.86.96.100

[Peer]
PublicKey = SERVER_PUBLIC_KEY_HERE
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = fr123.nordvpn.com:51820
```

#### ProtonVPN

1. Log in at `https://account.protonvpn.com`.
2. Go to **Downloads** in the left sidebar.
3. Scroll to **WireGuard configuration**.
4. Select your desired settings:
   - **Platform**: Router / other.
   - **Server**: Choose a country and specific server.
   - **NAT/Moderate NAT**: Keep default unless you have a specific reason to change.
5. Click **Create** or **Generate**.
6. Download the `.conf` file.

#### Mullvad

1. Log in at `https://mullvad.net/en/account`.
2. Go to **WireGuard configuration** (under "Manage devices and ports").
3. Click **Generate key** if you have not already.
4. Select:
   - **Country and city** for the exit server.
   - **Tunnel traffic**: IPv4 (or IPv4+IPv6 if needed).
   - **Port**: 51820 (default) or a custom port.
5. Click **Download file**.
6. Mullvad also provides a direct link to a `.conf` file.

#### Surfshark

1. Log in at `https://my.surfshark.com`.
2. Go to **VPN** > **Manual Setup** > **Router** > **WireGuard**.
3. Click **Generate new key pair**.
4. Copy or download the private key.
5. Select a server location.
6. Download the `.conf` file, or copy the configuration details.

#### IVPN

1. Log in at `https://www.ivpn.net/clientarea/`.
2. Go to **WireGuard** in the sidebar.
3. Click **Generate Key** to create a key pair.
4. Select a server location.
5. Click **Generate QR code** or **Download config file**.

### 4.2 Import WireGuard Config into Freebox

1. In Freebox OS, go to **Parametres de la Freebox** > **Client VPN**.
2. Click the **WireGuard** tab (if you see tabs for OpenVPN and WireGuard).
3. Click **Ajouter une connexion** (Add a connection).
4. Fill in the fields:
   - **Description** (or **Nom**): A descriptive name such as "NordVPN France" or "ProtonVPN Netherlands".
   - **Type de serveur**: Select **WireGuard**.
5. You have two import options:

   **Option A: Upload the .conf file** (easiest)
   - Click the upload/import button (it may say **Importer un fichier** or show a file icon).
   - Select the `.conf` file you downloaded from your provider.
   - The Freebox will auto-fill all fields from the file.

   **Option B: Manual entry** (if upload does not work or your provider only gives raw values)
   - **Cle privee (Private Key)**: Paste your WireGuard private key (a Base64 string, 44 characters ending in `=`).
   - **Adresse IP**: The tunnel address from the config (e.g., `10.5.0.2/16`).
   - **DNS**: The DNS server from the config (e.g., `103.86.96.100` or `1.1.1.1`).
   - Under the **Peer** section:
     - **Cle publique (Public Key)**: The server's public key.
     - **Point de terminaison (Endpoint)**: The server address and port (e.g., `fr123.nordvpn.com:51820`).
     - **IP autorisees (Allowed IPs)**: `0.0.0.0/0, ::/0` for full tunnel (all traffic routed through VPN).
     - **Cle pre-partagee (Pre-shared Key)**: Leave empty unless your provider specifies one.
     - **Keepalive**: `25` seconds (recommended to maintain the connection through NAT).

6. Click **Sauvegarder** (Save).

### 4.3 Activate and Verify

1. Back on the VPN Client list, you will see your new WireGuard connection listed.
2. Toggle the switch to **ON** (or click **Activer** / **Demarrer**).
3. Wait a few seconds. The status should change to **Connecte** (Connected).
4. If the status shows **Connecte** with a green indicator, the VPN tunnel is active.

**Verify the connection**:

1. On any device connected to your Freebox, open a browser.
2. Go to `https://whatismyip.com` or `https://ipleak.net`.
3. Your IP address should now show the VPN server's location (e.g., a Netherlands IP if you connected to a Netherlands server).
4. If your real IP appears instead, see [Troubleshooting](#11-troubleshooting-wireguard-specific).

**Speed test**:

1. Go to `https://speedtest.net` and run a test.
2. WireGuard should yield significantly higher speeds than OpenVPN on the same server.
3. On a Freebox Delta with 1 Gbps fiber, expect 800-950 Mbps through WireGuard versus 200-400 Mbps through OpenVPN.

---

## 5. VPN Server Mode -- Host WireGuard Server

VPN Server mode turns your Freebox into a WireGuard server. You can then connect to your home network from anywhere -- your phone on 4G, your laptop at a hotel, etc. You get secure access to your home NAS, printers, cameras, and other devices, and you can optionally route all your internet traffic through your home connection.

### 5.1 Enable WireGuard Server

1. In Freebox OS, go to **Parametres de la Freebox** > **Serveur VPN**.
2. Click the **WireGuard** tab.
3. Toggle the WireGuard server to **Actif** (Enabled).
4. Configure the server settings:
   - **Port d'ecoute (Listening Port)**: Default is `51820`. Change only if this port is blocked by your ISP or conflicts with something else. Common alternatives: `51821`, `41194`.
   - **Sous-reseau (Subnet)**: Default is `10.66.66.0/24`. This is the internal VPN subnet. Change only if it conflicts with your existing LAN (e.g., if your LAN already uses `10.66.66.x`).
   - **DNS**: The DNS server clients will use. Options:
     - `192.168.1.254` -- Use the Freebox itself as DNS (recommended if you use Freebox DNS features).
     - `1.1.1.1` -- Cloudflare DNS (fast, privacy-focused).
     - `8.8.8.8` -- Google DNS.
     - `9.9.9.9` -- Quad9 DNS (security-focused, blocks malware domains).
5. Click **Appliquer** (Apply) or **Sauvegarder** (Save).

### 5.2 Create Peers (Clients)

Each device that will connect to your Freebox's WireGuard server needs its own peer entry.

1. In the WireGuard server configuration, click **Ajouter un pair** (Add peer) or the "+" button.
2. Enter a **Nom** (Name): Use a descriptive name like "iPhone-Abdelhak", "Laptop-Work", or "Tablet-Living-Room".
3. The Freebox will automatically generate:
   - **Cle publique du serveur (Server Public Key)**: The Freebox's WireGuard public key (shared with all peers).
   - **Cle privee du client (Client Private Key)**: A private key for this specific peer.
   - **Cle publique du client (Client Public Key)**: The corresponding public key.
   - **Cle pre-partagee (Pre-shared Key)**: An optional extra key for post-quantum security. Enable this for maximum security.
4. Configure the peer's **IP autorisees (Allowed IPs)**:
   - `0.0.0.0/0, ::/0` -- Route ALL traffic through home (full tunnel). This means all internet traffic from the device goes through your Freebox. Use this when you want to browse as if you were at home.
   - `192.168.1.0/24, 10.66.66.0/24` -- Route only home network and VPN subnet traffic (split tunnel). Internet traffic goes directly through the device's local connection. Use this when you only need to access home devices.
5. Click **Sauvegarder** (Save).
6. Repeat for each device you want to connect.

### 5.3 Download/Export Client Config

After creating a peer, you need to get the configuration onto the client device.

1. In the peer list, find the peer you just created.
2. You have two export options:

   **Option A: Download .conf file**
   - Click the download icon (arrow pointing down) next to the peer name.
   - Save the `.conf` file.
   - Transfer it to the client device via email, AirDrop, USB, or cloud storage.
   - **Important**: This file contains the private key. Do not share it publicly or leave it in an unprotected location.

   **Option B: QR code** (recommended for phones)
   - Click the QR code icon next to the peer name.
   - A QR code will appear on screen.
   - On your phone, open the WireGuard app and scan this QR code (see [Section 6](#6-connect-from-phone-wireguard)).
   - This is the fastest and most secure method for phones since the config never touches an intermediate file.

### 5.4 Port Forwarding

WireGuard needs UDP traffic on its listening port to reach the Freebox from the internet.

**On newer Freebox models (Delta, Pop, Ultra), port forwarding is typically automatic when you enable the WireGuard server.** The Freebox opens the port on its firewall automatically.

To verify or set it manually:

1. Go to **Parametres de la Freebox** > **Gestion des ports** (Port Management) or **Redirections de ports** (Port Redirections).
2. Check that an entry exists for:
   - **Port externe (External Port)**: 51820 (or whatever port you chose)
   - **Protocole**: UDP
   - **IP de destination**: 0.0.0.0 or the Freebox's own address
   - **Port interne (Internal Port)**: 51820
3. If the entry does not exist, click **Ajouter une redirection** (Add a redirect) and create it.
4. Make sure the Freebox firewall is not blocking UDP 51820. Check under **Parametres de la Freebox** > **Mode avance** > **Pare-feu** (Firewall).

### 5.5 Dynamic DNS

Your home IP address may change periodically (most Free fiber connections have a relatively stable IP, but it can change after a Freebox reboot or a network event).

**Free's built-in Dynamic DNS**:

Free provides a free dynamic DNS hostname for every Freebox. It typically follows the format:

```
YOUR_LOGIN.freeboxos.fr
```

To find or enable it:

1. Go to **Parametres de la Freebox** > **Nom de domaine** (Domain Name) or **DynDNS**.
2. If a hostname is already assigned, note it down and use it as your WireGuard endpoint instead of a raw IP.
3. If not, you can enable it or use a third-party DynDNS service:
   - **No-IP** (`https://www.noip.com`) -- Free tier available.
   - **DuckDNS** (`https://www.duckdns.org`) -- Completely free.
   - **Dynu** (`https://www.dynu.com`) -- Free tier available.

To use a third-party DynDNS:

1. Go to **Parametres de la Freebox** > **DynDNS**.
2. Click **Ajouter** (Add).
3. Select your provider from the dropdown (or choose **Personnalise** / Custom).
4. Enter your DynDNS hostname, username, and password.
5. Click **Sauvegarder** (Save). The Freebox will automatically update the hostname whenever your IP changes.

Then, in your WireGuard client config, use the DynDNS hostname as the endpoint:

```ini
Endpoint = YOUR_LOGIN.freeboxos.fr:51820
```

---

## 6. Connect from Phone (WireGuard)

### 6.1 iPhone / iPad

1. Open the **App Store**.
2. Search for **WireGuard** (by WireGuard Development Team / Jason A. Donenfeld).
3. Tap **Get** to install.
4. Open the WireGuard app.
5. Tap the **+** button in the top-right corner. You will see three options:

   **Method A: QR Code (easiest and recommended)**
   1. Tap **Create from QR code**.
   2. Allow camera access if prompted.
   3. Point the camera at the QR code displayed in Freebox OS (see [Section 5.3](#53-downloadexport-client-config)).
   4. Enter a name for the tunnel (e.g., "Freebox Home").
   5. Tap **Allow** when iOS asks to add a VPN configuration.
   6. The tunnel appears in the list.

   **Method B: File import**
   1. Tap **Create from file or archive**.
   2. Browse to the `.conf` file in Files, or open it from an email attachment or AirDrop.
   3. The tunnel is added automatically.
   4. Tap **Allow** when iOS asks to add a VPN configuration.

   **Method C: Manual entry**
   1. Tap **Create from scratch**.
   2. Enter a **Name** for the tunnel.
   3. Under **Interface**:
      - Tap **Generate keypair** (or paste the private key from the config).
      - **Addresses**: Enter the tunnel address (e.g., `10.66.66.2/32`).
      - **DNS servers**: Enter the DNS from the config (e.g., `1.1.1.1`).
   4. Under **Peer**:
      - **Public key**: Enter the Freebox server's public key.
      - **Pre-shared key**: Enter if configured.
      - **Endpoint**: Enter your Freebox's public IP or DynDNS hostname and port (e.g., `YOUR_LOGIN.freeboxos.fr:51820`).
      - **Allowed IPs**: `0.0.0.0/0, ::/0` for full tunnel, or specific subnets for split tunnel.
      - **Persistent keepalive**: `25`.
   5. Tap **Save**.

6. To connect: Tap the toggle switch next to the tunnel name.
7. The status will show **Active** with:
   - Latest handshake timestamp.
   - Data transferred (received and sent).
8. A **VPN** icon appears in the iOS status bar.
9. To disconnect: Tap the toggle switch again.

**On-demand activation** (optional):

1. Tap the tunnel name to edit it.
2. Scroll down to **On-Demand Activation**.
3. You can set WireGuard to automatically activate:
   - On mobile data (cellular).
   - On any Wi-Fi except your home network.
   - On specific SSIDs.
4. This is useful to always be protected when away from home but not double-tunnel when on your own Freebox Wi-Fi.

### 6.2 Android

1. Open the **Play Store** (or F-Droid for the open-source build).
2. Search for **WireGuard**.
3. Tap **Install**.
4. Open the WireGuard app.
5. Tap the **+** (floating action button) in the bottom-right corner. You will see three options:

   **Method A: QR Code**
   1. Tap **Scan from QR code**.
   2. Allow camera access if prompted.
   3. Point the camera at the QR code from Freebox OS.
   4. Enter a tunnel name.
   5. The tunnel is added.

   **Method B: File import**
   1. Tap **Import from file or archive**.
   2. Browse to the `.conf` file using the file picker.
   3. The tunnel is imported automatically.

   **Method C: Manual entry**
   1. Tap **Create from scratch**.
   2. Fill in the same fields as described in the iPhone manual entry section above.
   3. Tap the save icon (floppy disk).

6. To connect: Tap the toggle switch next to the tunnel name.
7. Android will show a dialog: "Connection request -- WireGuard wants to set up a VPN connection". Tap **OK**.
8. A **key icon** appears in the Android status bar, indicating the VPN is active.
9. To disconnect: Tap the toggle switch again.

---

## 7. Connect from Laptop (WireGuard)

### 7.1 Windows

1. Download the WireGuard installer from `https://www.wireguard.com/install/`.
2. Run the installer. Administrator privileges are required.
3. Open **WireGuard** from the Start Menu.
4. Click **Import tunnel(s) from file** (or press `Ctrl+O`).
5. Select the `.conf` file you exported from the Freebox.
6. The tunnel appears in the left sidebar with its name.
7. Select the tunnel and click **Activate**.
8. The status will show:
   - **Status**: Active (green indicator).
   - **Public key**: The peer's public key.
   - **Transfer**: Bytes received and sent.
   - **Latest handshake**: Timestamp of last successful handshake.
9. To disconnect: Click **Deactivate**.

**Verify the connection**:

1. Open a browser and go to `https://whatismyip.com`.
2. You should see your Freebox's home IP address (for VPN Server mode) or the external VPN provider's IP (for VPN Client mode).
3. Try accessing a home device by its local IP (e.g., `http://192.168.1.100` for a NAS).

### 7.2 macOS

1. Open the **App Store**.
2. Search for **WireGuard** and install it.
3. Open WireGuard.
4. Click the **+** button in the bottom-left corner.
5. Select **Import tunnel(s) from file**.
6. Choose the `.conf` file.
7. macOS will ask you to **Allow** the VPN configuration. Authenticate with Touch ID or your password.
8. Click **Activate** to connect.
9. A WireGuard icon appears in the menu bar showing the connection status.
10. To disconnect: Click **Deactivate** or use the menu bar icon.

### 7.3 Linux

#### Install WireGuard

**Debian / Ubuntu**:

```bash
sudo apt update
sudo apt install wireguard wireguard-tools
```

**Fedora**:

```bash
sudo dnf install wireguard-tools
```

**Arch Linux**:

```bash
sudo pacman -S wireguard-tools
```

#### Set Up the Tunnel

```bash
# Copy the config file to the WireGuard directory
sudo cp /path/to/freebox-peer.conf /etc/wireguard/freebox.conf

# Secure the file permissions (private key inside)
sudo chmod 600 /etc/wireguard/freebox.conf

# Bring up the tunnel
sudo wg-quick up freebox
```

#### Verify the Connection

```bash
# Show WireGuard interface status
sudo wg show

# Check your public IP (should be Freebox home IP or VPN provider IP)
curl https://ifconfig.me

# Check connectivity to home network
ping 192.168.1.254
```

Expected output from `sudo wg show`:

```
interface: freebox
  public key: YOUR_CLIENT_PUBLIC_KEY
  private key: (hidden)
  listening port: 43210

peer: FREEBOX_SERVER_PUBLIC_KEY
  endpoint: YOUR_PUBLIC_IP:51820
  allowed ips: 0.0.0.0/0, ::/0
  latest handshake: 12 seconds ago
  transfer: 1.24 MiB received, 0.56 MiB sent
  persistent keepalive: every 25 seconds
```

#### Disconnect

```bash
sudo wg-quick down freebox
```

#### Auto-Start on Boot

```bash
# Enable the WireGuard service to start at boot
sudo systemctl enable wg-quick@freebox

# Start it now without rebooting
sudo systemctl start wg-quick@freebox

# Check status
sudo systemctl status wg-quick@freebox
```

#### Manage with systemd

```bash
# Stop the tunnel
sudo systemctl stop wg-quick@freebox

# Disable auto-start
sudo systemctl disable wg-quick@freebox

# Restart (useful after config changes)
sudo systemctl restart wg-quick@freebox
```

---

## 8. Performance Comparison

Tested on a Freebox Delta with 1 Gbps FTTH (fiber to the home) connection. Results may vary depending on your model, firmware version, and distance to the VPN server.

| Metric | WireGuard | OpenVPN (UDP) | OpenVPN (TCP) |
|---|---|---|---|
| Connection time | < 100 ms | 5-8 seconds | 8-15 seconds |
| Download throughput | 800-950 Mbps | 250-400 Mbps | 150-300 Mbps |
| Upload throughput | 400-500 Mbps | 150-250 Mbps | 100-200 Mbps |
| Latency overhead | +1-2 ms | +5-15 ms | +10-30 ms |
| CPU usage (Freebox) | ~5-10% | ~30-50% | ~40-60% |
| Battery drain (iPhone, 1h active use) | ~2-3% | ~8-12% | ~10-15% |
| Reconnect after Wi-Fi/sleep | < 1 second | 10-30 seconds | 15-45 seconds |
| Config file size | ~10-15 lines | ~50-100+ lines | ~50-100+ lines |
| Codebase size | ~4,000 lines | ~100,000+ lines | ~100,000+ lines |
| NAT traversal | Built-in | Requires config | Requires config |
| Protocol | UDP only | UDP | TCP |
| Encryption | ChaCha20-Poly1305 | AES-256-GCM | AES-256-GCM |
| Key exchange | Curve25519 | RSA / ECDH | RSA / ECDH |

**Key takeaway**: WireGuard delivers 2-3x higher throughput with dramatically lower latency and CPU usage. The difference is most noticeable on mobile devices where battery life and reconnection speed matter the most.

---

## 9. Advanced: Split Tunneling

By default, setting `AllowedIPs = 0.0.0.0/0, ::/0` routes ALL traffic through the VPN (full tunnel). This is secure but can be slower for general browsing since everything goes through the tunnel.

**Split tunneling** lets you route only specific traffic through the VPN while everything else goes directly through your local internet connection.

### When to Use Split Tunneling

- You want to access your home NAS or cameras remotely but do not want all your YouTube/Netflix traffic going through the tunnel.
- You want low-latency gaming on local internet but need access to home devices.
- Your home upload speed is limited and you do not want to bottleneck your browsing.

### How to Configure

In the WireGuard client config (`.conf` file), change the `AllowedIPs` line under `[Peer]`:

**Full tunnel** (default -- all traffic through VPN):

```ini
[Peer]
AllowedIPs = 0.0.0.0/0, ::/0
```

**Split tunnel -- home network only**:

```ini
[Peer]
AllowedIPs = 192.168.1.0/24, 10.66.66.0/24
```

This routes only traffic destined for `192.168.1.x` (your home LAN) and `10.66.66.x` (the WireGuard subnet) through the tunnel. All other traffic (web browsing, streaming, etc.) goes directly through your local connection.

**Split tunnel -- home network + specific services**:

```ini
[Peer]
AllowedIPs = 192.168.1.0/24, 10.66.66.0/24, 10.0.0.0/8
```

This adds the entire `10.x.x.x` range, useful if you have multiple subnets at home.

### Practical Example

You are at a coffee shop with your laptop. You want to:
- Access your Synology NAS at `192.168.1.50` to grab some files.
- Browse the web normally using the coffee shop's fast Wi-Fi.

Your config would be:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.66.66.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = FREEBOX_SERVER_PUBLIC_KEY
Endpoint = YOUR_LOGIN.freeboxos.fr:51820
AllowedIPs = 192.168.1.0/24, 10.66.66.0/24
PersistentKeepalive = 25
```

With this config:
- `http://192.168.1.50:5000` (Synology DSM) goes through the VPN tunnel to your home.
- `https://youtube.com` goes directly through the coffee shop's internet.

### DNS Considerations for Split Tunnel

When using split tunneling, DNS can be tricky:

- If you set `DNS = 192.168.1.254` (Freebox), DNS queries go through the tunnel to your Freebox. This is fine but means DNS queries are slower than using a public DNS directly.
- If you set `DNS = 1.1.1.1`, DNS queries go directly through your local connection. This is faster but means your home device hostnames (if you use Freebox's local DNS) will not resolve.
- **Recommendation**: For split tunnel, use a public DNS like `1.1.1.1` and access home devices by IP address rather than hostname.

---

## 10. Combining with Raspberry Pi

You can use both the Freebox's built-in WireGuard server and a Raspberry Pi on the same network for additional flexibility.

### Why Use a Pi Alongside the Freebox

- **Pi-hole ad blocking**: Run Pi-hole on the Pi and set it as the DNS for your WireGuard clients. All DNS queries from your VPN-connected devices go through Pi-hole, blocking ads and trackers even when you are away from home.
- **Custom DNS**: Run Unbound on the Pi for recursive DNS resolution, eliminating reliance on third-party DNS providers.
- **More control**: The Pi gives you full Linux command-line control over WireGuard configuration, including advanced firewall rules, multiple interfaces, and custom routing.
- **Backup VPN server**: If the Freebox WireGuard server has issues after a firmware update, the Pi can serve as a fallback.

### Architecture

```
Internet
    |
[Freebox Router] --- WireGuard Server (port 51820)
    |         \
    |          --- Port forward 51821/UDP -> Pi
    |
[Home LAN: 192.168.1.0/24]
    |
[Raspberry Pi: 192.168.1.100] --- WireGuard Server (port 51821)
    |
[Pi-hole DNS: 192.168.1.100:53]
```

### Setup Steps

1. **Set up the Pi as a WireGuard server** (see the [Raspberry Pi guide](RASPBERRY-PI.md) for detailed instructions).
2. **Configure the Freebox to forward port 51821/UDP to the Pi**:
   - Go to **Parametres de la Freebox** > **Gestion des ports**.
   - Add a new redirect:
     - Protocol: UDP
     - External port: 51821
     - Internal IP: 192.168.1.100 (Pi's IP)
     - Internal port: 51821
   - Save.
3. **On the Pi, install Pi-hole** (optional but recommended):
   ```bash
   curl -sSL https://install.pi-hole.net | bash
   ```
4. **Set the Pi's WireGuard server DNS to Pi-hole**:
   In the Pi's WireGuard server config, set:
   ```ini
   DNS = 192.168.1.100
   ```
5. **Connect your devices to the Pi's WireGuard server** (on port 51821) instead of the Freebox's server (port 51820).

### When to Use Which

| Scenario | Use Freebox WireGuard | Use Pi WireGuard |
|---|:-:|:-:|
| Quick remote access to home | Yes | -- |
| Ad-blocking via Pi-hole while remote | -- | Yes |
| Maximum simplicity (no extra hardware) | Yes | -- |
| Full control over VPN config | -- | Yes |
| Backup if Freebox firmware breaks VPN | -- | Yes |
| Multiple VPN interfaces/configs | -- | Yes |

---

## 11. Troubleshooting (WireGuard-Specific)

| Problem | Likely Cause | Solution |
|---|---|---|
| Handshake never completes | Port 51820/UDP is blocked or not forwarded | Verify port forwarding in Freebox settings. Check that your ISP does not block UDP 51820. Try a different port. |
| Handshake never completes (client mode) | Wrong server public key or endpoint | Double-check the public key and endpoint in the config match exactly what the VPN provider gave you. Keys are case-sensitive and Base64-encoded. |
| Connected but no internet | DNS misconfigured or AllowedIPs incorrect | Make sure `DNS` is set to a working server (try `1.1.1.1`). Ensure `AllowedIPs` includes `0.0.0.0/0` for full tunnel. |
| DNS not resolving (sites do not load but ping by IP works) | DNS server unreachable or wrong | Change DNS in the WireGuard config to `1.1.1.1` or `8.8.8.8`. If using split tunnel, make sure DNS queries are routed through the tunnel. |
| Cannot access Freebox from outside (VPN Server mode) | Public IP changed or CGNAT | Check your public IP at `whatismyip.com` and compare with the endpoint in the config. If behind CGNAT (IP starts with 100.64.x.x), contact Free support to request a full public IP. Set up DynDNS. |
| QR code will not scan | Screen glare, code too small, or camera issue | Increase screen brightness. Zoom in on the QR code in Freebox OS (use browser zoom). Clean the phone camera lens. Try importing the `.conf` file instead. |
| Peer not showing in Freebox OS | Peer was not saved or firmware bug | Click "Add peer" again and re-create. Make sure you clicked "Sauvegarder" (Save). Try refreshing the Freebox OS page (F5). |
| Connection drops after idle | NAT timeout killing the UDP session | Set `PersistentKeepalive = 25` in the client config under `[Peer]`. This sends a keepalive packet every 25 seconds to maintain the NAT mapping. |
| Slow speeds through WireGuard | MTU mismatch or server congestion | Try setting `MTU = 1420` (or `1280` for very restricted networks) in the `[Interface]` section of the client config. If using a VPN provider, try a different server. |
| Cannot reach home devices (VPN Server mode) | AllowedIPs does not include home subnet, or Freebox is not routing | Ensure `AllowedIPs` on the client includes `192.168.1.0/24`. On the Freebox, check that the WireGuard server subnet can route to the LAN (this is usually automatic). |
| AllowedIPs conflict | Overlapping subnets between WireGuard and LAN | If the WireGuard subnet (default `10.66.66.0/24`) conflicts with your LAN or another VPN, change the Freebox WireGuard server subnet. Also ensure the client's LAN does not overlap with the home LAN. |
| "Key is not in correct format" error | Corrupted key or wrong field | WireGuard keys are exactly 44 characters of Base64, ending in `=`. Make sure you are pasting the right key in the right field (private key in Interface, public key in Peer). Do not confuse the server's public key with the client's private key. |
| Freebox firmware too old for WireGuard | Freebox OS is older than 4.x | Go to **Parametres de la Freebox** > **Mise a jour du Freebox OS** and update to the latest version. Reboot the Freebox after updating. |
| "Address already in use" error on Freebox | Another service is using port 51820 | Change the WireGuard listening port to 51821 or another unused port. Update all client configs with the new port. |
| VPN works but local network devices cannot see each other | VPN subnet isolation | In Freebox WireGuard server settings, make sure inter-client routing or LAN access is enabled. The exact option varies by firmware version. |

---

## 12. Security Best Practices

### Key Rotation

- **Rotate WireGuard keys every 3 to 6 months**. WireGuard does not have built-in key expiration, so you must do this manually.
- To rotate: Delete the peer in Freebox OS, create a new one (which generates new keys), and re-import the config on the client device.
- Keep old configs deleted from devices after rotation.

### Pre-Shared Keys

- **Enable pre-shared keys (PSK) for every peer**. The Freebox can generate these automatically when creating a peer.
- PSK adds an additional layer of symmetric encryption on top of WireGuard's Curve25519 key exchange.
- This provides defense against future quantum computers that could break Curve25519 (post-quantum security).
- There is no performance penalty for enabling PSK.

### Allowed IPs

- **Limit AllowedIPs to only what is needed**. If a peer only needs access to the home NAS at `192.168.1.50`, set `AllowedIPs = 192.168.1.50/32, 10.66.66.0/24` instead of `0.0.0.0/0`.
- This follows the principle of least privilege and limits damage if a peer's keys are compromised.

### Monitoring

- **Regularly check active connections** in Freebox OS under **Serveur VPN** > **WireGuard**. Look for:
  - Unexpected peers.
  - Peers with large data transfers you do not recognize.
  - Peers that should not be connected (e.g., an old phone you no longer own).
- Remove peers for devices you no longer use.

### Firmware Updates

- **Keep your Freebox firmware up to date**. Free regularly releases security patches.
- Enable automatic updates if available: **Parametres de la Freebox** > **Mise a jour du Freebox OS** > **Mise a jour automatique**.

### Config File Security

- **Treat `.conf` files like passwords**. They contain the private key which grants full access to the VPN.
- Do not email `.conf` files unencrypted. Use AirDrop, USB drive, or scan a QR code instead.
- Delete `.conf` files from Downloads/Desktop after importing them into the WireGuard app.
- Do not commit `.conf` files to Git repositories. Add `*.conf` to your `.gitignore`.

### Network Segmentation

- If your Freebox supports VLANs or guest networks, consider putting IoT devices on a separate subnet and only allowing VPN peers to access the main subnet.
- This limits exposure if an IoT device is compromised.

---

## 13. Freebox OS Navigation (French to English)

The Freebox OS interface is in French. Here is a reference table for all VPN-related menu items and labels.

| French | English |
|---|---|
| Parametres de la Freebox | Freebox Settings |
| Client VPN | VPN Client |
| Serveur VPN | VPN Server |
| Ajouter une connexion | Add a connection |
| Ajouter un pair | Add a peer |
| Configuration VPN | VPN Configuration |
| Type de serveur | Server type |
| Description / Nom | Description / Name |
| Cle privee | Private key |
| Cle publique | Public key |
| Cle pre-partagee | Pre-shared key |
| Point de terminaison | Endpoint |
| IP autorisees | Allowed IPs |
| Port d'ecoute | Listening port |
| Sous-reseau | Subnet |
| Adresse IP | IP address |
| Sauvegarder | Save |
| Appliquer | Apply |
| Activer / Demarrer | Activate / Start |
| Desactiver / Arreter | Deactivate / Stop |
| Connecte | Connected |
| Deconnecte | Disconnected |
| Etat | Status |
| Gestion des ports | Port Management |
| Redirections de ports | Port Redirections |
| Ajouter une redirection | Add a redirect |
| Port externe | External port |
| Port interne | Internal port |
| IP de destination | Destination IP |
| Protocole | Protocol |
| Pare-feu | Firewall |
| Mode avance | Advanced mode |
| Mise a jour du Freebox OS | Freebox OS Update |
| Mise a jour automatique | Automatic update |
| Nom de domaine | Domain name |
| Importer un fichier | Import a file |
| Telecharger | Download |
| Supprimer | Delete |
| Modifier | Edit |
| Connexion | Login / Connection |
| Utilisateur | User |
| Mot de passe | Password |
| Adresse du serveur | Server address |
| Actif | Active / Enabled |
| Inactif | Inactive / Disabled |

---

**See also**:
- [Freebox VPN Configuration Guide (OpenVPN)](FREEBOX.md) -- For Revolution/Mini 4K or if you need OpenVPN.
- [WireGuard General Guide](WIREGUARD.md) -- WireGuard concepts and standalone setup.
- [Raspberry Pi VPN Guide](RASPBERRY-PI.md) -- Setting up a Pi as a VPN server.
- [OpenVPN Guide](OPENVPN.md) -- OpenVPN configuration details.
