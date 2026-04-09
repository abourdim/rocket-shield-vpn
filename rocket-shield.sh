#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# 🚀 ROCKET SHIELD VPN — Mission Control Launch Script
# ═══════════════════════════════════════════════════════════════
# Cross-platform (Linux/macOS/Raspberry Pi) interactive menu
# for serving the educational web app AND setting up real VPN
# client/server configurations.
#
# Usage: bash rocket-shield.sh
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Colors & Formatting ────────────────────────────────────
RED='\033[0;31m'    GREEN='\033[0;32m'   YELLOW='\033[1;33m'
BLUE='\033[0;34m'   PURPLE='\033[0;35m'  CYAN='\033[0;36m'
WHITE='\033[1;37m'  GRAY='\033[0;90m'    NC='\033[0m'
BOLD='\033[1m'      DIM='\033[2m'

# ─── Globals ─────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_PID=""
WEB_PORT=8080
WG_INTERFACE="wg0"
WG_PORT=51820
WG_SUBNET="10.66.66"
WG_CONFIG_DIR="/etc/wireguard"
OVPN_CONFIG_DIR="/etc/openvpn"
CLIENT_CONFIG_DIR="$SCRIPT_DIR/vpn-configs"

# ─── Helpers ─────────────────────────────────────────────────
info()    { echo -e "${CYAN}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
error()   { echo -e "${RED}❌ $*${NC}"; }
header()  { echo -e "\n${PURPLE}${BOLD}═══ $* ═══${NC}\n"; }
prompt()  { echo -en "${WHITE}$* ${NC}"; }

press_enter() {
    echo ""
    prompt "Press Enter to continue..."
    read -r
}

confirm() {
    prompt "$1 [y/N]: "
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ─── OS & Platform Detection ────────────────────────────────
detect_platform() {
    OS="unknown"
    ARCH="$(uname -m)"
    IS_PI=false
    IS_ARM=false
    PKG_MGR=""
    OPEN_CMD=""

    case "$(uname -s)" in
        Linux*)
            OS="linux"
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO="${ID:-unknown}"
            fi
            # Detect Raspberry Pi
            if grep -qi "raspberry\|bcm27\|bcm28" /proc/cpuinfo 2>/dev/null; then
                IS_PI=true
            fi
            if [[ "$ARCH" == arm* || "$ARCH" == aarch64 ]]; then
                IS_ARM=true
            fi
            # Package manager
            if command -v apt-get &>/dev/null; then
                PKG_MGR="apt"
            elif command -v dnf &>/dev/null; then
                PKG_MGR="dnf"
            elif command -v pacman &>/dev/null; then
                PKG_MGR="pacman"
            fi
            OPEN_CMD="xdg-open"
            ;;
        Darwin*)
            OS="macos"
            PKG_MGR="brew"
            OPEN_CMD="open"
            ;;
        *)
            OS="unknown"
            ;;
    esac
}

detect_deps() {
    HAS_PYTHON=$(command -v python3 &>/dev/null && echo true || echo false)
    HAS_NODE=$(command -v node &>/dev/null && echo true || echo false)
    HAS_NPX=$(command -v npx &>/dev/null && echo true || echo false)
    HAS_WG=$(command -v wg &>/dev/null && echo true || echo false)
    HAS_OVPN=$(command -v openvpn &>/dev/null && echo true || echo false)
    HAS_QRENCODE=$(command -v qrencode &>/dev/null && echo true || echo false)
    HAS_CURL=$(command -v curl &>/dev/null && echo true || echo false)
    HAS_UFW=$(command -v ufw &>/dev/null && echo true || echo false)
    HAS_DOCKER=$(command -v docker &>/dev/null && echo true || echo false)
}

get_local_ip() {
    if [[ "$OS" == "macos" ]]; then
        ipconfig getifaddr en0 2>/dev/null || echo "127.0.0.1"
    else
        hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1"
    fi
}

get_public_ip() {
    if $HAS_CURL; then
        curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "unavailable"
    else
        echo "unavailable (curl not installed)"
    fi
}

install_package() {
    local pkg="$1"
    info "Installing $pkg..."
    case "$PKG_MGR" in
        apt)    sudo apt-get update -qq && sudo apt-get install -y -qq "$pkg" ;;
        dnf)    sudo dnf install -y -q "$pkg" ;;
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
        brew)   brew install "$pkg" ;;
        *)      error "Unknown package manager. Install $pkg manually."; return 1 ;;
    esac
}

# ─── ASCII Art Banner ────────────────────────────────────────
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    ██████╗  ██████╗  ██████╗██╗  ██╗███████╗████████╗
    ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝
    ██████╔╝██║   ██║██║     █████╔╝ █████╗     ██║
    ██╔══██╗██║   ██║██║     ██╔═██╗ ██╔══╝     ██║
    ██║  ██║╚██████╔╝╚██████╗██║  ██╗███████╗   ██║
    ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝
BANNER
    echo -e "${GREEN}        ███████╗██╗  ██╗██╗███████╗██╗     ██████╗"
    echo -e "        ██╔════╝██║  ██║██║██╔════╝██║     ██╔══██╗"
    echo -e "        ███████╗███████║██║█████╗  ██║     ██║  ██║"
    echo -e "        ╚════██║██╔══██║██║██╔══╝  ██║     ██║  ██║"
    echo -e "        ███████║██║  ██║██║███████╗███████╗██████╔╝"
    echo -e "        ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝${NC}"
    echo ""
    echo -e "${GRAY}        VPN for Young Explorers — Mission Control${NC}"
    echo -e "${DIM}        ─────────────────────────────────────────${NC}"

    # Platform info line
    local platform_info="${OS}"
    $IS_PI && platform_info="🍓 Raspberry Pi ($ARCH)"
    $IS_ARM && ! $IS_PI && platform_info="ARM Linux ($ARCH)"
    echo -e "${DIM}        Platform: ${platform_info} | Port: ${WEB_PORT}${NC}"
    echo ""
}

# ─── Main Menu ───────────────────────────────────────────────
show_menu() {
    echo -e "${WHITE}${BOLD}  🚀 MISSION CONTROL${NC}"
    echo -e "${GRAY}  ═══════════════════════════════════════${NC}"
    echo -e "  ${CYAN}1)${NC} 🌐 Launch Web App        ${DIM}— Serve the educational app${NC}"
    echo -e "  ${CYAN}2)${NC} 🔒 VPN Client Setup      ${DIM}— Connect to a VPN provider${NC}"
    echo -e "  ${CYAN}3)${NC} 🌍 VPN Server Setup      ${DIM}— Host your own VPN server${NC}"
    echo -e "  ${CYAN}4)${NC} 📊 Status & Diagnostics  ${DIM}— Check VPN & network status${NC}"
    echo -e "  ${CYAN}5)${NC} 🛑 Stop All Services     ${DIM}— Stop web server & VPN${NC}"
    echo -e "  ${CYAN}6)${NC} 🚪 Exit"
    echo -e "${GRAY}  ═══════════════════════════════════════${NC}"
    echo ""
    prompt "  Select mission [1-6]: "
}

# ═══════════════════════════════════════════════════════════════
# 1) LAUNCH WEB APP
# ═══════════════════════════════════════════════════════════════
serve_webapp() {
    header "🌐 LAUNCH WEB APP"

    # Check if already running
    if [[ -n "$WEB_PID" ]] && kill -0 "$WEB_PID" 2>/dev/null; then
        warn "Web server already running (PID: $WEB_PID)"
        if confirm "Restart it?"; then
            kill "$WEB_PID" 2>/dev/null || true
            WEB_PID=""
        else
            return
        fi
    fi

    # Choose port
    prompt "Port (default $WEB_PORT): "
    read -r port_input
    [[ -n "$port_input" ]] && WEB_PORT="$port_input"

    # Choose binding
    local bind_addr="0.0.0.0"
    if confirm "Bind to all interfaces (LAN access)?"; then
        bind_addr="0.0.0.0"
    else
        bind_addr="127.0.0.1"
    fi

    # Detect server method
    if $HAS_PYTHON; then
        info "Using Python HTTP server..."
        cd "$SCRIPT_DIR"
        python3 -m http.server "$WEB_PORT" --bind "$bind_addr" &>/dev/null &
        WEB_PID=$!
    elif $HAS_NPX; then
        info "Using npx serve..."
        cd "$SCRIPT_DIR"
        npx -y serve -l "$WEB_PORT" --listen "$bind_addr" &>/dev/null &
        WEB_PID=$!
    elif $HAS_NODE; then
        info "Using Node.js inline server..."
        cd "$SCRIPT_DIR"
        node -e "require('http').createServer((q,r)=>{r.end(require('fs').readFileSync('index.html'))}).listen($WEB_PORT,'$bind_addr')" &
        WEB_PID=$!
    else
        error "No Python3 or Node.js found. Install one first."
        return
    fi

    sleep 1
    local local_ip
    local_ip=$(get_local_ip)

    success "Web server running!"
    echo ""
    echo -e "  ${WHITE}Local:${NC}   http://127.0.0.1:${WEB_PORT}"
    if [[ "$bind_addr" == "0.0.0.0" ]]; then
        echo -e "  ${WHITE}Network:${NC} http://${local_ip}:${WEB_PORT}"
    fi

    # QR code for mobile access
    if $HAS_QRENCODE && [[ "$bind_addr" == "0.0.0.0" ]]; then
        echo ""
        info "Scan this QR code on your phone:"
        qrencode -t ANSIUTF8 "http://${local_ip}:${WEB_PORT}" 2>/dev/null || true
    fi

    # Auto-open browser
    if confirm "Open in browser?"; then
        $OPEN_CMD "http://127.0.0.1:${WEB_PORT}" 2>/dev/null || true
    fi

    press_enter
}

# ═══════════════════════════════════════════════════════════════
# 2) VPN CLIENT SETUP
# ═══════════════════════════════════════════════════════════════
vpn_client_menu() {
    header "🔒 VPN CLIENT SETUP"
    echo -e "  ${CYAN}1)${NC} ⚡ WireGuard Client"
    echo -e "  ${CYAN}2)${NC} 🔐 OpenVPN Client"
    echo -e "  ${CYAN}3)${NC} 📋 Show Client Status"
    echo -e "  ${CYAN}4)${NC} ⬅️  Back"
    echo ""
    prompt "  Select [1-4]: "
    read -r choice
    case "$choice" in
        1) setup_wg_client ;;
        2) setup_ovpn_client ;;
        3) show_client_status ;;
        4) return ;;
        *) warn "Invalid choice" ;;
    esac
}

setup_wg_client() {
    header "⚡ WIREGUARD CLIENT SETUP"

    # Install if needed
    if ! $HAS_WG; then
        if confirm "WireGuard not found. Install it?"; then
            case "$PKG_MGR" in
                apt) install_package wireguard ;;
                dnf) install_package wireguard-tools ;;
                pacman) install_package wireguard-tools ;;
                brew) install_package wireguard-tools ;;
            esac
            HAS_WG=true
        else
            return
        fi
    fi

    success "WireGuard is installed"

    # Import config
    echo ""
    prompt "Path to .conf file (from your VPN provider): "
    read -r conf_path

    if [[ ! -f "$conf_path" ]]; then
        error "File not found: $conf_path"
        press_enter
        return
    fi

    local conf_name
    conf_name=$(basename "$conf_path" .conf)

    if confirm "Import config as '$conf_name' and activate?"; then
        sudo cp "$conf_path" "$WG_CONFIG_DIR/${conf_name}.conf"
        sudo chmod 600 "$WG_CONFIG_DIR/${conf_name}.conf"
        success "Config imported to $WG_CONFIG_DIR/${conf_name}.conf"

        if confirm "Bring up the interface now?"; then
            sudo wg-quick up "$conf_name"
            success "WireGuard client connected!"
            echo ""
            sudo wg show "$conf_name" 2>/dev/null || true
        fi

        if confirm "Enable on boot (systemd)?"; then
            sudo systemctl enable "wg-quick@${conf_name}" 2>/dev/null
            success "Enabled on boot"
        fi
    fi

    press_enter
}

setup_ovpn_client() {
    header "🔐 OPENVPN CLIENT SETUP"

    # Install if needed
    if ! $HAS_OVPN; then
        if confirm "OpenVPN not found. Install it?"; then
            install_package openvpn
            HAS_OVPN=true
        else
            return
        fi
    fi

    success "OpenVPN is installed"

    # Import config
    echo ""
    prompt "Path to .ovpn file (from your VPN provider): "
    read -r ovpn_path

    if [[ ! -f "$ovpn_path" ]]; then
        error "File not found: $ovpn_path"
        press_enter
        return
    fi

    local ovpn_name
    ovpn_name=$(basename "$ovpn_path" .ovpn)

    if confirm "Import config as '$ovpn_name' and activate?"; then
        sudo cp "$ovpn_path" "$OVPN_CONFIG_DIR/client/${ovpn_name}.conf" 2>/dev/null || \
        sudo cp "$ovpn_path" "$OVPN_CONFIG_DIR/${ovpn_name}.conf"
        success "Config imported"

        if confirm "Connect now?"; then
            sudo openvpn --config "$ovpn_path" --daemon
            sleep 3
            success "OpenVPN client started!"
        fi
    fi

    press_enter
}

show_client_status() {
    header "📋 CLIENT STATUS"

    echo -e "${WHITE}WireGuard interfaces:${NC}"
    if $HAS_WG; then
        sudo wg show 2>/dev/null || echo "  No active WireGuard interfaces"
    else
        echo "  WireGuard not installed"
    fi

    echo ""
    echo -e "${WHITE}OpenVPN processes:${NC}"
    if pgrep -a openvpn 2>/dev/null; then
        pgrep -a openvpn
    else
        echo "  No active OpenVPN connections"
    fi

    press_enter
}

# ═══════════════════════════════════════════════════════════════
# 3) VPN SERVER SETUP
# ═══════════════════════════════════════════════════════════════
vpn_server_menu() {
    header "🌍 VPN SERVER SETUP"
    echo -e "  ${CYAN}1)${NC} ⚡ WireGuard Server"
    echo -e "  ${CYAN}2)${NC} 🔐 OpenVPN Server"
    echo -e "  ${CYAN}3)${NC} 👤 Add Client Config"
    echo -e "  ${CYAN}4)${NC} 📋 Show Server Status"
    echo -e "  ${CYAN}5)${NC} 🐳 Docker Setup"
    echo -e "  ${CYAN}6)${NC} ⬅️  Back"
    echo ""
    prompt "  Select [1-6]: "
    read -r choice
    case "$choice" in
        1) setup_wg_server ;;
        2) setup_ovpn_server ;;
        3) add_wg_client ;;
        4) show_server_status ;;
        5) docker_setup ;;
        6) return ;;
        *) warn "Invalid choice" ;;
    esac
}

setup_wg_server() {
    header "⚡ WIREGUARD SERVER SETUP"

    $IS_PI && info "🍓 Raspberry Pi detected! Optimizing for ARM..."

    # Install
    if ! $HAS_WG; then
        if confirm "WireGuard not found. Install it?"; then
            install_package wireguard
            HAS_WG=true
        else
            return
        fi
    fi

    # Check if already configured
    if [[ -f "$WG_CONFIG_DIR/$WG_INTERFACE.conf" ]]; then
        warn "WireGuard config already exists at $WG_CONFIG_DIR/$WG_INTERFACE.conf"
        if ! confirm "Overwrite existing config?"; then
            return
        fi
    fi

    # Port
    prompt "Server port (default $WG_PORT): "
    read -r port_input
    [[ -n "$port_input" ]] && WG_PORT="$port_input"

    # Generate keys
    info "Generating server keys..."
    local server_privkey server_pubkey
    server_privkey=$(wg genkey)
    server_pubkey=$(echo "$server_privkey" | wg pubkey)

    # Detect public IP
    local public_ip
    public_ip=$(get_public_ip)
    prompt "Public IP/hostname (detected: $public_ip): "
    read -r ip_input
    [[ -n "$ip_input" ]] && public_ip="$ip_input"

    # Detect default interface
    local default_iface
    default_iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}' || echo "eth0")

    # Create server config
    info "Creating server config..."
    sudo mkdir -p "$WG_CONFIG_DIR"
    sudo tee "$WG_CONFIG_DIR/$WG_INTERFACE.conf" > /dev/null << EOF
# Rocket Shield VPN Server — WireGuard
# Generated: $(date -Iseconds)
[Interface]
Address = ${WG_SUBNET}.1/24
ListenPort = ${WG_PORT}
PrivateKey = ${server_privkey}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${default_iface} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${default_iface} -j MASQUERADE

# Client peers will be added below
EOF
    sudo chmod 600 "$WG_CONFIG_DIR/$WG_INTERFACE.conf"

    # Enable IP forwarding
    info "Enabling IP forwarding..."
    sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
        echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf >/dev/null
    fi

    # Firewall
    if $HAS_UFW; then
        info "Configuring UFW firewall..."
        sudo ufw allow "$WG_PORT"/udp >/dev/null 2>&1
        success "UFW: port $WG_PORT/udp allowed"
    fi

    # Start server
    if confirm "Start WireGuard server now?"; then
        sudo wg-quick up "$WG_INTERFACE"
        success "WireGuard server is running!"
    fi

    # Enable on boot
    if confirm "Enable on boot (systemd)?"; then
        sudo systemctl enable "wg-quick@${WG_INTERFACE}" 2>/dev/null
        success "Enabled on boot"
    fi

    # Raspberry Pi tips
    if $IS_PI; then
        echo ""
        echo -e "${YELLOW}🍓 Raspberry Pi Tips:${NC}"
        echo "  • Use a static IP or set up Dynamic DNS"
        echo "  • Forward port $WG_PORT/UDP on your Freebox/router"
        echo "  • Consider a heatsink — VPN can warm up the Pi!"
        echo "  • WireGuard is very lightweight, perfect for Pi"
    fi

    # Save server info
    mkdir -p "$CLIENT_CONFIG_DIR"
    echo "$server_pubkey" > "$CLIENT_CONFIG_DIR/server_pubkey"
    echo "$public_ip" > "$CLIENT_CONFIG_DIR/server_ip"
    echo "$WG_PORT" > "$CLIENT_CONFIG_DIR/server_port"

    success "Server setup complete!"
    echo ""
    echo -e "  ${WHITE}Public Key:${NC} $server_pubkey"
    echo -e "  ${WHITE}Endpoint:${NC}  $public_ip:$WG_PORT"
    echo -e "  ${WHITE}Subnet:${NC}    ${WG_SUBNET}.0/24"
    echo ""
    info "Next: Add a client with option 3 in the VPN Server menu"

    press_enter
}

setup_ovpn_server() {
    header "🔐 OPENVPN SERVER SETUP"

    if ! $HAS_OVPN; then
        if confirm "OpenVPN not found. Install it?"; then
            install_package openvpn
            if [[ "$PKG_MGR" == "apt" ]]; then
                install_package easy-rsa
            fi
            HAS_OVPN=true
        else
            return
        fi
    fi

    info "OpenVPN server setup requires more steps than WireGuard."
    echo ""
    echo -e "  ${WHITE}Recommended approach:${NC}"
    echo "  1. Use the WireGuard server option (simpler, faster)"
    echo "  2. Or use Docker: docker-compose up (includes OpenVPN)"
    echo "  3. Or follow the official guide:"
    echo -e "     ${CYAN}https://openvpn.net/community-resources/how-to/${NC}"
    echo ""

    if confirm "Would you like to set up WireGuard instead?"; then
        setup_wg_server
    fi

    press_enter
}

add_wg_client() {
    header "👤 ADD WIREGUARD CLIENT"

    if [[ ! -f "$WG_CONFIG_DIR/$WG_INTERFACE.conf" ]]; then
        error "WireGuard server not configured. Set it up first (option 1)."
        press_enter
        return
    fi

    # Client name
    prompt "Client name (e.g., phone, laptop): "
    read -r client_name
    [[ -z "$client_name" ]] && client_name="client-$(date +%s)"

    # Find next available IP
    local existing_ips
    existing_ips=$(grep -c "AllowedIPs" "$WG_CONFIG_DIR/$WG_INTERFACE.conf" 2>/dev/null || echo "0")
    local client_ip="${WG_SUBNET}.$((existing_ips + 2))"

    # Generate client keys
    info "Generating keys for '$client_name'..."
    local client_privkey client_pubkey
    client_privkey=$(wg genkey)
    client_pubkey=$(echo "$client_privkey" | wg pubkey)

    # Read server info
    local server_pubkey server_ip server_port
    server_pubkey=$(cat "$CLIENT_CONFIG_DIR/server_pubkey" 2>/dev/null || echo "SERVER_PUBKEY")
    server_ip=$(cat "$CLIENT_CONFIG_DIR/server_ip" 2>/dev/null || get_public_ip)
    server_port=$(cat "$CLIENT_CONFIG_DIR/server_port" 2>/dev/null || echo "$WG_PORT")

    # Add peer to server config
    sudo tee -a "$WG_CONFIG_DIR/$WG_INTERFACE.conf" > /dev/null << EOF

# Client: $client_name (added $(date -Iseconds))
[Peer]
PublicKey = ${client_pubkey}
AllowedIPs = ${client_ip}/32
EOF

    # Create client config
    mkdir -p "$CLIENT_CONFIG_DIR"
    local client_conf="$CLIENT_CONFIG_DIR/${client_name}.conf"
    cat > "$client_conf" << EOF
# Rocket Shield VPN — Client: ${client_name}
# Generated: $(date -Iseconds)
[Interface]
Address = ${client_ip}/24
PrivateKey = ${client_privkey}
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = ${server_pubkey}
Endpoint = ${server_ip}:${server_port}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    # Reload server if running
    if sudo wg show "$WG_INTERFACE" &>/dev/null; then
        sudo wg syncconf "$WG_INTERFACE" <(sudo wg-quick strip "$WG_INTERFACE") 2>/dev/null || \
        warn "Restart WireGuard to apply: sudo wg-quick down $WG_INTERFACE && sudo wg-quick up $WG_INTERFACE"
    fi

    success "Client '$client_name' created!"
    echo ""
    echo -e "  ${WHITE}Config file:${NC} $client_conf"
    echo -e "  ${WHITE}Client IP:${NC}  $client_ip"
    echo ""

    # Show QR code for mobile
    if $HAS_QRENCODE; then
        info "Scan this QR code with the WireGuard mobile app:"
        echo ""
        qrencode -t ANSIUTF8 < "$client_conf"
    else
        info "Install qrencode for a mobile QR code: ${PKG_MGR} install qrencode"
    fi

    # Show config
    echo ""
    echo -e "${DIM}─── Client Config ───${NC}"
    cat "$client_conf"
    echo -e "${DIM}─────────────────────${NC}"

    press_enter
}

show_server_status() {
    header "📋 SERVER STATUS"

    echo -e "${WHITE}WireGuard Server:${NC}"
    if $HAS_WG && sudo wg show "$WG_INTERFACE" &>/dev/null; then
        sudo wg show "$WG_INTERFACE"
    else
        echo "  Not running"
    fi

    echo ""
    echo -e "${WHITE}OpenVPN Server:${NC}"
    if pgrep -a "openvpn.*server" 2>/dev/null; then
        pgrep -a "openvpn.*server"
    else
        echo "  Not running"
    fi

    echo ""
    echo -e "${WHITE}Client Configs:${NC}"
    if [[ -d "$CLIENT_CONFIG_DIR" ]]; then
        ls -la "$CLIENT_CONFIG_DIR"/*.conf 2>/dev/null || echo "  No client configs"
    else
        echo "  No configs directory"
    fi

    press_enter
}

docker_setup() {
    header "🐳 DOCKER SETUP"

    if ! $HAS_DOCKER; then
        error "Docker not found."
        echo ""
        echo -e "  Install Docker: ${CYAN}https://docs.docker.com/engine/install/${NC}"
        echo ""
        if [[ "$PKG_MGR" == "apt" ]]; then
            if confirm "Try installing Docker via apt?"; then
                install_package docker.io
                install_package docker-compose
                sudo usermod -aG docker "$USER"
                success "Docker installed! Log out and back in for group changes."
            fi
        fi
        press_enter
        return
    fi

    if [[ ! -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
        error "docker-compose.yml not found in $SCRIPT_DIR"
        press_enter
        return
    fi

    echo -e "  ${CYAN}1)${NC} Start (docker-compose up -d)"
    echo -e "  ${CYAN}2)${NC} Stop (docker-compose down)"
    echo -e "  ${CYAN}3)${NC} Status (docker-compose ps)"
    echo -e "  ${CYAN}4)${NC} Logs"
    echo -e "  ${CYAN}5)${NC} ⬅️  Back"
    echo ""
    prompt "  Select [1-5]: "
    read -r choice

    cd "$SCRIPT_DIR"
    case "$choice" in
        1) docker-compose up -d && success "Containers started!" ;;
        2) docker-compose down && success "Containers stopped!" ;;
        3) docker-compose ps ;;
        4) docker-compose logs --tail=50 ;;
        5) return ;;
    esac

    press_enter
}

# ═══════════════════════════════════════════════════════════════
# 4) STATUS & DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════
show_diagnostics() {
    header "📊 STATUS & DIAGNOSTICS"

    # System info
    echo -e "${WHITE}🖥️  System Info:${NC}"
    echo -e "  OS:       ${OS} $(uname -r)"
    echo -e "  Arch:     ${ARCH}"
    $IS_PI && echo -e "  Device:   🍓 Raspberry Pi"
    echo -e "  Uptime:   $(uptime -p 2>/dev/null || uptime)"
    if [[ "$OS" == "linux" ]]; then
        local mem_total mem_used
        mem_total=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}')
        mem_used=$(free -h 2>/dev/null | awk '/^Mem:/{print $3}')
        echo -e "  Memory:   ${mem_used} / ${mem_total}"
    fi
    echo ""

    # Network info
    echo -e "${WHITE}🌐 Network:${NC}"
    local local_ip public_ip
    local_ip=$(get_local_ip)
    echo -e "  Local IP:  ${local_ip}"
    echo -n "  Public IP: "
    public_ip=$(get_public_ip)
    echo -e "${public_ip}"
    echo ""

    # Web server status
    echo -e "${WHITE}🌐 Web Server:${NC}"
    if [[ -n "$WEB_PID" ]] && kill -0 "$WEB_PID" 2>/dev/null; then
        echo -e "  ${GREEN}Running${NC} (PID: $WEB_PID, Port: $WEB_PORT)"
    else
        echo -e "  ${RED}Not running${NC}"
    fi
    echo ""

    # VPN status
    echo -e "${WHITE}🔒 VPN Status:${NC}"
    if $HAS_WG; then
        local wg_interfaces
        wg_interfaces=$(sudo wg show interfaces 2>/dev/null)
        if [[ -n "$wg_interfaces" ]]; then
            echo -e "  WireGuard: ${GREEN}Active${NC} ($wg_interfaces)"
            sudo wg show 2>/dev/null | grep -E "peer|endpoint|latest|transfer" | sed 's/^/  /'
        else
            echo -e "  WireGuard: ${RED}Inactive${NC}"
        fi
    else
        echo -e "  WireGuard: ${GRAY}Not installed${NC}"
    fi

    if pgrep openvpn &>/dev/null; then
        echo -e "  OpenVPN:   ${GREEN}Active${NC}"
    elif $HAS_OVPN; then
        echo -e "  OpenVPN:   ${RED}Inactive${NC}"
    else
        echo -e "  OpenVPN:   ${GRAY}Not installed${NC}"
    fi
    echo ""

    # DNS leak check
    echo -e "${WHITE}🛡️  DNS Leak Check:${NC}"
    if $HAS_CURL; then
        local dns_ip
        dns_ip=$(curl -s --max-time 5 "https://1.1.1.1/cdn-cgi/trace" 2>/dev/null | grep "ip=" | cut -d= -f2)
        if [[ -n "$dns_ip" ]]; then
            echo -e "  Cloudflare sees: ${dns_ip}"
            if [[ "$dns_ip" == "$public_ip" ]]; then
                echo -e "  ${YELLOW}⚠️  Same as public IP — VPN may not be active${NC}"
            else
                echo -e "  ${GREEN}✅ Different from public IP — VPN working!${NC}"
            fi
        else
            echo "  Could not check (no internet?)"
        fi
    fi
    echo ""

    # Deps summary
    echo -e "${WHITE}📦 Dependencies:${NC}"
    echo -e "  Python3:   $($HAS_PYTHON && echo "${GREEN}✅${NC}" || echo "${RED}❌${NC}")"
    echo -e "  Node.js:   $($HAS_NODE && echo "${GREEN}✅${NC}" || echo "${RED}❌${NC}")"
    echo -e "  WireGuard: $($HAS_WG && echo "${GREEN}✅${NC}" || echo "${RED}❌${NC}")"
    echo -e "  OpenVPN:   $($HAS_OVPN && echo "${GREEN}✅${NC}" || echo "${RED}❌${NC}")"
    echo -e "  Docker:    $($HAS_DOCKER && echo "${GREEN}✅${NC}" || echo "${RED}❌${NC}")"
    echo -e "  QR Code:   $($HAS_QRENCODE && echo "${GREEN}✅${NC}" || echo "${RED}❌${NC}")"

    press_enter
}

# ═══════════════════════════════════════════════════════════════
# 5) STOP ALL SERVICES
# ═══════════════════════════════════════════════════════════════
stop_all() {
    header "🛑 STOP ALL SERVICES"

    # Web server
    if [[ -n "$WEB_PID" ]] && kill -0 "$WEB_PID" 2>/dev/null; then
        kill "$WEB_PID" 2>/dev/null
        WEB_PID=""
        success "Web server stopped"
    else
        info "Web server not running"
    fi

    # WireGuard
    if $HAS_WG && sudo wg show "$WG_INTERFACE" &>/dev/null; then
        if confirm "Stop WireGuard ($WG_INTERFACE)?"; then
            sudo wg-quick down "$WG_INTERFACE" 2>/dev/null
            success "WireGuard stopped"
        fi
    fi

    # OpenVPN
    if pgrep openvpn &>/dev/null; then
        if confirm "Stop all OpenVPN processes?"; then
            sudo killall openvpn 2>/dev/null
            success "OpenVPN stopped"
        fi
    fi

    press_enter
}

# ─── Cleanup on exit ─────────────────────────────────────────
cleanup() {
    if [[ -n "$WEB_PID" ]] && kill -0 "$WEB_PID" 2>/dev/null; then
        kill "$WEB_PID" 2>/dev/null
    fi
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════
main() {
    detect_platform
    detect_deps

    while true; do
        show_banner
        show_menu
        read -r choice
        case "$choice" in
            1) serve_webapp ;;
            2) vpn_client_menu ;;
            3) vpn_server_menu ;;
            4) show_diagnostics ;;
            5) stop_all ;;
            6|q|Q)
                echo ""
                success "Mission complete! Stay safe, Commander! 🚀"
                exit 0
                ;;
            *)
                warn "Invalid choice. Try 1-6."
                sleep 1
                ;;
        esac
    done
}

main "$@"
