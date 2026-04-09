#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🚀 Rocket Shield VPN — VPS WireGuard Server Installer
# ═══════════════════════════════════════════════════════════════
# One-command WireGuard VPN server setup on any VPS.
# Works on Ubuntu 20.04+, Debian 11+.
#
# Usage:
#   bash vps-setup.sh
#   or: curl -sSL https://raw.githubusercontent.com/abourdim/rocket-shield-vpn/main/vps-setup.sh | bash
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
CYAN='\033[0;36m' WHITE='\033[1;37m' NC='\033[0m' BOLD='\033[1m'

info()    { echo -e "${CYAN}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
error()   { echo -e "${RED}❌ $*${NC}"; exit 1; }

# ─── Banner ──────────────────────────────────────────────────
echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║  🚀 ROCKET SHIELD VPN — VPS Server Setup     ║"
echo "  ║  WireGuard VPN on any VPS, any country        ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Check root ──────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    error "Run as root: sudo bash vps-setup.sh"
fi

# ─── Check OS ────────────────────────────────────────────────
if ! command -v apt-get &>/dev/null; then
    error "This script requires apt (Ubuntu/Debian). Your OS is not supported."
fi

# ─── Config ──────────────────────────────────────────────────
WG_PORT=51820
WG_SUBNET="10.77.77"
WG_DIR="/etc/wireguard"
CONFIG_DIR="/root/vpn-clients"

echo -e "${WHITE}${BOLD}Server Configuration${NC}"
echo ""

# Port
read -rp "  WireGuard port (default $WG_PORT): " input_port
[[ -n "$input_port" ]] && WG_PORT="$input_port"

# Detect public IP
PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 api.ipify.org 2>/dev/null || echo "")
if [[ -z "$PUBLIC_IP" ]]; then
    read -rp "  Your VPS public IP: " PUBLIC_IP
    [[ -z "$PUBLIC_IP" ]] && error "Could not detect public IP"
else
    read -rp "  Public IP (detected: $PUBLIC_IP): " input_ip
    [[ -n "$input_ip" ]] && PUBLIC_IP="$input_ip"
fi

# Detect network interface
SERVER_IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}' || echo "eth0")
info "Network interface: $SERVER_IFACE"

# Number of clients
read -rp "  How many client configs to create? (default 3): " NUM_CLIENTS
NUM_CLIENTS=${NUM_CLIENTS:-3}

echo ""

# ─── Install ─────────────────────────────────────────────────
info "Updating system..."
apt-get update -qq

info "Installing WireGuard..."
apt-get install -y -qq wireguard qrencode curl iptables

# ─── Generate Server Keys ────────────────────────────────────
info "Generating server keys..."
mkdir -p "$WG_DIR" "$CONFIG_DIR"
wg genkey | tee "$WG_DIR/server_private" | wg pubkey > "$WG_DIR/server_public"
chmod 600 "$WG_DIR/server_private"

SERVER_PRIVATE=$(cat "$WG_DIR/server_private")
SERVER_PUBLIC=$(cat "$WG_DIR/server_public")

# ─── Create Server Config ────────────────────────────────────
info "Creating server config..."
cat > "$WG_DIR/wg0.conf" << EOF
# Rocket Shield VPN — WireGuard Server
# Generated: $(date -Iseconds)
# Public IP: $PUBLIC_IP
# Port: $WG_PORT

[Interface]
Address = ${WG_SUBNET}.1/24
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIVATE}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${SERVER_IFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${SERVER_IFACE} -j MASQUERADE
EOF
chmod 600 "$WG_DIR/wg0.conf"

# ─── Enable IP Forwarding ────────────────────────────────────
info "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 >/dev/null
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

# ─── Firewall ────────────────────────────────────────────────
info "Configuring firewall..."
if command -v ufw &>/dev/null; then
    ufw allow "$WG_PORT"/udp >/dev/null 2>&1
    ufw allow ssh >/dev/null 2>&1
    echo "y" | ufw enable >/dev/null 2>&1 || true
    success "UFW: port $WG_PORT/udp + SSH allowed"
else
    iptables -A INPUT -p udp --dport "$WG_PORT" -j ACCEPT
    success "iptables: port $WG_PORT/udp allowed"
fi

# ─── Generate Client Configs ─────────────────────────────────
info "Generating $NUM_CLIENTS client configs..."
echo ""

NAMES=("phone" "laptop" "tablet" "desktop" "work" "family" "backup" "extra1" "extra2" "extra3")

for i in $(seq 1 "$NUM_CLIENTS"); do
    CLIENT_NAME="${NAMES[$((i-1))]:-client$i}"
    CLIENT_IP="${WG_SUBNET}.$((i+1))"

    # Generate keys
    CLIENT_PRIVATE=$(wg genkey)
    CLIENT_PUBLIC=$(echo "$CLIENT_PRIVATE" | wg pubkey)
    CLIENT_PSK=$(wg genpsk)

    # Add peer to server config
    cat >> "$WG_DIR/wg0.conf" << EOF

# Client: $CLIENT_NAME
[Peer]
PublicKey = ${CLIENT_PUBLIC}
PresharedKey = ${CLIENT_PSK}
AllowedIPs = ${CLIENT_IP}/32
EOF

    # Create client config
    cat > "$CONFIG_DIR/${CLIENT_NAME}.conf" << EOF
# Rocket Shield VPN — Client: ${CLIENT_NAME}
# Server: ${PUBLIC_IP}:${WG_PORT}
# Generated: $(date -Iseconds)

[Interface]
Address = ${CLIENT_IP}/24
PrivateKey = ${CLIENT_PRIVATE}
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = ${SERVER_PUBLIC}
PresharedKey = ${CLIENT_PSK}
Endpoint = ${PUBLIC_IP}:${WG_PORT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    echo -e "  ${GREEN}✅ ${CLIENT_NAME}${NC} → ${CLIENT_IP} → ${CONFIG_DIR}/${CLIENT_NAME}.conf"
done

# ─── Start WireGuard ──────────────────────────────────────────
echo ""
info "Starting WireGuard..."
wg-quick up wg0
systemctl enable wg-quick@wg0 2>/dev/null

# ─── Show QR Codes ────────────────────────────────────────────
echo ""
echo -e "${WHITE}${BOLD}═══ QR Codes (scan with WireGuard app) ═══${NC}"
echo ""

for i in $(seq 1 "$NUM_CLIENTS"); do
    CLIENT_NAME="${NAMES[$((i-1))]:-client$i}"
    if [[ -f "$CONFIG_DIR/${CLIENT_NAME}.conf" ]]; then
        echo -e "${CYAN}─── ${CLIENT_NAME} ───${NC}"
        qrencode -t ANSIUTF8 < "$CONFIG_DIR/${CLIENT_NAME}.conf" 2>/dev/null || echo "(qrencode failed — use the .conf file instead)"
        echo ""
    fi
done

# ─── Summary ──────────────────────────────────────────────────
echo -e "${GREEN}${BOLD}"
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║  🎉 VPN SERVER IS RUNNING!                    ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${WHITE}Server Public Key:${NC} $SERVER_PUBLIC"
echo -e "  ${WHITE}Endpoint:${NC}          $PUBLIC_IP:$WG_PORT"
echo -e "  ${WHITE}Subnet:${NC}            ${WG_SUBNET}.0/24"
echo -e "  ${WHITE}Clients:${NC}           $NUM_CLIENTS configs in $CONFIG_DIR/"
echo ""
echo -e "  ${WHITE}Location:${NC}          $(curl -s --max-time 3 ipapi.co/$PUBLIC_IP/country_name 2>/dev/null || echo 'unknown')"
echo ""
echo -e "  ${CYAN}To add more clients later:${NC}"
echo "  Edit $WG_DIR/wg0.conf and run: wg syncconf wg0 <(wg-quick strip wg0)"
echo ""
echo -e "  ${CYAN}To check status:${NC}"
echo "  sudo wg show"
echo ""
echo -e "  ${CYAN}Client configs:${NC}"
ls -la "$CONFIG_DIR/"*.conf 2>/dev/null
echo ""
echo -e "  ${GREEN}Scan QR codes above with the WireGuard app on your phone!${NC}"
echo -e "  ${GREEN}Or copy .conf files to your devices.${NC}"
echo ""
echo -e "  🚀 Stay safe, Commander!"
