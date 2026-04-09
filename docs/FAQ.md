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

Freebox Delta, Freebox Pop, Freebox Ultra, and Freebox Revolution support VPN features. The Freebox Mini 4K has limited support. Check your Freebox OS version -- VPN features require a recent firmware.

### 23. How do I access Freebox OS?

Open a browser and go to `http://mafreebox.freebox.fr` or `http://192.168.1.254`. Log in with your admin password. If you have never set a password, the Freebox will prompt you to create one on the LCD screen.

### 24. Can I use the Freebox as both VPN client and server?

It depends on the model. Some Freebox models support running a VPN server (to connect to your home network remotely) and configuring VPN client mode (to route all traffic through an external VPN). Check Freebox OS under Settings > VPN for available options.

### 25. What VPN protocols does the Freebox support?

The Freebox natively supports:

- **OpenVPN** (most common for Freebox VPN server)
- **PPTP** (legacy, not recommended)
- **L2TP/IPsec** (available on some models)

WireGuard is not natively supported on the Freebox, but you can run a WireGuard server on a device behind the Freebox and use port forwarding.

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

### 35. How do I check if my VPN is working?

Three quick tests:

1. **IP test** -- Visit [whatismyip.com](https://www.whatismyip.com). Your IP should match the VPN server, not your ISP.
2. **DNS test** -- Visit [dnsleaktest.com](https://www.dnsleaktest.com). Run the extended test. You should not see your ISP's DNS servers.
3. **Command line** -- Run `curl ifconfig.me` (Linux/macOS) or `Invoke-RestMethod ifconfig.me` (PowerShell). Compare the result with and without VPN.

The launch script also has a "Status & Diagnostics" option that checks your public IP, DNS, and VPN status automatically.
