# Raspberry Pi Deployment Guide

Deploy Rocket Shield VPN on a Raspberry Pi for a low-power, always-on VPN server and educational web app host.

---

## Which Pi to Use

| Model | RAM | CPU | WireGuard Throughput | Recommendation |
|-------|-----|-----|---------------------|----------------|
| Pi 3B+ | 1 GB | Quad A53 1.4 GHz | ~100 Mbps | Functional, limited |
| Pi 4 (2 GB) | 2 GB | Quad A72 1.5 GHz | ~300 Mbps | Recommended |
| Pi 4 (4/8 GB) | 4-8 GB | Quad A72 1.5 GHz | ~300 Mbps | More than enough |
| Pi 5 | 4-8 GB | Quad A76 2.4 GHz | ~500+ Mbps | Best performance |
| Pi Zero 2 W | 512 MB | Quad A53 1.0 GHz | ~50 Mbps | Possible, tight on RAM |

**Recommended**: Raspberry Pi 4 with 2 GB RAM or more. It handles WireGuard, the web app, and system services comfortably.

---

## Initial Setup

### Flash Raspberry Pi OS Lite (Headless)

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. Select **Raspberry Pi OS Lite (64-bit)** -- no desktop environment needed for a server.
3. Click the gear icon (or Ctrl+Shift+X) to open advanced options:
   - Enable SSH
   - Set username and password
   - Configure Wi-Fi (optional, Ethernet is preferred)
   - Set locale and timezone
4. Flash to your SD card.
5. Insert the SD card into your Pi and power it on.

### Connect via SSH

```bash
ssh pi@<your-pi-ip>
# or if you set a custom username:
ssh <username>@<your-pi-ip>
```

Find your Pi's IP from your router admin page or use:

```bash
# From another machine on the same network
ping raspberrypi.local
```

### Set a Static IP

Edit the dhcpcd configuration:

```bash
sudo nano /etc/dhcpcd.conf
```

Add at the bottom:

```
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=1.1.1.1 8.8.8.8
```

Replace the IP addresses with values appropriate for your network. Then reboot:

```bash
sudo reboot
```

### Update the System

```bash
sudo apt update && sudo apt upgrade -y
```

---

## Install and Run the Web App

### Clone the Repository

```bash
git clone https://github.com/abourdim/rocket-shield-vpn.git
cd rocket-shield-vpn
```

### Using Python HTTP Server

```bash
python3 -m http.server 8080 --bind 0.0.0.0
```

Access from any device on your network: `http://<pi-ip>:8080`

### Using the Launch Script

```bash
chmod +x rocket-shield.sh
bash rocket-shield.sh
# Select option 1 — Launch Web App
```

The script auto-detects Raspberry Pi and shows relevant info.

### Auto-Start on Boot (systemd Service)

Create a service file:

```bash
sudo nano /etc/systemd/system/rocket-shield-web.service
```

Paste:

```ini
[Unit]
Description=Rocket Shield VPN Web App
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/rocket-shield-vpn
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 0.0.0.0
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rocket-shield-web.service
sudo systemctl start rocket-shield-web.service
```

Check status:

```bash
sudo systemctl status rocket-shield-web.service
```

---

## WireGuard VPN Server on Pi

### Install WireGuard

```bash
sudo apt install wireguard -y
```

### Use the Launch Script

The fastest way to set up a WireGuard server on Pi:

```bash
bash rocket-shield.sh
# Select option 3 > 1 (WireGuard Server)
```

The script detects the Raspberry Pi, installs WireGuard, generates keys, creates the server config, enables IP forwarding, configures the firewall, and starts the service. It also offers to enable auto-start on boot.

### Performance Tuning

**Adjust MTU** for better throughput. In `/etc/wireguard/wg0.conf`, under `[Interface]`, add:

```ini
MTU = 1420
```

Lower values (1380-1420) can improve stability on some networks. The default is typically 1420 for WireGuard.

**Increase buffer sizes** for higher throughput:

```bash
sudo sysctl -w net.core.rmem_max=2500000
sudo sysctl -w net.core.wmem_max=2500000
```

To make persistent, add to `/etc/sysctl.conf`:

```
net.core.rmem_max=2500000
net.core.wmem_max=2500000
```

### Expected Throughput

| Model | Download | Upload | Notes |
|-------|----------|--------|-------|
| Pi 3B+ | ~80-100 Mbps | ~80-100 Mbps | CPU-limited |
| Pi 4 | ~250-300 Mbps | ~250-300 Mbps | Good for most connections |
| Pi 5 | ~400-500+ Mbps | ~400-500+ Mbps | Handles gigabit well |
| Pi Zero 2 W | ~40-50 Mbps | ~40-50 Mbps | Adequate for basic use |

Throughput depends on your internet speed, encryption overhead, and network conditions. WireGuard is significantly faster than OpenVPN on ARM hardware.

---

## Network Configuration

### Static IP on the Pi

See the "Set a Static IP" section above. A static IP ensures the Pi is always reachable at the same address.

### Port Forwarding on Your Router / Freebox

You need to forward UDP port **51820** (or your chosen WireGuard port) from your router to your Pi's static IP.

**Generic router:**
1. Log in to your router admin panel (usually `192.168.1.1`).
2. Find "Port Forwarding" or "NAT" settings.
3. Add a rule: External port 51820 (UDP) to Internal IP `<pi-ip>` port 51820 (UDP).
4. Save and apply.

**Freebox-specific steps:**
1. Go to `http://mafreebox.freebox.fr`.
2. Navigate to **Freebox Settings > Port Forwarding** (Redirections de ports).
3. Click "Add a redirection" (Ajouter une redirection).
4. Configure: IP destination = your Pi's IP, port = 51820, protocol = UDP.
5. Save.

See [FREEBOX.md](FREEBOX.md) for detailed Freebox instructions.

### Dynamic DNS

If your ISP gives you a dynamic public IP (it changes periodically), set up Dynamic DNS so you can always reach your Pi.

**Duck DNS (free):**

1. Go to [duckdns.org](https://www.duckdns.org/) and sign in.
2. Create a subdomain (e.g., `my-rocket-vpn.duckdns.org`).
3. Install the update script on your Pi:

```bash
mkdir -p ~/duckdns
cat > ~/duckdns/duck.sh << 'EOF'
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=MY-SUBDOMAIN&token=MY-TOKEN&ip=" | curl -k -o ~/duckdns/duck.log -K -
EOF
chmod +x ~/duckdns/duck.sh
```

4. Add a cron job to update every 5 minutes:

```bash
crontab -e
# Add this line:
*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1
```

5. Use `my-rocket-vpn.duckdns.org` as your WireGuard endpoint instead of a raw IP.

**No-IP** works similarly -- sign up at [noip.com](https://www.noip.com/), create a hostname, and install their Dynamic Update Client (DUC).

---

## Security Hardening

### Change the Default Password

```bash
passwd
```

Use a strong password with at least 12 characters.

### SSH Key Authentication Only

On your local machine, generate a key pair (if you do not already have one):

```bash
ssh-keygen -t ed25519
```

Copy the public key to your Pi:

```bash
ssh-copy-id pi@<pi-ip>
```

Then disable password authentication on the Pi:

```bash
sudo nano /etc/ssh/sshd_config
```

Set:

```
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:

```bash
sudo systemctl restart sshd
```

### Fail2ban

Protects against brute-force login attempts.

```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Unattended Upgrades

Automatically install security updates:

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### Firewall (UFW)

```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 51820/udp
sudo ufw allow 8080/tcp    # If serving the web app
sudo ufw enable
```

Check status:

```bash
sudo ufw status verbose
```

---

## Maintenance

### Update WireGuard

```bash
sudo apt update && sudo apt upgrade wireguard -y
```

### Rotate Keys

Periodically regenerate server and client keys for security:

1. Generate new server keys.
2. Update `/etc/wireguard/wg0.conf`.
3. Regenerate client configs with the new server public key.
4. Distribute new client configs.
5. Restart: `sudo wg-quick down wg0 && sudo wg-quick up wg0`

### Monitor

```bash
# Show connected peers and traffic
sudo wg show

# System resources
htop

# Service status
sudo systemctl status wg-quick@wg0
```

### Backup Configs

```bash
# Backup WireGuard configs
sudo cp -r /etc/wireguard /home/pi/wireguard-backup

# Backup client configs
cp -r ~/rocket-shield-vpn/vpn-configs ~/vpn-configs-backup
```

### Auto-Restart on Crash (systemd)

The `wg-quick@wg0` systemd service already has restart capability. To verify:

```bash
sudo systemctl show wg-quick@wg0 | grep Restart
```

For the web app service created earlier, `Restart=always` and `RestartSec=5` handle automatic restarts.

---

## Troubleshooting

### Overheating

- **Symptom**: Pi throttles CPU, VPN throughput drops.
- **Fix**: Attach a heatsink or a small fan. Check temperature with `vcgencmd measure_temp`. The Pi throttles at 80 degrees C.
- **Tip**: The official Pi 4 case has poor ventilation. Use an open case or one with a fan.

### SD Card Corruption

- **Symptom**: Boot failures, read-only filesystem errors.
- **Fix**: Use a high-quality SD card (Samsung EVO, SanDisk Extreme). Consider booting from USB/SSD for better reliability.
- **Prevention**: Avoid frequent writes. Use `log2ram` to reduce SD card wear:

```bash
sudo apt install log2ram -y
```

### Power Supply Issues

- **Symptom**: Random crashes, lightning bolt icon on screen, "Under-voltage detected" in `dmesg`.
- **Fix**: Use the official Raspberry Pi power supply (5V 3A for Pi 4, 5V 5A for Pi 5). Avoid powering from a laptop USB port.

### Cannot Connect from Outside

1. Verify port forwarding is configured on your router (UDP 51820).
2. Check your public IP: `curl ifconfig.me`.
3. Verify WireGuard is running: `sudo wg show`.
4. Test from mobile data (not the same Wi-Fi network).
5. Check firewall: `sudo ufw status`.
6. If using Dynamic DNS, verify the hostname resolves: `nslookup my-subdomain.duckdns.org`.

### Slow VPN Speeds

1. Check Pi CPU usage with `htop` -- if near 100%, the Pi is the bottleneck.
2. Try adjusting MTU (lower values like 1380 can help on some networks).
3. Use Ethernet instead of Wi-Fi on the Pi.
4. Ensure your internet upload speed is sufficient (this limits remote download speed).
5. Consider upgrading to Pi 5 for better throughput.
