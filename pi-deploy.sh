#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🍓 Rocket Shield VPN — Raspberry Pi Full Deployment Script
# ═══════════════════════════════════════════════════════════════
# One-command Pi setup:
#   - WireGuard VPN server
#   - Pi-hole ad blocker (network-wide)
#   - Web app served via Python (systemd service)
#   - Auto-start everything on boot
#   - Firewall + security hardening
#
# Usage (run on your Raspberry Pi):
#   curl -sSL https://raw.githubusercontent.com/abourdim/rocket-shield-vpn/main/pi-deploy.sh | sudo bash
#   or: sudo bash pi-deploy.sh
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
CYAN='\033[0;36m' WHITE='\033[1;37m' NC='\033[0m' BOLD='\033[1m'

info()    { echo -e "${CYAN}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
error()   { echo -e "${RED}❌ $*${NC}"; exit 1; }
header()  { echo -e "\n${PURPLE:-$CYAN}${BOLD}═══ $* ═══${NC}\n"; }

# ─── Banner ──────────────────────────────────────────────────
clear
echo -e "${CYAN}"
cat << 'BANNER'
  ╔═══════════════════════════════════════════════╗
  ║                                               ║
  ║   🍓 RASPBERRY PI VPN DEPLOYMENT              ║
  ║   WireGuard + Pi-hole + Web App               ║
  ║                                               ║
  ╚═══════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# ─── Checks ──────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Run as root: sudo bash pi-deploy.sh"
[[ ! -f /etc/os-release ]] && error "Cannot detect OS"

. /etc/os-release
info "OS: ${PRETTY_NAME}"

# Detect Pi
IS_PI=false
if grep -qi "raspberry\|bcm" /proc/cpuinfo 2>/dev/null; then
    IS_PI=true
    success "🍓 Raspberry Pi detected"
else
    warn "Not a Raspberry Pi — script will still work on any Debian/Ubuntu"
fi

# ─── Config ──────────────────────────────────────────────────
WG_PORT=51820
WG_SUBNET="10.88.88"
WEB_PORT=8080
INSTALL_DIR="/opt/rocket-shield"
REPO_URL="https://github.com/abourdim/rocket-shield-vpn.git"

echo ""
echo -e "${WHITE}${BOLD}Deployment Options${NC}"
echo ""

read -rp "  Install WireGuard VPN server? [Y/n]: " INSTALL_WG
INSTALL_WG=${INSTALL_WG:-Y}

read -rp "  Install Pi-hole ad blocker? [Y/n]: " INSTALL_PIHOLE
INSTALL_PIHOLE=${INSTALL_PIHOLE:-Y}

read -rp "  Install web app? [Y/n]: " INSTALL_WEB
INSTALL_WEB=${INSTALL_WEB:-Y}

read -rp "  Enable security hardening (fail2ban, UFW)? [Y/n]: " INSTALL_SEC
INSTALL_SEC=${INSTALL_SEC:-Y}

echo ""

# ─── System Update ──────────────────────────────────────────
header "📦 System Update"
info "Updating package lists..."
apt-get update -qq
info "Upgrading packages..."
apt-get upgrade -y -qq
success "System updated"

# ─── Install Dependencies ────────────────────────────────────
header "📦 Installing Dependencies"
apt-get install -y -qq git curl wget python3 python3-pip ufw iptables
success "Base packages installed"

# ─── WireGuard ───────────────────────────────────────────────
if [[ "$INSTALL_WG" =~ ^[Yy]$ ]]; then
    header "⚡ WireGuard Server"

    apt-get install -y -qq wireguard qrencode
    success "WireGuard installed"

    mkdir -p /etc/wireguard
    cd /etc/wireguard

    if [[ ! -f server_private ]]; then
        wg genkey | tee server_private | wg pubkey > server_public
        chmod 600 server_private
    fi

    SERVER_PRIVATE=$(cat server_private)
    SERVER_PUBLIC=$(cat server_public)
    SERVER_IFACE=$(ip route show default | awk '{print $5; exit}' || echo "eth0")
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "your-public-ip")

    cat > wg0.conf << EOF
[Interface]
Address = ${WG_SUBNET}.1/24
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIVATE}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${SERVER_IFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${SERVER_IFACE} -j MASQUERADE

# Clients will be added below by 'pi-deploy.sh add <name>'
EOF
    chmod 600 wg0.conf

    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
    sysctl -p /etc/sysctl.d/99-wireguard.conf >/dev/null

    systemctl enable wg-quick@wg0 >/dev/null 2>&1
    wg-quick up wg0 2>/dev/null || true

    success "WireGuard server running on port ${WG_PORT}"
    echo -e "  ${WHITE}Public key:${NC} $SERVER_PUBLIC"
    echo -e "  ${WHITE}Endpoint:${NC}   $PUBLIC_IP:$WG_PORT"
fi

# ─── Pi-hole ─────────────────────────────────────────────────
if [[ "$INSTALL_PIHOLE" =~ ^[Yy]$ ]]; then
    header "🕳️ Pi-hole Ad Blocker"

    if command -v pihole &>/dev/null; then
        warn "Pi-hole already installed, skipping"
    else
        info "Installing Pi-hole (this will take a few minutes)..."
        info "Use the interactive installer to complete setup"
        curl -sSL https://install.pi-hole.net | bash || warn "Pi-hole install had issues — run manually if needed"
    fi

    success "Pi-hole setup — access at http://${LOCAL_IP:-<pi-ip>}/admin"
fi

# ─── Web App ─────────────────────────────────────────────────
if [[ "$INSTALL_WEB" =~ ^[Yy]$ ]]; then
    header "🌐 Web App"

    mkdir -p "$INSTALL_DIR"

    if [[ -d "$INSTALL_DIR/.git" ]]; then
        info "Updating existing install..."
        cd "$INSTALL_DIR"
        git pull
    else
        info "Cloning Rocket Shield VPN..."
        git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
    fi

    # systemd service
    cat > /etc/systemd/system/rocket-shield-web.service << EOF
[Unit]
Description=Rocket Shield VPN Web App
After=network.target

[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/python3 -m http.server ${WEB_PORT} --bind 0.0.0.0
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable rocket-shield-web >/dev/null 2>&1
    systemctl restart rocket-shield-web

    success "Web app running at http://${LOCAL_IP:-<pi-ip>}:${WEB_PORT}"
fi

# ─── Security Hardening ──────────────────────────────────────
if [[ "$INSTALL_SEC" =~ ^[Yy]$ ]]; then
    header "🔒 Security Hardening"

    apt-get install -y -qq fail2ban unattended-upgrades

    # UFW
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    ufw allow ssh >/dev/null 2>&1
    [[ "$INSTALL_WG" =~ ^[Yy]$ ]] && ufw allow "$WG_PORT"/udp >/dev/null 2>&1
    [[ "$INSTALL_WEB" =~ ^[Yy]$ ]] && ufw allow "$WEB_PORT"/tcp >/dev/null 2>&1
    [[ "$INSTALL_PIHOLE" =~ ^[Yy]$ ]] && ufw allow 53 >/dev/null 2>&1 && ufw allow 80/tcp >/dev/null 2>&1
    echo "y" | ufw enable >/dev/null 2>&1 || true

    # fail2ban
    systemctl enable fail2ban >/dev/null 2>&1
    systemctl restart fail2ban

    # unattended upgrades
    dpkg-reconfigure -plow unattended-upgrades >/dev/null 2>&1 || true

    success "Firewall active, fail2ban running, auto-updates enabled"
fi

# ─── Summary ──────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
cat << 'EOF'
  ╔═══════════════════════════════════════════════╗
  ║                                               ║
  ║   🎉 DEPLOYMENT COMPLETE!                     ║
  ║                                               ║
  ╚═══════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${WHITE}${BOLD}Services Running:${NC}"
[[ "$INSTALL_WG" =~ ^[Yy]$ ]] && echo -e "  ${GREEN}✅ WireGuard${NC} on port ${WG_PORT}/udp"
[[ "$INSTALL_PIHOLE" =~ ^[Yy]$ ]] && echo -e "  ${GREEN}✅ Pi-hole${NC} admin: http://${LOCAL_IP:-<pi-ip>}/admin"
[[ "$INSTALL_WEB" =~ ^[Yy]$ ]] && echo -e "  ${GREEN}✅ Web App${NC}  http://${LOCAL_IP:-<pi-ip>}:${WEB_PORT}"
[[ "$INSTALL_SEC" =~ ^[Yy]$ ]] && echo -e "  ${GREEN}✅ UFW + fail2ban + auto-updates${NC}"
echo ""

echo -e "${WHITE}${BOLD}Next Steps:${NC}"
if [[ "$INSTALL_WG" =~ ^[Yy]$ ]]; then
    echo -e "  1. Add VPN clients: ${CYAN}bash ${INSTALL_DIR}/rocket-shield.sh${NC} → option 3 → Add Client"
    echo -e "  2. Forward port ${WG_PORT}/UDP on your Freebox/router"
    echo -e "  3. Scan the QR code with WireGuard mobile app"
fi
if [[ "$INSTALL_PIHOLE" =~ ^[Yy]$ ]]; then
    echo -e "  4. Point your devices to Pi-hole DNS: ${LOCAL_IP:-<pi-ip>}"
fi
echo ""
echo -e "  ${GREEN}🚀 Stay safe, Commander!${NC}"
echo ""
