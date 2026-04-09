# Docker and Docker Compose Guide

Run the Rocket Shield VPN web app (and optionally a WireGuard VPN server) using Docker.

---

## Prerequisites

### Install Docker and Docker Compose

| Platform | Installation |
|----------|-------------|
| Ubuntu/Debian | `sudo apt install docker.io docker-compose -y && sudo usermod -aG docker $USER` (log out and back in) |
| Fedora | `sudo dnf install docker docker-compose -y && sudo systemctl enable --now docker` |
| macOS | Install [Docker Desktop](https://docs.docker.com/desktop/install/mac-install/) |
| Windows | Install [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/) (requires WSL2) |
| Raspberry Pi | `sudo apt install docker.io docker-compose -y && sudo usermod -aG docker $USER` |

Verify installation:

```bash
docker --version
docker-compose --version
```

---

## Quick Start

```bash
git clone https://github.com/abourdim/rocket-shield-vpn.git
cd rocket-shield-vpn
docker-compose up -d
```

Open `http://localhost:8080` in your browser. The educational web app is running.

To stop:

```bash
docker-compose down
```

---

## Services

The `docker-compose.yml` defines two services:

### webapp

- **Image**: Built from the included `Dockerfile` (nginx:alpine)
- **Container name**: `rocket-shield-web`
- **Port**: `8080` on the host, mapped to `80` in the container
- **Purpose**: Serves the educational web app (`index.html`)
- **Health check**: Runs every 30 seconds, checks `http://localhost/`
- **Restart policy**: `unless-stopped`

### wireguard (Optional)

- **Image**: `lscr.io/linuxserver/wireguard:latest` (LinuxServer.io)
- **Container name**: `rocket-shield-vpn`
- **Port**: `51820/udp` on the host
- **Purpose**: Full WireGuard VPN server
- **Default state**: Commented out in `docker-compose.yml`
- **Capabilities**: `NET_ADMIN`, `SYS_MODULE`
- **Restart policy**: `unless-stopped`

---

## Configuration

### Environment Variables for WireGuard Container

When you enable the WireGuard service, configure it with these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` | User ID for file ownership |
| `PGID` | `1000` | Group ID for file ownership |
| `TZ` | `Europe/Paris` | Timezone ([list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)) |
| `SERVERURL` | `auto` | Your public IP or domain. `auto` detects it automatically |
| `SERVERPORT` | `51820` | WireGuard listening port |
| `PEERS` | `3` | Number of client configs to generate (number or comma-separated names like `phone,laptop,tablet`) |
| `PEERDNS` | `1.1.1.1,8.8.8.8` | DNS servers for clients |
| `INTERNAL_SUBNET` | `10.66.66.0/24` | VPN internal subnet |
| `ALLOWEDIPS` | `0.0.0.0/0` | Client allowed IPs (route all traffic through VPN) |
| `LOG_CONFS` | `true` | Log generated client configs to container output |

---

## Enable the WireGuard VPN Server

By default, only the web app runs. To enable the VPN server:

### Step 1: Edit docker-compose.yml

Open `docker-compose.yml` and uncomment the entire `wireguard` section (remove the `#` at the start of each line):

```yaml
  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: rocket-shield-vpn
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Paris
      - SERVERURL=auto
      - SERVERPORT=51820
      - PEERS=3
      - PEERDNS=1.1.1.1,8.8.8.8
      - INTERNAL_SUBNET=10.66.66.0/24
      - ALLOWEDIPS=0.0.0.0/0
    volumes:
      - ./vpn-configs:/config
      - /lib/modules:/lib/modules:ro
    ports:
      - "51820:51820/udp"
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
```

### Step 2: Configure

Adjust the environment variables as needed:
- Set `TZ` to your timezone
- Set `PEERS` to the number of clients you want
- Set `SERVERURL` to your public IP or domain (or leave as `auto`)

### Step 3: Start

```bash
docker-compose up -d
```

### Step 4: Check Logs

```bash
docker-compose logs wireguard
```

The logs will show the generated client configurations and QR codes.

---

## Client Configs

When the WireGuard container starts, it generates client configurations automatically.

### Location

Client configs are stored in:

```
./vpn-configs/peer1/
./vpn-configs/peer2/
./vpn-configs/peer3/
...
```

Each peer directory contains:
- `peer1.conf` -- WireGuard client configuration file
- `peer1.png` -- QR code image for mobile import
- `privatekey-peer1` -- Client private key
- `publickey-peer1` -- Client public key
- `presharedkey-peer1` -- Preshared key for extra security

### QR Codes

QR codes are auto-generated as PNG images in each peer directory. You can also view them in the container logs:

```bash
docker-compose logs wireguard | grep -A 50 "peer1"
```

### How to Use on Phone or Laptop

**Phone (iOS/Android):**
1. Install the WireGuard app.
2. Open the app and tap **+** > **Scan from QR Code**.
3. Scan the QR code from the PNG file or container logs.
4. Toggle the connection on.

**Laptop:**
1. Install WireGuard.
2. Copy the `.conf` file to your device.
3. Import: `sudo cp peer1.conf /etc/wireguard/peer1.conf`
4. Connect: `sudo wg-quick up peer1`

---

## Updating

Pull the latest images and recreate containers:

```bash
docker-compose pull
docker-compose up -d
```

To rebuild the web app container (after changes to `index.html`):

```bash
docker-compose build --no-cache webapp
docker-compose up -d
```

---

## ARM / Raspberry Pi

The Docker setup works on ARM-based devices including Raspberry Pi.

- The `nginx:alpine` image supports `arm64` and `armv7`.
- The LinuxServer WireGuard image (`lscr.io/linuxserver/wireguard`) supports `arm64`.
- On Pi 3B+ (armv7), verify image compatibility. The `arm64` variant requires a 64-bit OS.

### Performance Considerations

- Docker adds a small overhead compared to running WireGuard natively. For maximum throughput on a Pi, consider native installation (see [RASPBERRY-PI.md](RASPBERRY-PI.md)).
- The nginx web app container is negligible in resource usage.
- Monitor with: `docker stats`

---

## Custom Dockerfile

The project includes a `Dockerfile` for the web app.

### How It Works

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
COPY icon-512.png /usr/share/nginx/html/icon-512.png
```

It uses `nginx:alpine` as the base image (very small, about 7 MB), copies the single HTML file and icon, and configures nginx to serve it with gzip compression and a health check.

### Building a Custom Image

```bash
docker build -t rocket-shield-vpn:latest .
docker run -d -p 8080:80 rocket-shield-vpn:latest
```

### Adding SSL/TLS with Let's Encrypt

To serve the web app over HTTPS, you can add a reverse proxy with automatic certificate management.

Create a `docker-compose.override.yml`:

```yaml
services:
  caddy:
    image: caddy:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
    depends_on:
      - webapp

volumes:
  caddy_data:
```

Create a `Caddyfile`:

```
your-domain.com {
    reverse_proxy webapp:80
}
```

Replace `your-domain.com` with your actual domain. Caddy automatically obtains and renews Let's Encrypt certificates.

Then start:

```bash
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

---

## Troubleshooting

### Container Will Not Start

```bash
# Check logs for errors
docker-compose logs webapp
docker-compose logs wireguard

# Verify Docker is running
sudo systemctl status docker

# Check disk space
df -h
```

### Port Conflicts

If port 8080 or 51820 is already in use:

```bash
# Find what is using the port
sudo lsof -i :8080
sudo lsof -i :51820
```

Change the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "9090:80"    # Use port 9090 instead of 8080 for the web app
```

### Kernel Modules Missing (WireGuard)

The WireGuard container requires the WireGuard kernel module on the host:

```bash
# Check if the module is loaded
lsmod | grep wireguard

# Load it manually
sudo modprobe wireguard

# If not available, install kernel headers
sudo apt install linux-headers-$(uname -r) -y
```

On some systems (e.g., older kernels), WireGuard may need to be installed on the host even when running in Docker.

### Permission Issues

If the container cannot write to `./vpn-configs/`:

```bash
# Fix ownership
sudo chown -R 1000:1000 ./vpn-configs/

# Or set PUID/PGID to match your user
id    # Note your UID and GID
```

Update `PUID` and `PGID` in `docker-compose.yml` to match your user ID.
