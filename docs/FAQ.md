# Rocket Shield VPN -- Frequently Asked Questions

---

## General

### 1. What is Rocket Shield VPN?

Rocket Shield VPN is a single-file educational web app that teaches kids and teens (ages 6-15) how VPNs, encryption, and internet security work. It uses a space adventure theme with a robot mascot called ByteBot to make cybersecurity concepts fun and accessible.

### 2. Is it a real VPN?

No. The web app itself is a simulator -- it does not route your traffic through a VPN. However, the project includes launch scripts (`rocket-shield.sh` and `rocket-shield.ps1`) that can install and configure real WireGuard or OpenVPN clients and servers on your machine.

### 3. Who is it for?

Primarily kids aged 6-15, parents, and teachers who want to introduce cybersecurity concepts. The three difficulty levels (Newbie Cadet, Explorer Pilot, Advanced Commander) cover ages from early primary school through teens. Developers and hobbyists can also use the launch scripts for real VPN infrastructure.

### 4. Is it free and open source?

Yes. The project is released under the MIT License. You can use, modify, share, and teach with it freely.

### 5. What languages does it support?

Three languages are built in:

- **English** (default, left-to-right)
- **French** (left-to-right)
- **Arabic** (right-to-left, with full RTL layout support)

You can switch languages instantly using the dropdown in the header.

### 6. Does it work offline?

Yes. Once the page has loaded, everything works offline. The only external dependency is Google Fonts (Fredoka, Nunito, Amiri), which will fall back to system fonts if unavailable.

---

## Web App

### 7. How do I run the web app?

The simplest way: double-click `index.html` to open it in your browser. No installation, no terminal, no server needed. Alternatively, use the launch script (`bash rocket-shield.sh` or `powershell rocket-shield.ps1`) to serve it on a local port with a QR code for mobile access.

### 8. How do I change the language?

Use the language dropdown in the top-right area of the header. Select EN (English), FR (French), or AR (Arabic). The entire app updates instantly, including all cards, quizzes, buttons, and ByteBot dialogue.

### 9. How do I change the theme?

Use the theme dropdown in the header. Four themes are available:

- **Space Commander** -- Deep navy with neon green and blue glows (default)
- **Sunset Desert** -- Warm oranges and sandy tones
- **Synthwave** -- Purple and pink neon, retro 80s vibe
- **Paper Light** -- Cream background with soft browns, easy on the eyes

### 10. Are there easter eggs?

Yes! Three of them:

- **ByteBot Secret Dance** -- Click ByteBot 5 times on the Command Center page.
- **Rainbow Mode** -- Enter the Konami Code on your keyboard (Up Up Down Down Left Right Left Right B A).
- **Confetti Celebrations** -- Connect to the VPN simulation, answer quizzes correctly, or complete all test checks.

### 11. Does it work on mobile devices?

Yes. The app is fully responsive with a mobile-first layout. The main breakpoint is at 640px. Navigation tabs stack vertically on small screens, and all interactive elements are touch-friendly.

---

## VPN Client

### 12. Which VPN providers work with the launch script?

The launch script supports any provider that offers WireGuard (`.conf` files) or OpenVPN (`.ovpn` files) configuration files. Popular options include Mullvad, ProtonVPN, NordVPN, Surfshark, and IVPN. The script helps you import and activate these configs.

### 13. WireGuard vs OpenVPN -- which is better?

WireGuard is generally recommended for most users:

- **WireGuard** -- Faster, lighter, simpler code, better battery life on mobile, ideal for Raspberry Pi.
- **OpenVPN** -- More mature, wider server compatibility, better at bypassing firewalls via TCP mode.

For kids and home setups, WireGuard is the easier and faster choice.

### 14. How do I import a VPN config file?

Run the launch script and select "VPN Client Setup." It will walk you through:

1. Choosing WireGuard or OpenVPN.
2. Installing the software if needed.
3. Importing your `.conf` or `.ovpn` file.
4. Activating the connection.

### 15. Does a VPN slow my internet?

Slightly. Encryption adds a small overhead. With WireGuard, the speed loss is typically under 5-10%. OpenVPN may be a bit slower. The closer the server is to your physical location, the lower the latency.

### 16. Can I use free VPNs?

You can, but be cautious. Free VPNs often have data limits, fewer servers, and some monetize your data. For learning purposes, ProtonVPN's free tier is a reputable option. The app's Launch Pad section discusses free vs. paid options in a kid-friendly way.

---

## VPN Server

### 17. Can I host a VPN server on a Raspberry Pi?

Yes. WireGuard runs excellently on Raspberry Pi (Zero, 3, 4, 5). The launch script auto-detects Pi hardware and optimizes the setup. It will install WireGuard, generate server and client keys, create configs, and even produce QR codes for mobile clients.

### 18. What port do I need to forward?

- **WireGuard** -- Port `51820/UDP` (default).
- **OpenVPN** -- Port `1194/UDP` or `1194/TCP` (default).

Forward the appropriate port on your router (e.g., Freebox) to your server's local IP address.

### 19. How do I add clients to my VPN server?

The launch script generates client configuration files automatically. By default, the Docker setup creates configs for 3 peers (configurable via the `PEERS` environment variable in `docker-compose.yml`). Each client gets its own `.conf` file and QR code in the `vpn-configs/` directory.

### 20. How many clients can connect at the same time?

WireGuard has no hard limit on peers. For a Raspberry Pi, 5-10 simultaneous clients is comfortable. For a regular server or Docker setup, dozens of clients work fine. Each client just needs its own keypair and IP in the subnet.

### 21. Is my self-hosted VPN server secure?

Yes, if configured properly. WireGuard uses modern cryptography (ChaCha20, Curve25519, BLAKE2s). Key points for security:

- Keep your server OS updated.
- Never share your server private key.
- Use strong firewall rules (only expose the VPN port).
- Distribute client configs securely.

---

## Freebox

### 22. Which Freebox models support VPN?

| Model | OpenVPN | WireGuard | IPsec IKEv2 | PPTP |
|-------|---------|-----------|-------------|------|
| **Revolution** | Yes | **No** | No | Yes |
| **Mini 4K** | Yes | **No** | No | Yes |
| **One** | Yes | **Yes** | Yes | Yes |
| **Delta** | Yes | **Yes** | Yes | Yes |
| **Pop** | Yes | **Yes** | Yes | Yes |
| **Ultra** | Yes | **Yes** | Yes | Yes |

All models support VPN Server + VPN Client modes. Newer models (One/Delta/Pop/Ultra) support WireGuard natively. Revolution and Mini 4K are OpenVPN only.

### 23. How do I access Freebox OS?

1. Connect to your Freebox network (WiFi or Ethernet)
2. Open browser → `http://mafreebox.freebox.fr` or `http://192.168.1.254`
3. First time: confirm on the Freebox LCD screen, then set admin password
4. Navigate to **Paramètres → Mode Avancé → VPN** (Settings → Advanced → VPN)

**Freebox OS version 4.9** is confirmed working with WireGuard server.

### 24. Can I use the Freebox as both VPN client and server?

Yes! Both modes work simultaneously on all supported models:
- **VPN Client**: Routes all home traffic through an external VPN provider (NordVPN, ProtonVPN, etc.)
- **VPN Server**: Lets you connect BACK to your home network when you're away

### 25. What VPN protocols does the Freebox support?

Newer models (One, Delta, Pop, Ultra) support:
- **WireGuard** (recommended — faster, modern, QR code import)
- **OpenVPN Routé** (Layer 3 routed mode)
- **OpenVPN Bridgé** (Layer 2 bridged mode)
- **IPsec IKEv2**
- **PPTP** (legacy, not recommended)

Revolution and Mini 4K support:
- **OpenVPN** (both Routé and Bridgé)
- **PPTP** (legacy)

### 26. How do I set up WireGuard Server on my Freebox?

Step-by-step (confirmed working on Freebox OS 4.9):

1. Open Freebox OS → **Paramètres → Serveur VPN → WireGuard**
2. Check **"Activer"** (Enable)
3. **Port**: default or custom (e.g., `62088`) — non-standard ports work fine
4. **MTU**: `1360` (default, works well)
5. Click **"Appliquer"** (Apply)
6. Go to **Utilisateurs** → **"Ajouter un utilisateur"**
7. Set **Login** (e.g., `phone`), **Type: WireGuard**, **Keepalive: 25**, check **Clé pré-partagée**
8. Click **"Sauvegarder"**
9. Go back to **WireGuard** page → download config file or scan QR code

### 27. The VPN IP is 192.168.27.x — is that normal?

Yes! The Freebox assigns WireGuard peers to a separate subnet (`192.168.27.0/24`), different from your home LAN (`192.168.1.0/24`). This is by design:
- `192.168.27.65` = your device's VPN tunnel IP
- `192.168.1.x` = your home network (still accessible through the tunnel)

### 28. I created a user as IPsec/OpenVPN but want WireGuard. How to switch?

You cannot change the "Type de serveur VPN" after creation. You must:
1. **Delete** the user (click the trash icon 🗑️)
2. **Recreate** with the same name, selecting **"WireGuard"** as the type
3. Don't forget: **Keepalive: 25**, **Clé pré-partagée: checked**

### 29. How do I test that my VPN actually works?

The **Ultimate Phone Test**:
1. Turn **OFF WiFi** on your phone → use **4G/5G** (mobile data)
2. Open WireGuard app → toggle your tunnel **ON**
3. Open browser → type `192.168.1.254`
4. **If you see Freebox OS → VPN is working!** You're accessing your home router from mobile data through the encrypted tunnel
5. Disconnect VPN → try again → should **fail** (proves VPN was doing the work)

Also check:
- [whatismyip.com](https://whatismyip.com) → should show your Freebox's public IP
- [dnsleaktest.com](https://dnsleaktest.com) → Extended Test → no leaks

### 30. Should I start with VPN Server or Client?

**Start with the Server.** Here's why:
- You own a Freebox — it's a **free VPN server** (no subscription needed)
- You learn more — understanding the server makes client setup trivial
- You control everything — your keys, your logs, your rules

Recommended order:
1. Set up WireGuard Server on Freebox (5 min)
2. Create client configs for phone/laptop
3. Connect phone from 4G — verify it works
4. Then optionally: set up VPN Client on Revolution to route home traffic through a provider

### 31. What settings should I use for WireGuard peers?

Confirmed working configuration:
- **Keepalive: 25** — essential for mobile (keeps connection alive behind NAT)
- **Clé pré-partagée: Yes** — adds post-quantum security layer
- **IP Fixe**: let Freebox auto-assign (192.168.27.x range)
- **Port**: any works (default 51820 or custom like 62088)
- **MTU**: 1360 (Freebox default, works well)

### 32. How do I import the config on my phone?

**Fastest method — QR Code:**
1. Install WireGuard app (App Store / Play Store)
2. In Freebox OS → WireGuard page → click **QR Code** icon next to your user
3. In WireGuard app → tap **"+"** → **"Create from QR code"** → scan → done!

**File method:**
1. Download the `.conf` file from Freebox OS
2. Send to phone (email, AirDrop, cloud)
3. Tap the file → "Open in WireGuard?" → Allow

### 33. Can I see connected devices in the web app?

Yes! Open `vpn-dashboard.html` — it has 3 modes:
- **🎮 Demo**: simulated devices to see what it looks like
- **📋 Paste**: paste `sudo wg show` output → visualizes as device cards
- **📡 Freebox Live**: connects to Freebox API at `mafreebox.freebox.fr` for real-time data

The Freebox "Connexions" page (Serveur VPN → État → Connexions) also shows connected peers with IP, data transferred, and connection time.

---

## Docker

### 26. How do I deploy with Docker?

From the project root:

```bash
# Web app only
docker-compose up -d

# Web app + WireGuard VPN server
# First, uncomment the wireguard section in docker-compose.yml
docker-compose up -d
```

The web app will be available at `http://localhost:8080`.

### 27. How do I update the containers?

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

This rebuilds the web app container with any changes to `index.html` and pulls the latest WireGuard image.

### 28. Where are VPN configs stored?

Client configuration files are stored in the `./vpn-configs/` directory (mapped to `/config` inside the WireGuard container). Each peer gets its own subfolder with a `.conf` file and a QR code PNG.

### 29. Can I run the Docker setup on ARM / Raspberry Pi?

Yes. The `nginx:alpine` base image supports ARM architectures. The LinuxServer WireGuard image (`lscr.io/linuxserver/wireguard`) also supports ARM. On a Pi, make sure Docker and Docker Compose are installed, then run the same commands.

---

## Troubleshooting

### 30. My VPN won't connect. What should I check?

1. **Config file** -- Make sure the `.conf` or `.ovpn` file is correct and not corrupted.
2. **Port forwarding** -- If connecting to a self-hosted server, verify the port is forwarded on your router.
3. **Firewall** -- Check that the VPN port is not blocked by your OS firewall.
4. **DNS** -- Try setting DNS to `1.1.1.1` or `8.8.8.8` in your client config.
5. **Keys** -- For WireGuard, verify the client public key is listed in the server config.

### 31. How do I check for DNS leaks?

Visit [dnsleaktest.com](https://www.dnsleaktest.com) or [ipleak.net](https://ipleak.net) while connected to your VPN. If you see your ISP's DNS servers instead of your VPN provider's, you have a DNS leak. Fix it by setting `DNS = 1.1.1.1, 8.8.8.8` in your WireGuard client config or adding `dhcp-option DNS` lines to your OpenVPN config.

### 32. My VPN connection is slow. What can I do?

- **Switch servers** -- Choose a server closer to your physical location.
- **Use WireGuard** -- It is faster than OpenVPN in most cases.
- **Check your base speed** -- Run a speed test without VPN first to establish a baseline.
- **Reduce MTU** -- Add `MTU = 1380` to your WireGuard config if you are on a network with small packet sizes.
- **Use UDP** -- If using OpenVPN, switch from TCP to UDP mode.

### 33. I can't access Freebox OS. What do I do?

- Make sure you are connected to the Freebox network (Wi-Fi or Ethernet), not through a VPN.
- Try both `http://mafreebox.freebox.fr` and `http://192.168.1.254`.
- Clear your browser cache or try an incognito window.
- Restart the Freebox if the interface is unresponsive.
- Check that the Freebox is not in bridge mode (bridge mode disables the admin interface).

### 34. Port forwarding is not working on my router. Any tips?

- Verify you are forwarding the correct port and protocol (UDP for WireGuard, UDP or TCP for OpenVPN).
- Make sure the destination IP is your server's local IP (e.g., `192.168.1.x`), not `127.0.0.1`.
- Disable UPnP conflicts if another device claimed the same port.
- Some ISPs block certain ports -- try a non-standard port like `51821` if `51820` does not work.
- On Freebox, go to Freebox OS > Port Management > Add a redirection.

### 39. How do I check if my VPN is working?

**Quick tests from any device:**
1. **IP test** — Visit [whatismyip.com](https://www.whatismyip.com). Should show VPN server IP, not your ISP.
2. **DNS test** — Visit [dnsleaktest.com](https://www.dnsleaktest.com) → Extended Test. Should not show your ISP's DNS.
3. **Home access test** — Browse to `192.168.1.254` — if Freebox OS loads, your tunnel works!
4. **Command line** — `curl ifconfig.me` (Linux/macOS) or `Invoke-RestMethod ifconfig.me` (PowerShell).

**The Ultimate Phone Test:**
1. Disconnect WiFi → use 4G
2. Connect VPN
3. Open `192.168.1.254` in browser
4. If Freebox OS loads → VPN works perfectly
5. Disconnect VPN → try again → should fail

The launch script option 4 (Status & Diagnostics) also checks IP, DNS, and VPN status automatically.

### 40. Where can I see connected VPN devices?

Three ways:
1. **Freebox OS** → Serveur VPN → État → Connexions — shows user, data transferred, IP source, IP locale, connection date
2. **vpn-dashboard.html** — our web dashboard with live Freebox API, paste mode, or demo mode
3. **Command line** — `sudo wg show` on Linux shows all peers with handshake times and data

### 41. What's the recommended architecture with two Freebox routers?

If you have a newer Freebox (WireGuard) + a Revolution (OpenVPN only):
```
📱 Phone (away)  → ⚡ Newer Freebox (WireGuard Server) → 🏠 Home
💻 Laptop (café) → ⚡ Newer Freebox (WireGuard Server) → 🏠 Home
🔴 Revolution (VPN Client) → ProtonVPN/NordVPN (optional, for privacy)
```

### 42. What is VPN Gate and how do I use it?

[VPN Gate](https://www.vpngate.net/) is a free academic VPN project from the University of Tsukuba (Japan) with ~5,000 volunteer servers worldwide. No signup needed!

**How to use:**
1. Go to [vpngate.net](https://www.vpngate.net/) → pick a server
2. Download the **OpenVPN Config File** (.ovpn)
3. Import into any OpenVPN client (including Freebox Revolution!)
4. Credentials: Username `vpn` / Password `vpn`

**Works with:** Freebox Revolution (VPN Client mode), OpenVPN Connect (phone/PC), Linux command line. Great for testing and learning — servers are volunteer-run so speeds vary.

### 43. What interactive tools are included in the project?

| Tool | File | Purpose |
|------|------|---------|
| Packet Journey | `packet-journey.html` | Watch encryption/tunneling animated |
| Attack Simulator | `attack-simulator.html` | 10-level cyber defense game |
| Config Generator | `config-generator.html` | Generate WireGuard/OpenVPN configs + QR |
| Speed Test | `speed-test.html` | Before/after VPN speed comparison |
| VPN Status | `vpn-status.html` | Live IP, location, WebRTC leak check |
| Password Generator | `password-generator.html` | Passwords, passphrases, WireGuard PSKs |
| DNS Explorer | `dns-explorer.html` | Animated DNS resolution |
| Encryption Playground | `encryption-playground.html` | Caesar/XOR/AES-256 with crack demos |
| Crypto Quiz | `crypto-quiz.html` | 50-question timed quiz |
| Phishing Detector | `phishing-detector.html` | Spot-the-phishing email game |
| Firewall Builder | `firewall-builder.html` | Build rules, test with packets |
| VPN Dashboard | `vpn-dashboard.html` | See connected devices live |
