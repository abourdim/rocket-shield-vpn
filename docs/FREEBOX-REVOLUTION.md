# Freebox Revolution -- Complete OpenVPN Setup Guide

> A step-by-step guide for setting up OpenVPN on the Freebox Revolution, both as a VPN Client (route your traffic through a commercial VPN) and as a VPN Server (access your home network remotely).

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites](#2-prerequisites)
3. [Accessing Freebox OS -- Step by Step](#3-accessing-freebox-os--step-by-step)
4. [VPN Client Mode -- Connect to External VPN Provider](#4-vpn-client-mode--connect-to-external-vpn-provider)
5. [VPN Server Mode -- Host Your Own OpenVPN Server](#5-vpn-server-mode--host-your-own-openvpn-server)
6. [Connect from Your Phone (Detailed)](#6-connect-from-your-phone-detailed)
7. [Connect from Your Laptop (Detailed)](#7-connect-from-your-laptop-detailed)
8. [Troubleshooting (Revolution-Specific)](#8-troubleshooting-revolution-specific)
9. [Security Tips for Revolution](#9-security-tips-for-revolution)
10. [Freebox OS Navigation Reference (French to English)](#10-freebox-os-navigation-reference-french-to-english)

---

## 1. Overview

The **Freebox Revolution** (v6) was released by Free (Iliad Group) in 2011 and remains one of the most widely deployed internet boxes in France. It serves as a combined modem, router, NAS, media player, and telephony device.

**Key specs relevant to VPN:**

- **Connection types**: ADSL, ADSL2+, VDSL2, and FTTH (Fiber to the Home) depending on your line
- **Processor**: Marvell Armada 370 (1.2 GHz dual-core ARM)
- **RAM**: 512 MB DDR3
- **Storage**: 250 GB internal HDD
- **VPN support**: OpenVPN only -- WireGuard is **not** supported on the Revolution hardware
- **VPN modes**: Both VPN Client and VPN Server are available through Freebox OS
- **Operating system**: Freebox OS (web-based administration interface)
- **Minimum Freebox OS version for VPN**: 3.1.0 or later (most Revolutions have been updated well past this)

**What you can do:**

| Mode | Purpose | Example Use Case |
|------|---------|-----------------|
| **VPN Client** | Route all home traffic through a commercial VPN provider | Privacy, access geo-restricted content, hide traffic from your ISP |
| **VPN Server** | Allow remote devices to connect back into your home network | Access home NAS while traveling, secure browsing on public WiFi via your home connection |

---

## 2. Prerequisites

Before starting, make sure you have the following:

### 2.1 Hardware and Connectivity

- A **Freebox Revolution** connected to the internet and powered on (both the Server box and the Player box should have green/white LEDs -- but only the Server box is needed for VPN)
- A **computer or smartphone** connected to the Freebox network (via WiFi or Ethernet cable)

### 2.2 Freebox Admin Password

You need the Freebox admin password to access Freebox OS settings. Here is how to set or reset it:

**First-time setup (no password set yet):**

1. Open a browser and go to `http://mafreebox.freebox.fr`
2. The Freebox will prompt you to look at the **LCD screen on the front of the Freebox Server box**
3. A numeric code is displayed on that LCD screen -- type it into your browser
4. You will then be asked to **create an admin password**
5. Choose a strong password (minimum 8 characters, mix of letters, numbers, and symbols)
6. Write it down somewhere safe -- you will need it every time you access Freebox OS

**Reset a forgotten password:**

1. On the Freebox Server box, there is a small recessed **reset button** on the back panel
2. Use a paperclip to press and hold it for about 5 seconds until the LCD screen shows a reset message
3. The admin password is wiped -- you can now set a new one through the browser as described above
4. Note: resetting the password does **not** reset your internet settings, WiFi, or other configs

### 2.3 Know Your Public IP (for Server Mode)

If you plan to use VPN Server mode, you need to know your public IP address:

1. From a device on your Freebox network, visit [whatismyip.com](https://whatismyip.com)
2. Note the IPv4 address displayed (example: `82.65.xx.xx` or `78.193.xx.xx` for Free subscribers)
3. Be aware that this IP may change unless you have a **static IP** (Free assigns static IPs to most fiber subscribers, but ADSL subscribers often have dynamic IPs)
4. If your IP is dynamic, see Section 5.5 for Dynamic DNS setup

---

## 3. Accessing Freebox OS -- Step by Step

Freebox OS is the web-based administration panel for your Freebox Revolution. All VPN configuration happens here.

### Step 1: Connect to the Freebox Network

You **must** be connected to the Freebox network to access Freebox OS. This means:

- Connected via **WiFi** to your Freebox WiFi network (the SSID is usually printed on a sticker under the Freebox Server box), OR
- Connected via **Ethernet cable** plugged into one of the 4 Ethernet ports on the back of the Freebox Server box

You **cannot** access Freebox OS from outside your network (unless you have enabled remote access, which is disabled by default).

### Step 2: Open the Freebox OS Interface

1. Open any web browser (Chrome, Firefox, Edge, Safari)
2. In the address bar, type exactly: **`http://mafreebox.freebox.fr`**
3. Press Enter

This address is a local DNS name that resolves to the Freebox's internal IP address (typically `192.168.1.254`).

### Step 3: First-Time Authentication

If this is your first time accessing Freebox OS (or after a password reset):

1. The browser will show a message asking you to check the Freebox LCD screen
2. Walk over to your Freebox Server box and read the **numeric code** displayed on the small LCD
3. Enter this code in the browser
4. Set your **admin password**:
   - Minimum 8 characters
   - Use a mix of uppercase, lowercase, numbers, and special characters
   - Example: `MyFr33b0x!2024`
5. Click **"Valider"** (Validate)

If you have already set a password, simply enter it and click **"Connexion"** (Login).

### Step 4: Navigate to VPN Settings

Once logged in, you will see the Freebox OS home screen with several icons:

1. Click the **gear icon** labeled **"Parametres de la Freebox"** (Freebox Settings)
2. In the left sidebar, look for **"Mode Avance"** (Advanced Mode) -- if you do not see VPN options, click this to switch to the advanced view
3. Click **"VPN"** in the sidebar or in the main settings panel
4. You will see two tabs:
   - **"Client VPN"** -- for connecting the Freebox to an external VPN
   - **"Serveur VPN"** -- for running your own VPN server

### Common Access Issues

| Problem | Solution |
|---------|----------|
| "Page not found" or page does not load | Make sure you are connected to the Freebox network (WiFi or Ethernet). You cannot access it from another network. |
| `mafreebox.freebox.fr` does not resolve | Try the IP address directly: **`http://192.168.1.254`** |
| Login page loads but password is rejected | Double-check your password. If forgotten, reset it using the physical button on the back of the Freebox (see Section 2.2). |
| Interface loads very slowly | The Freebox Revolution hardware is from 2011 -- give it 10-15 seconds to load. Clear your browser cache if needed. |
| "Freebox OS" page appears but no settings | You may be in simplified mode. Look for a toggle or link labeled **"Mode Avance"** (Advanced Mode) and click it. |

---

## 4. VPN Client Mode -- Connect to External VPN Provider

**Goal:** Route **all** internet traffic from your entire home network through a commercial VPN provider. Every device connected to your Freebox (phones, laptops, smart TV, game console) will automatically use the VPN -- no per-device setup needed.

### 4.1 Get OpenVPN Config from Your Provider

You need to download an `.ovpn` configuration file from your VPN provider. Here are the steps for the most popular providers:

#### NordVPN

1. Go to [my.nordaccount.com](https://my.nordaccount.com) and log in
2. Click **"NordVPN"** in the left sidebar
3. Scroll down to **"Manual Setup"**
4. Click the **"OpenVPN"** tab
5. Note your **service credentials** (username and password) -- these are different from your NordVPN account login
6. Below the credentials, you will see a server list -- select a server (e.g., `fr789.nordvpn.com` for France)
7. Click **"Download UDP"** (UDP is recommended for better performance) or "Download TCP" if UDP is blocked on your network
8. Save the `.ovpn` file to your computer

#### ProtonVPN

1. Go to [account.protonvpn.com](https://account.protonvpn.com) and log in
2. Click **"Downloads"** in the left sidebar
3. Scroll to **"OpenVPN configuration files"**
4. Select your preferred platform: choose **"Router"**
5. Select the **protocol**: UDP (recommended) or TCP
6. Select the **country and server** (e.g., France, `FR#10`)
7. Click **"Download"**
8. Note your **OpenVPN/IKEv2 username and password** shown on the same page

#### Mullvad

1. Go to [mullvad.net/account](https://mullvad.net/account) and log in with your account number
2. Click **"OpenVPN configuration file generator"** (or navigate to the downloads section)
3. Select your desired **country** (e.g., France)
4. Select your desired **city** (e.g., Paris)
5. Select **UDP** (port 1194 or 1301) or **TCP** (port 443)
6. Click **"Download file"**
7. Mullvad uses your **account number** as both the username and password (no separate credentials)

#### Surfshark

1. Go to [my.surfshark.com](https://my.surfshark.com) and log in
2. Click **"VPN"** then **"Manual Setup"**
3. Click the **"OpenVPN"** tab
4. Note your **service credentials** (username and password)
5. Select a server location from the list (e.g., `fr-par.prod.surfshark.com` for Paris, France)
6. Click the **"Download UDP"** or **"Download TCP"** button
7. Save the `.ovpn` file

### 4.2 Import Config into Freebox

Now that you have the `.ovpn` file on your computer:

1. Open Freebox OS in your browser (`http://mafreebox.freebox.fr`)
2. Go to **Parametres** (Settings) > **VPN** > **Client VPN**
3. Click **"Ajouter une connexion"** (Add a connection)
4. A form appears with the following fields:

| Field | What to enter |
|-------|--------------|
| **Type** | Select **"OpenVPN"** from the dropdown |
| **Description** | Give it a recognizable name, e.g., `NordVPN-France` or `ProtonVPN-Paris` |
| **Fichier de configuration** (Configuration file) | Click **"Parcourir"** (Browse), then select the `.ovpn` file you downloaded |
| **Nom d'utilisateur** (Username) | Enter the **service username** from your VPN provider (not your website login) |
| **Mot de passe** (Password) | Enter the **service password** from your VPN provider |

5. Click **"Sauvegarder"** (Save)

**Important notes:**

- The Freebox may take a few seconds to parse the `.ovpn` file
- If the import fails, your `.ovpn` file may contain unsupported directives. See Troubleshooting Section 8 for common fixes
- You can add multiple VPN configurations (e.g., different countries/servers) and switch between them

### 4.3 Activate VPN Client

1. Go back to the **Client VPN** tab -- your new connection should appear in the list
2. Click the **toggle switch** next to your connection to turn it **ON**
3. Wait **5-10 seconds** for the connection to establish
4. The status should change to **"Connecte"** (Connected) with a green indicator
5. If the status shows **"Erreur"** (Error) or stays on **"Connexion en cours"** (Connecting):
   - Double-check your username and password
   - Try downloading a different server's `.ovpn` file from your provider
   - Make sure your VPN subscription is active

### 4.4 Verify It Works

Once the VPN Client is connected, **all devices** on your Freebox network are automatically routed through the VPN. To verify:

1. From any device connected to your Freebox (phone, laptop, etc.)
2. Open a browser and go to [whatismyip.com](https://whatismyip.com)
   - The IP address shown should be **your VPN provider's IP**, not your Freebox IP
   - The location should match the VPN server you selected (e.g., if you chose a France server, it should show a French IP)
3. For a more thorough check, go to [dnsleaktest.com](https://dnsleaktest.com)
   - Click **"Extended test"**
   - Wait for the test to complete (about 30 seconds)
   - The DNS servers listed should belong to **your VPN provider**, not to Free (Proxad/Free SAS)
   - If you see Free's DNS servers, you have a DNS leak -- see Troubleshooting Section 8

### 4.5 Disable VPN Client

To return to your normal internet connection:

1. Go to Freebox OS > **Parametres** > **VPN** > **Client VPN**
2. Toggle the switch next to your connection to **OFF**
3. Wait a few seconds -- internet traffic will now go directly through Free's network
4. Verify by visiting [whatismyip.com](https://whatismyip.com) -- you should see your real Freebox public IP again

---

## 5. VPN Server Mode -- Host Your Own OpenVPN Server

**Goal:** Run an OpenVPN server on your Freebox Revolution so you can securely connect back to your home network from anywhere in the world (hotel, school, coffee shop, abroad).

This gives you:
- Secure, encrypted access to your home network
- Access to local devices (NAS, printer, cameras) while away
- A trusted exit point for your internet traffic (your home IP) instead of using untrusted public WiFi

### 5.1 Enable OpenVPN Server

1. Open Freebox OS: `http://mafreebox.freebox.fr`
2. Go to **Parametres** (Settings) > **VPN** > **Serveur VPN** (VPN Server)
3. Click the **"OpenVPN"** tab
4. Toggle **"Activer"** (Enable) to **ON**
5. Configure the following settings:

| Setting | Recommended Value | Notes |
|---------|------------------|-------|
| **Port** | `1194` (default) | Change only if your ISP or network blocks 1194. Common alternatives: 443, 1195, 8080 |
| **Protocole** (Protocol) | **UDP** (recommended) | UDP is faster. Use TCP only if UDP is blocked at your location. |
| **Sous-reseau** (Subnet) | `10.8.0.0/24` (default) | Leave this as default unless it conflicts with your LAN (unlikely). VPN clients will get IPs in the 10.8.0.x range. |
| **DNS** | Freebox DNS or `1.1.1.1` | Freebox DNS uses Free's resolvers. For privacy, use `1.1.1.1` (Cloudflare) or `9.9.9.9` (Quad9). |
| **Chiffrement** (Encryption) | AES-256-CBC | If available, use the strongest option. |

6. Click **"Appliquer"** (Apply)
7. The server will start -- this takes about 5-10 seconds

### 5.2 Create VPN Users

Each device that will connect remotely needs its own user account:

1. In the VPN Server section, click the **"Utilisateurs"** (Users) tab
2. Click **"Ajouter un utilisateur"** (Add a user)
3. Fill in the fields:

| Field | Example | Notes |
|-------|---------|-------|
| **Login** | `phone` | Choose a descriptive name for the device (e.g., `phone`, `laptop`, `tablet`) |
| **Mot de passe** (Password) | `Str0ng!Pass#42` | Use a strong password -- at least 12 characters with mixed case, numbers, symbols |
| **Adresse IP fixe** (Static IP) | `10.8.0.2` | Optional. Leave blank for automatic assignment, or set a specific IP within the 10.8.0.x range |

4. Click **"Sauvegarder"** (Save)
5. Repeat for each device that needs access (e.g., create `phone`, `laptop`, `work-pc`)

### 5.3 Download Client Configuration

For each user, you need to download the `.ovpn` configuration file that the remote device will use to connect:

1. In the **Utilisateurs** (Users) list, find the user you created
2. Click the **download icon** (downward arrow) next to that user's entry
3. Save the `.ovpn` file to your computer
4. This file contains:
   - Your Freebox's public IP address (as the server address)
   - The port and protocol settings
   - TLS certificates and keys for encrypted authentication
   - All required OpenVPN client directives

**IMPORTANT:** The downloaded `.ovpn` file uses your Freebox's **current public IP address** as the server endpoint. If your IP changes (common with ADSL/VDSL), the VPN will stop working until you update the file or set up Dynamic DNS (see Section 5.5).

**Security note:** Treat this `.ovpn` file as sensitive -- it contains certificates that grant access to your home network. Transfer it securely (not via unencrypted email to strangers).

### 5.4 Port Forwarding (Usually Automatic)

The Freebox Revolution typically handles port forwarding automatically when you enable the OpenVPN server. However, if remote connections are not working:

**Check existing port forwarding rules:**

1. In Freebox OS, go to **Parametres** > **Mode Avance** > **Gestion des ports** (Port Management)
2. Look for a rule forwarding port **1194/UDP** to the Freebox itself

**If no rule exists, create one manually:**

1. Click **"Ajouter une redirection"** (Add a redirect)
2. Fill in:

| Field | Value |
|-------|-------|
| **IP de destination** (Destination IP) | `192.168.1.254` (the Freebox itself) |
| **Port de debut** (Start port) | `1194` |
| **Port de fin** (End port) | `1194` |
| **Type** | `UDP` |
| **Port de destination** (Destination port) | `1194` |

3. Click **"Sauvegarder"** (Save)

**Verify from outside your network:**

- Ask a friend to try connecting, or use your phone's mobile data (disconnect from WiFi first)
- You can also use an online port checker like [yougetsignal.com/tools/open-ports](https://www.yougetsignal.com/tools/open-ports/) -- enter your public IP and port 1194 to see if it is open

### 5.5 Dynamic DNS (Optional but Recommended)

If your Freebox has a dynamic public IP (it changes periodically), you should set up Dynamic DNS so you have a fixed hostname that always points to your current IP.

#### Option A: Free's Built-in DynDNS (Recommended)

Free provides a free Dynamic DNS domain for Freebox subscribers:

1. In Freebox OS, go to **Parametres** > **Mode Avance** > **Nom de domaine** (Domain Name) or **DynDNS**
2. Enable the service
3. You will get a hostname like `your-id.freeboxos.fr` or `your-id.hd.free.fr`
4. This hostname automatically updates when your IP changes

#### Option B: DuckDNS (Free Third-Party Service)

1. Go to [duckdns.org](https://www.duckdns.org) and create an account (sign in with Google/GitHub/etc.)
2. Create a subdomain, e.g., `myfreebox` (your full hostname will be `myfreebox.duckdns.org`)
3. Note your **DuckDNS token** from the dashboard
4. In Freebox OS, go to **Parametres** > **Mode Avance** > **DynDNS**
5. Click **"Ajouter"** (Add) and fill in:

| Field | Value |
|-------|-------|
| **Fournisseur** (Provider) | Select `duckdns.org` from the dropdown (or "Custom" if not listed) |
| **Nom d'hote** (Hostname) | `myfreebox.duckdns.org` |
| **Nom d'utilisateur** (Username) | Your DuckDNS token |
| **Mot de passe** (Password) | Your DuckDNS token (same as username for DuckDNS) |

6. Click **"Sauvegarder"** (Save)

#### Option C: No-IP

1. Create an account at [noip.com](https://www.noip.com)
2. Create a hostname (e.g., `myfreebox.ddns.net`)
3. In Freebox OS DynDNS settings, select `No-IP` as the provider
4. Enter your No-IP credentials and hostname
5. Save

**After setting up DynDNS:** Edit your `.ovpn` client configuration file -- find the line starting with `remote` and replace the IP address with your DynDNS hostname:

```
# Before:
remote 82.65.123.456 1194

# After:
remote myfreebox.duckdns.org 1194
```

---

## 6. Connect from Your Phone (Detailed)

### 6.1 iPhone / iPad

**Step 1: Install OpenVPN Connect**

1. Open the **App Store** on your iPhone or iPad
2. Search for **"OpenVPN Connect"** (the official app by OpenVPN Inc. -- blue shield icon)
3. Tap **"Get"** / **"Install"**
4. Wait for the installation to complete

**Step 2: Transfer the .ovpn file to your phone**

Choose one of these methods:

**Method A -- Email (simplest):**

1. On your computer, open your email client
2. Compose a new email to yourself
3. Attach the `.ovpn` file you downloaded in Section 5.3
4. Send the email
5. On your iPhone, open the Mail app and find the email
6. Tap the `.ovpn` attachment
7. Tap the **Share** button (square with upward arrow)
8. Scroll through the apps and select **"OpenVPN"** (or "Open in OpenVPN")

**Method B -- AirDrop (Mac users):**

1. On your Mac, right-click the `.ovpn` file
2. Select **Share** > **AirDrop**
3. Select your iPhone from the AirDrop list
4. On your iPhone, accept the file
5. Choose **"OpenVPN"** when asked which app to open with

**Method C -- iCloud Drive / Files app:**

1. On your computer, upload the `.ovpn` file to iCloud Drive (or copy it to the Files app)
2. On your iPhone, open the **OpenVPN Connect** app
3. Tap the **"+"** button (or "Import Profile")
4. Tap **"Upload File"**
5. Navigate to the `.ovpn` file in the Files browser and select it

**Step 3: Import and connect**

1. OpenVPN Connect will show the imported profile with your server details
2. Tap **"Add"** to add the profile
3. Enter the **username** and **password** you created in Section 5.2
4. Optionally toggle **"Save Password"** so you do not have to enter it each time
5. Tap the **toggle switch** to connect
6. **First time only:** iOS will display a popup: "OpenVPN would like to add VPN Configurations" -- tap **"Allow"**
7. You may need to authenticate with Face ID / Touch ID / passcode
8. Once connected, a **VPN icon** appears in your iPhone's status bar (a small "VPN" badge)
9. You are now securely connected to your home network

### 6.2 Android

**Step 1: Install OpenVPN Connect**

1. Open the **Google Play Store**
2. Search for **"OpenVPN Connect"** (by OpenVPN Inc.)
3. Tap **"Install"**
4. Wait for installation to complete

**Step 2: Transfer the .ovpn file to your phone**

**Method A -- Email:**

1. Email the `.ovpn` file to yourself from your computer
2. On your Android phone, open the email
3. Tap the `.ovpn` attachment
4. If prompted, choose **"Open with OpenVPN Connect"**

**Method B -- USB cable:**

1. Connect your Android phone to your computer via USB
2. Copy the `.ovpn` file to your phone's internal storage (e.g., to the `Downloads` folder)
3. Open the **OpenVPN Connect** app
4. Tap **"+"** (Import Profile) > **"Upload File"**
5. Browse to the `.ovpn` file and select it

**Method C -- Google Drive:**

1. Upload the `.ovpn` file to Google Drive from your computer
2. On your phone, open Google Drive and download the file
3. Open OpenVPN Connect and import it using "Upload File"

**Step 3: Import and connect**

1. After selecting the `.ovpn` file, OpenVPN shows a profile summary
2. Tap **"Import"** then **"Add"**
3. Enter your **username** and **password** from Section 5.2
4. Tap **"Connect"**
5. **First time only:** Android will show a dialog: "Connection request -- OpenVPN wants to set up a VPN connection" -- tap **"OK"**
6. Once connected, a **key icon** appears in your Android status bar
7. You are now connected to your home network through the VPN

---

## 7. Connect from Your Laptop (Detailed)

### 7.1 Windows

**Step 1: Install OpenVPN Connect**

1. Go to [openvpn.net/client](https://openvpn.net/client/) in your browser
2. Click the **Windows** download button
3. Run the downloaded installer (you may need administrator rights -- right-click > "Run as administrator" if prompted)
4. Follow the installation wizard -- accept the defaults
5. During installation, Windows may ask to install a **TAP network adapter** -- click **"Yes"** or **"Install"** to allow this (it is required for OpenVPN to work)

**Step 2: Import the configuration**

1. Launch **OpenVPN Connect** from your Start menu or desktop shortcut
2. Click the **"+"** button or **"Import Profile"**
3. Click **"Upload File"**
4. Navigate to and select the `.ovpn` file from Section 5.3
5. The profile will be imported and shown in the app

**Step 3: Connect**

1. Enter your **username** and **password** from Section 5.2
2. Optionally check **"Save password"**
3. Click **"Connect"**
4. The OpenVPN icon in your **system tray** (bottom-right of taskbar) will turn **green** when connected
5. You are now tunneled into your home network

**Alternative: OpenVPN Community Client (command line)**

If you prefer the command-line client:

```bash
# Install OpenVPN (via winget or from openvpn.net)
winget install OpenVPNTechnologies.OpenVPN

# Connect (run as Administrator in Command Prompt or PowerShell)
openvpn --config "C:\Users\YourName\Downloads\freebox-vpn.ovpn"
# Enter username and password when prompted
```

### 7.2 macOS

**Option A: OpenVPN Connect (recommended)**

1. Go to [openvpn.net/client](https://openvpn.net/client/)
2. Click the **macOS** download button
3. Open the `.dmg` file and drag OpenVPN Connect to your Applications folder
4. Launch OpenVPN Connect
5. Click **"+"** > **"Upload File"** > select your `.ovpn` file
6. Enter your username and password
7. Click **"Connect"**
8. macOS will ask for your **admin password** to authorize the VPN configuration -- enter it
9. A **VPN icon** (two connected arrows) appears in the menu bar when connected

**Option B: Tunnelblick (open-source alternative)**

1. Download Tunnelblick from [tunnelblick.net](https://tunnelblick.net)
2. Install and open it
3. Drag and drop your `.ovpn` file onto the Tunnelblick icon in the menu bar
4. Click **"Install"** when prompted (choose "Only Me" or "All Users")
5. Click the Tunnelblick icon in the menu bar > select your profile > **"Connect"**
6. Enter your credentials when prompted

### 7.3 Linux (Ubuntu / Debian)

**Option A: Command-line (fastest)**

```bash
# Install OpenVPN client
sudo apt update
sudo apt install openvpn

# Connect manually (foreground -- useful for testing)
sudo openvpn --config ~/Downloads/freebox-vpn.ovpn
# Enter username and password when prompted
# Press Ctrl+C to disconnect

# Connect in background (daemon mode)
sudo openvpn --config ~/Downloads/freebox-vpn.ovpn --daemon
# To disconnect daemon mode:
sudo killall openvpn
```

**Option B: Auto-start on boot**

```bash
# Copy your config to the OpenVPN client directory
sudo cp ~/Downloads/freebox-vpn.ovpn /etc/openvpn/client/freebox.conf

# Create a credentials file so it does not prompt for username/password
sudo bash -c 'cat > /etc/openvpn/client/freebox-auth.txt << EOF
your_username
your_password
EOF'

# Secure the credentials file
sudo chmod 600 /etc/openvpn/client/freebox-auth.txt

# Edit the config to reference the auth file
# Add this line to /etc/openvpn/client/freebox.conf:
#   auth-user-pass /etc/openvpn/client/freebox-auth.txt

# Enable and start the service
sudo systemctl enable openvpn-client@freebox
sudo systemctl start openvpn-client@freebox

# Check status
sudo systemctl status openvpn-client@freebox
```

**Option C: NetworkManager GUI (Ubuntu Desktop)**

1. Install the OpenVPN plugin: `sudo apt install network-manager-openvpn-gnome`
2. Open **Settings** > **Network** > **VPN** > click **"+"**
3. Select **"Import from file..."**
4. Select your `.ovpn` file
5. Enter your username and password in the form
6. Click **"Add"**
7. Toggle the VPN on from the network menu in the top panel

---

## 8. Troubleshooting (Revolution-Specific)

| # | Problem | Cause | Solution |
|---|---------|-------|----------|
| 1 | Cannot access `mafreebox.freebox.fr` | Not connected to the Freebox network, or DNS issue | Make sure you are connected via WiFi or Ethernet to the Freebox. Try the direct IP: `http://192.168.1.254`. If still not working, try a different browser or clear your DNS cache (`ipconfig /flushdns` on Windows, `sudo dscacheutil -flushcache` on macOS). |
| 2 | VPN Client shows "Erreur" after connecting | Incorrect credentials or incompatible `.ovpn` file | Double-check the username and password (these are often **service credentials**, not your website login). Try downloading a fresh `.ovpn` file from your provider. Remove `persist-tun` or `persist-key` lines from the `.ovpn` file if present -- the Freebox does not always support them. |
| 3 | VPN Client connected but no internet | DNS is misconfigured or the VPN provider blocks traffic | In the `.ovpn` file, make sure there is a `dhcp-option DNS` line. If not, add: `dhcp-option DNS 1.1.1.1`. Some providers require you to whitelist your IP or activate the connection from their dashboard first. |
| 4 | VPN Server: cannot connect from outside | Port 1194 is not forwarded, or ISP is blocking it | Check port forwarding in Freebox OS (Section 5.4). Test the port from outside using an online port checker. If port 1194 is blocked, try changing the server port to 443/TCP (which is almost never blocked). Make sure your Freebox firewall is not blocking incoming connections on this port. |
| 5 | "Auth failed" when connecting to VPN server | Wrong username or password in the client | Re-enter the credentials exactly as set in Section 5.2. Passwords are case-sensitive. Delete the user in Freebox OS and recreate it if unsure. |
| 6 | Connection drops after a few minutes | NAT timeout or keepalive issue | Add these lines to your `.ovpn` client file: `keepalive 10 60` and `ping-restart 120`. This sends a ping every 10 seconds and restarts after 60 seconds of no response. |
| 7 | Slow speeds through VPN Client | VPN encryption overhead on Revolution's older CPU | The Revolution's CPU is not powerful enough for high-speed VPN. Expect 30-80 Mbps maximum through VPN even on a fiber connection. Choose a VPN server geographically close to you. Use UDP instead of TCP. Try AES-128-CBC instead of AES-256-CBC if your provider supports it. |
| 8 | DNS leaks detected on dnsleaktest.com | Freebox is using Free's DNS alongside the VPN's DNS | Edit the `.ovpn` file and add: `block-outside-dns` (Windows) or `dhcp-option DNS 1.1.1.1`. In Freebox OS, go to Settings > DHCP and change the DNS servers from Free's to your VPN provider's or to `1.1.1.1`. |
| 9 | `.ovpn` file will not import into Freebox | File contains unsupported OpenVPN directives | Open the `.ovpn` file in a text editor and remove or comment out (prefix with `#`) these lines if present: `pull-filter`, `block-outside-dns`, `setenv`, `up`, `down`, `script-security`. The Freebox supports a limited subset of OpenVPN directives. |
| 10 | Public IP changes and VPN server becomes unreachable | Dynamic IP without DynDNS | Set up Dynamic DNS as described in Section 5.5. Edit the `remote` line in your `.ovpn` file to use the DynDNS hostname instead of the IP. |
| 11 | "TLS handshake failed" | Clock skew, expired certificates, or incompatible TLS version | Make sure the date and time are correct on both your Freebox and client device. Regenerate the server configuration (disable and re-enable the VPN server). If your client is very new, it may require TLS 1.3 which the Revolution does not support -- downgrade your OpenVPN client or add `tls-version-min 1.0` to the `.ovpn` file. |
| 12 | TAP adapter error on Windows | TAP driver not installed or corrupted | Reinstall OpenVPN Connect -- it will reinstall the TAP adapter. Or manually install it: go to `C:\Program Files\OpenVPN\bin\` and run `tapctl.exe create`. If using OpenVPN 2.5+, try the `wintun` adapter by adding `windows-driver wintun` to your `.ovpn` file. |
| 13 | Freebox OS interface is entirely in French | Freebox OS does not have an English language option | The Freebox OS interface is French-only. See Section 10 for a complete French-to-English translation table of all VPN-related terms. Use your browser's built-in translation feature (right-click > "Translate to English" in Chrome) for a quick workaround. |
| 14 | Revolution firmware is outdated | Firmware has not been updated | Go to Freebox OS > **Parametres** > **Mise a jour du Freebox OS** (Freebox OS Update). If an update is available, click **"Mettre a jour"** (Update). The Freebox will restart (takes 2-5 minutes). VPN features require firmware 3.1.0+. |
| 15 | How to check Freebox firmware version | Need to verify current version | In Freebox OS, go to **Parametres** > **Informations** (or the main dashboard). The firmware version is displayed as **"Version de Freebox OS"** (e.g., `4.7.6`). You can also see it on the LCD screen of the Freebox Server box by pressing the small front button. |
| 16 | VPN Client: "Certificate verify failed" | VPN provider updated their certificates | Download a fresh `.ovpn` file from your provider's website and re-import it into the Freebox. Delete the old configuration first. |
| 17 | Cannot create more than a few VPN users | Freebox has a user limit | The Freebox Revolution supports a limited number of simultaneous VPN server connections (typically 4-8). Delete unused users or disconnect idle clients. |

---

## 9. Security Tips for Revolution

### Essential Security Measures

1. **Change the default admin password**
   - If you have never changed it, do it now: Freebox OS > Parametres > Change password
   - Use at least 12 characters with a mix of uppercase, lowercase, numbers, and symbols

2. **Use strong VPN user passwords**
   - Each VPN user account should have a unique, strong password
   - Do not reuse passwords from other services
   - Minimum 12 characters recommended

3. **Enable the Freebox firewall**
   - Freebox OS > Parametres > Mode Avance > Pare-feu (Firewall)
   - Set to at least "Normal" mode
   - Do not disable it -- it protects your network from unsolicited incoming connections

4. **Keep firmware updated**
   - Freebox OS > Parametres > Mise a jour du Freebox OS
   - Enable automatic updates if the option is available
   - Check manually every few months

5. **Secure your .ovpn files**
   - These files contain certificates and keys -- treat them like passwords
   - Do not share them via unencrypted channels (use AirDrop, USB drives, or end-to-end encrypted messaging)
   - Delete `.ovpn` files from email after transferring them to your device

6. **Monitor connected VPN clients**
   - Regularly check Freebox OS > VPN > Serveur VPN > Utilisateurs
   - Look at the connection status and last connection time
   - If you see unexpected connections, change the affected user's password immediately

7. **Rotate VPN server certificates periodically**
   - Every 6-12 months, disable the VPN server, re-enable it (this regenerates certificates), create new user profiles, and distribute new `.ovpn` files
   - Revoke old certificates by deleting old user accounts

8. **Disable remote Freebox OS access**
   - Unless you specifically need it, keep remote management disabled
   - Freebox OS > Parametres > Mode Avance > Acces a distance > Off

9. **WiFi security**
   - Use WPA2 or WPA3 encryption on your Freebox WiFi
   - Set a strong WiFi password (different from the admin password)
   - Disable WPS (WiFi Protected Setup) as it is a known security weakness

---

## 10. Freebox OS Navigation Reference (French to English)

Since Freebox OS is available only in French, use this reference table to navigate the interface:

### General Navigation

| French | English | Context |
|--------|---------|---------|
| Parametres de la Freebox | Freebox Settings | Main settings entry point (gear icon) |
| Mode Avance | Advanced Mode | Toggle to show all settings |
| Accueil | Home | Home screen |
| Informations | Information | System info and firmware version |
| Connexion Internet | Internet Connection | WAN/internet status |
| Mise a jour du Freebox OS | Freebox OS Update | Firmware updates |

### VPN-Specific Terms

| French | English | Where You See It |
|--------|---------|-----------------|
| VPN | VPN | Settings sidebar |
| Client VPN | VPN Client | Tab for connecting to external VPN |
| Serveur VPN | VPN Server | Tab for hosting your own VPN |
| Ajouter une connexion | Add a connection | Button in VPN Client |
| Ajouter un utilisateur | Add a user | Button in VPN Server |
| Supprimer | Delete | Remove a VPN profile or user |
| Sauvegarder | Save | Save changes |
| Appliquer | Apply | Apply settings |
| Activer | Enable | Turn a feature on |
| Desactiver | Disable | Turn a feature off |
| Connecte | Connected | VPN status indicator |
| Deconnecte | Disconnected | VPN status indicator |
| Erreur | Error | VPN status when connection failed |
| Connexion en cours | Connecting | VPN is establishing connection |
| Utilisateurs | Users | VPN Server user management tab |
| Telecharger | Download | Download button (e.g., for .ovpn files) |
| Parcourir | Browse | File browser button for uploading .ovpn |

### Network and Port Settings

| French | English | Where You See It |
|--------|---------|-----------------|
| Gestion des ports | Port Management | Port forwarding settings |
| Ajouter une redirection | Add a redirect | Create port forwarding rule |
| Port de debut | Start port | Port forwarding form |
| Port de fin | End port | Port forwarding form |
| Port de destination | Destination port | Port forwarding form |
| IP de destination | Destination IP | Port forwarding form |
| Pare-feu | Firewall | Firewall settings |
| Nom de domaine | Domain Name | DynDNS settings |
| Nom d'hote | Hostname | DynDNS hostname field |
| Fournisseur | Provider | DynDNS provider dropdown |

### Other Useful Terms

| French | English | Where You See It |
|--------|---------|-----------------|
| Nom d'utilisateur | Username | Login fields |
| Mot de passe | Password | Login fields |
| Fichier de configuration | Configuration file | VPN config upload |
| Description | Description | VPN connection name field |
| Valider | Validate / Confirm | Confirmation buttons |
| Annuler | Cancel | Cancel buttons |
| Redemarrer | Restart | Reboot the Freebox |
| Etat | Status | Connection status display |
| Reseau local | Local Network | LAN settings |
| DHCP | DHCP | DHCP server settings |
| Bail statique | Static lease | Fixed IP assignment |
| Adresse IP | IP Address | Various settings |

---

> **Last updated:** April 2026
>
> **Applies to:** Freebox Revolution (v6) running Freebox OS 4.x
>
> **Related guides:** [OpenVPN General Guide](OPENVPN.md) | [Freebox General Guide](FREEBOX.md) | [Step-by-Step Setup](STEP-BY-STEP.md)
