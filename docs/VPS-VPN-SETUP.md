# VPS VPN Setup -- Get Any Country's IP Address

> Deploy your own WireGuard VPN server on a cheap VPS and get an IP address from **any country** -- Saudi Arabia, UAE, Japan, USA, or anywhere else.

---

## Table of Contents

1. [Why Use a VPS?](#1-why-use-a-vps)
2. [VPS Providers by Region](#2-vps-providers-by-region)
3. [Step-by-Step: Create Your VPS](#3-step-by-step-create-your-vps)
4. [Install WireGuard on the VPS](#4-install-wireguard-on-the-vps)
5. [Add Client Peers](#5-add-client-peers)
6. [Connect from Your Devices](#6-connect-from-your-devices)
7. [Verify Your IP](#7-verify-your-ip)
8. [One-Command Installer Script](#8-one-command-installer-script)
9. [Security Hardening](#9-security-hardening)
10. [Cost Optimization](#10-cost-optimization)
11. [Troubleshooting](#11-troubleshooting)
12. [Use Cases](#12-use-cases)

---

## 1. Why Use a VPS?

- **You need an IP from a specific country** (e.g., Saudi Arabia, UAE) that your regular VPN provider does not cover.
- **Full control** -- no logs, your server, your rules. Nobody else shares your IP.
- **Cheap** -- $3-7/month for an always-on server, or pay by the hour and destroy when done.
- **Works everywhere** -- any device that supports WireGuard can connect.
- **Multi-user** -- add your family members as peers on the same server at no extra cost.

---

## 2. VPS Providers by Region

| Region | Provider | Location | Price | Link |
|---|---|---|---|---|
| **Saudi Arabia** | LightNode | Jeddah / Riyadh | ~$7/mo | [lightnode.com](https://www.lightnode.com) |
| Saudi Arabia | Ultahost | Riyadh | ~$5/mo | [ultahost.com](https://www.ultahost.com) |
| Saudi Arabia | WafaiCloud | Riyadh | ~$18/mo | [wafaicloud.com](https://www.wafaicloud.com) |
| Saudi Arabia | KSA Hosting | Riyadh | ~$10/mo | [ksahosting.net](https://www.ksahosting.net) |
| **UAE / Gulf** | AWS Lightsail | Bahrain (me-south-1) | $3-5/mo (free tier) | [aws.amazon.com/lightsail](https://aws.amazon.com/lightsail) |
| UAE / Gulf | Vultr | Mumbai (closest) | $5/mo | [vultr.com](https://www.vultr.com) |
| **Japan** | Vultr | Tokyo | $5/mo | [vultr.com](https://www.vultr.com) |
| Japan | Linode (Akamai) | Tokyo | $5/mo | [linode.com](https://www.linode.com) |
| **USA** | DigitalOcean | NYC / SFO | $4/mo | [digitalocean.com](https://www.digitalocean.com) |
| USA | Vultr | Multiple US cities | $3.50/mo | [vultr.com](https://www.vultr.com) |
| USA | Linode (Akamai) | Multiple US cities | $5/mo | [linode.com](https://www.linode.com) |
| **Europe** | Hetzner | Germany / Finland | $3.49/mo | [hetzner.com](https://www.hetzner.com) |
| Europe | OVH | France / Germany | $3.50/mo | [ovhcloud.com](https://www.ovhcloud.com) |
| **General** | LightNode | 40+ locations worldwide | from $7/mo | [lightnode.com](https://www.lightnode.com) |

> **Tip**: LightNode has the widest coverage for exotic locations (Middle East, Southeast Asia, Africa). For budget-friendly choices in common regions, Vultr, Hetzner, and DigitalOcean are hard to beat.

---

## 3. Step-by-Step: Create Your VPS

1. **Sign up** at your chosen provider.
2. **Create a VPS** (also called Droplet, Instance, or Linode depending on provider):
   - **OS**: Ubuntu 22.04 LTS (or 24.04)
   - **Plan**: Cheapest available (1 vCPU, 512MB-1GB RAM is enough)
   - **Location**: Pick the country whose IP you want
3. **Note the public IP address** -- this will become your VPN endpoint.
4. **SSH into your server**:

```bash
ssh root@YOUR_VPS_IP
```

> If you are on Windows, use PowerShell, Windows Terminal, or PuTTY.

---

## 4. Install WireGuard on the VPS

SSH into your VPS and run the following commands. You can copy-paste the entire block.

```bash
# Update system and install WireGuard + QR code tool
apt update && apt install -y wireguard qrencode

# Generate server keys
wg genkey | tee /etc/wireguard/server_private | wg pubkey > /etc/wireguard/server_public
chmod 600 /etc/wireguard/server_private

# Detect the default network interface (eth0, ens3, etc.)
SERVER_IFACE=$(ip route show default | awk '{print $5; exit}')
echo "Detected interface: $SERVER_IFACE"

# Create server config
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.77.77.1/24
ListenPort = 51820
PrivateKey = $(cat /etc/wireguard/server_private)
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $SERVER_IFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $SERVER_IFACE -j MASQUERADE
EOF

chmod 600 /etc/wireguard/wg0.conf

# Enable IP forwarding (required to route traffic)
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Configure firewall
ufw allow 51820/udp
ufw allow ssh
ufw --force enable

# Start WireGuard and enable on boot
wg-quick up wg0
systemctl enable wg-quick@wg0

echo ""
echo "=== WireGuard server is running ==="
echo "Server public key: $(cat /etc/wireguard/server_public)"
echo "Listening on port: 51820/udp"
echo "VPN subnet: 10.77.77.0/24"
```

---

## 5. Add Client Peers

Run this script on the VPS each time you want to add a new device (phone, laptop, tablet, etc.).

```bash
# ---- Configuration ----
CLIENT_NAME="phone"       # Change this: phone, laptop, tablet, mom, dad, etc.
CLIENT_IP="10.77.77.2"    # Increment for each new client: .2, .3, .4, ...

# ---- Generate client keys ----
CLIENT_PRIVATE=$(wg genkey)
CLIENT_PUBLIC=$(echo "$CLIENT_PRIVATE" | wg pubkey)
SERVER_PUBLIC=$(cat /etc/wireguard/server_public)
VPS_IP=$(curl -s ifconfig.me)

# ---- Add peer to server config ----
cat >> /etc/wireguard/wg0.conf << EOF

# Client: $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUBLIC
AllowedIPs = $CLIENT_IP/32
EOF

# Reload WireGuard without dropping existing connections
wg syncconf wg0 <(wg-quick strip wg0)

# ---- Generate client config file ----
cat > /root/${CLIENT_NAME}.conf << EOF
[Interface]
Address = $CLIENT_IP/24
PrivateKey = $CLIENT_PRIVATE
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC
Endpoint = $VPS_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo ""
echo "=== Client '$CLIENT_NAME' added ==="
echo "Config saved to: /root/${CLIENT_NAME}.conf"
echo ""

# ---- Show QR code (scan from WireGuard mobile app) ----
qrencode -t ANSIUTF8 < /root/${CLIENT_NAME}.conf
```

**Example for multiple devices:**

```bash
# First device (phone)
CLIENT_NAME="phone"   CLIENT_IP="10.77.77.2"   # run script above

# Second device (laptop)
CLIENT_NAME="laptop"  CLIENT_IP="10.77.77.3"   # run script above

# Third device (mom's phone)
CLIENT_NAME="mom"     CLIENT_IP="10.77.77.4"   # run script above
```

---

## 6. Connect from Your Devices

### Android / iOS

1. Install the **WireGuard** app from Play Store or App Store.
2. Tap **+** then **Scan from QR code**.
3. Scan the QR code displayed in your terminal.
4. Toggle the tunnel **ON**.

### Windows

1. Install [WireGuard for Windows](https://www.wireguard.com/install/).
2. Copy the `.conf` file from the VPS to your PC:
   ```bash
   scp root@YOUR_VPS_IP:/root/laptop.conf .
   ```
3. Open WireGuard, click **Import tunnel(s) from file**, select the `.conf` file.
4. Click **Activate**.

### macOS

1. Install WireGuard from the Mac App Store.
2. Copy the `.conf` file:
   ```bash
   scp root@YOUR_VPS_IP:/root/laptop.conf ~/Desktop/
   ```
3. Open WireGuard, click **Import tunnel(s) from file**, select the `.conf` file.
4. Click **Activate**.

### Linux

```bash
# Copy config from VPS
scp root@YOUR_VPS_IP:/root/laptop.conf /etc/wireguard/wg-vps.conf

# Connect
sudo wg-quick up wg-vps

# Disconnect
sudo wg-quick down wg-vps

# Auto-start on boot (optional)
sudo systemctl enable wg-quick@wg-vps
```

### Freebox

- **Freebox Pop / Delta (WireGuard support)**: Go to Freebox OS > VPN Client > Add a connection > WireGuard. Import the `.conf` file.
- **Freebox Revolution (OpenVPN only)**: WireGuard is not supported. You would need to also install OpenVPN on the VPS and generate an `.ovpn` config. See [FREEBOX-REVOLUTION.md](FREEBOX-REVOLUTION.md) for OpenVPN setup details.

---

## 7. Verify Your IP

Once connected, verify that your traffic is routed through the VPS:

| Check | URL | Expected Result |
|---|---|---|
| IP Address | [whatismyip.com](https://whatismyip.com) | Shows VPS country and IP |
| Speed Test | [fast.com](https://fast.com) | Reasonable speed for your VPS plan |
| DNS Leak Test | [dnsleaktest.com](https://dnsleaktest.com) | No leaks, DNS resolves through 1.1.1.1 or 8.8.8.8 |
| IP Geolocation | [iplocation.net](https://iplocation.net) | Confirms the VPS country |

---

## 8. One-Command Installer Script

For convenience, you can use the automated installer that handles everything (server setup + interactive client creation):

```bash
curl -sSL https://raw.githubusercontent.com/abourdim/rocket-shield-vpn/main/vps-setup.sh | bash
```

This script will:
1. Install WireGuard and dependencies
2. Generate server keys and config
3. Configure firewall and IP forwarding
4. Start WireGuard
5. Prompt you to create your first client
6. Display a QR code for mobile devices

> **Note**: Always review scripts before piping to bash. You can download and inspect first:
> ```bash
> curl -sSL https://raw.githubusercontent.com/abourdim/rocket-shield-vpn/main/vps-setup.sh -o vps-setup.sh
> less vps-setup.sh
> bash vps-setup.sh
> ```

---

## 9. Security Hardening

Once your VPN is running, harden the server to prevent unauthorized access.

### Change SSH Port

```bash
# Edit SSH config
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
systemctl restart sshd

# Update firewall
ufw allow 2222/tcp
ufw delete allow ssh
```

### Disable Root Password Login (Use SSH Keys Only)

```bash
# On your LOCAL machine, generate a key if you don't have one
ssh-keygen -t ed25519

# Copy your key to the VPS
ssh-copy-id -p 2222 root@YOUR_VPS_IP

# On the VPS, disable password login
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
```

### Install fail2ban

```bash
apt install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

### Enable Automatic Security Updates

```bash
apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

### UFW Summary

```bash
ufw status verbose
# Should show:
#   2222/tcp   ALLOW IN    Anywhere   (SSH)
#   51820/udp  ALLOW IN    Anywhere   (WireGuard)
```

---

## 10. Cost Optimization

| Strategy | Details | Cost |
|---|---|---|
| **Always-on** (simplest) | Leave the VPS running 24/7 | $3-7/month |
| **On-demand** (cheapest) | Use hourly billing (LightNode, Vultr). Spin up when needed, destroy when done | ~$0.01/hour |
| **AWS Free Tier** | t3.micro in Bahrain region, free for 12 months | $0 for 1 year |
| **Share with family** | Add multiple peers to the same VPS. Everyone uses the same server | No extra cost |
| **Snapshot + destroy** | Take a snapshot of your configured VPS, destroy it, restore when needed | Snapshot storage only (~$0.05/GB/mo) |

**Tips:**
- For occasional use (e.g., accessing a Saudi bank once a week), hourly billing is the cheapest option.
- For daily use, always-on at $3-7/month is simpler and more reliable.
- AWS free tier is unbeatable if you need a Bahrain/UAE-region IP for up to 12 months.

---

## 11. Troubleshooting

| Problem | Solution |
|---|---|
| **Can't SSH into VPS** | Check that the VPS is running. Verify the IP address. Make sure your local firewall allows outbound SSH. Try: `ssh -v root@VPS_IP` for debug output. |
| **WireGuard won't start** | Check the config syntax: `wg-quick up wg0`. Look at logs: `journalctl -xeu wg-quick@wg0`. Ensure the private key file exists and has correct permissions (600). |
| **Connected but no internet** | Verify IP forwarding is enabled: `sysctl net.ipv4.ip_forward` (should be 1). Check iptables NAT rules: `iptables -t nat -L`. Make sure the interface name in PostUp/PostDown matches your actual interface (`ip route show default`). |
| **DNS not resolving** | Change DNS in the client config to `1.1.1.1, 8.8.8.8`. On Linux, check `/etc/resolv.conf` is not being overwritten by systemd-resolved. |
| **Slow speeds** | VPS location matters -- closer is faster. Check VPS bandwidth limits (some cheap plans cap at 1TB/mo). Try a different VPS provider or location. |
| **IP still shows France** | Make sure the WireGuard tunnel is active: `wg show`. Verify `AllowedIPs = 0.0.0.0/0` in the client config (routes ALL traffic through VPN). Check for DNS leaks at dnsleaktest.com. |
| **VPS provider blocks VPN** | Some providers block UDP 51820. Try changing the WireGuard port to 443 or 53 in both server and client configs. Switch to a more VPN-friendly provider (Vultr, LightNode). |
| **Connection drops** | Add `PersistentKeepalive = 25` to the client config. Check VPS uptime and resources: `htop`, `free -h`. Ensure UFW is not blocking established connections. |

---

## 12. Use Cases

| Use Case | VPS Location | Provider Suggestion |
|---|---|---|
| **Saudi Arabia IP** from France | Jeddah / Riyadh | LightNode, Ultahost |
| **UAE IP** for Emirates services | Bahrain (AWS) | AWS Lightsail (free tier) |
| **Japan IP** for Japanese content | Tokyo | Vultr, Linode |
| **US IP** for American streaming | New York / Los Angeles | DigitalOcean, Vultr |
| **Any country** where you need a local IP | Varies | LightNode (40+ locations) |

**Concrete examples:**
- Access Saudi banking apps and government portals (Absher, Tawakkalna) from France.
- Use UAE-only services (Emirates ID renewal, local streaming) from abroad.
- Access Japan-only content, games, or streaming services.
- Get a US IP for services that require an American address.
- Bypass geo-restrictions in any country where you can find a VPS provider.

---

## Quick Reference

```
VPS IP:          ___________________________
SSH Port:        ___________________________
WireGuard Port:  51820
VPN Subnet:      10.77.77.0/24
Server IP:       10.77.77.1
Client 1 (___):  10.77.77.2
Client 2 (___):  10.77.77.3
Client 3 (___):  10.77.77.4
```

---

*Part of the [Rocket Shield VPN](../README.md) documentation.*
