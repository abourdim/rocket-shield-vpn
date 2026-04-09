# WireGuard Complete Reference Guide

## 1. Introduction

### What is WireGuard?

WireGuard is a modern, high-performance VPN protocol designed to be simpler, faster, and more secure than traditional solutions like OpenVPN and IPSec. The entire codebase consists of roughly 4,000 lines of code, making it significantly easier to audit compared to the hundreds of thousands of lines found in competing implementations.

### Key Features

- **Minimal codebase**: ~4,000 lines of code (vs ~100,000 for OpenVPN, ~400,000 for IPSec)
- **Modern cryptography**: ChaCha20 for symmetric encryption, Poly1305 for authentication, Curve25519 for key exchange, BLAKE2s for hashing, SipHash24 for hashtable keys, HKDF for key derivation
- **Kernel-level implementation**: Runs as a Linux kernel module (userspace implementations available for other platforms)
- **Stealth by default**: Does not respond to unauthenticated packets; invisible to port scanners
- **Roaming support**: Seamlessly handles IP address changes (mobile-friendly)
- **Built-in simplicity**: No certificate authorities, no complex configuration, just public/private key pairs

### Protocol Comparison

| Feature | WireGuard | OpenVPN | IPSec/IKEv2 |
|---|---|---|---|
| **Codebase size** | ~4,000 lines | ~100,000 lines | ~400,000 lines |
| **Encryption** | ChaCha20-Poly1305 | AES-256-GCM / CBC | AES-256-GCM / CBC |
| **Key exchange** | Curve25519 | RSA / ECDH | RSA / ECDH |
| **Transport** | UDP only | UDP or TCP | UDP (ESP) |
| **Speed** | Excellent | Good | Good |
| **Latency** | Very low | Moderate | Moderate |
| **Handshake time** | 1 RTT | Multi-step TLS | Multi-step IKE |
| **Connection state** | Stateless | Stateful | Stateful |
| **Auditability** | Very easy | Difficult | Very difficult |
| **Mobile roaming** | Native | Reconnect needed | Good (MOBIKE) |
| **Default port** | 51820/UDP | 1194/UDP | 500,4500/UDP |

---

## 2. How It Works

### Cryptokey Routing

WireGuard associates public keys with a list of allowed IP addresses. Each network interface has a private key and a list of peers. Each peer has a public key and a set of allowed IPs. When sending a packet, WireGuard looks at the destination IP, finds the peer whose `AllowedIPs` list contains that address, encrypts the packet with that peer's public key, and sends it to that peer's endpoint.

When receiving a packet, WireGuard decrypts it, checks the source IP against the peer's `AllowedIPs`, and if it matches, accepts the packet. This creates a simple and elegant routing table based on cryptographic keys.

### Handshake Process

WireGuard uses the **Noise Protocol Framework** (specifically `Noise_IKpsk2`) for its handshake:

1. **Initiator sends** a message containing their ephemeral public key and encrypted static public key
2. **Responder replies** with their ephemeral public key, encrypted static public key, and an empty encrypted payload
3. Both sides derive symmetric session keys from the shared secrets
4. The handshake completes in **1 round trip** (1-RTT)
5. Session keys are **rotated every 2 minutes** or after 2^64 - 2^16 - 1 messages

A new handshake is initiated if no data has been received for 5 minutes (the `REKEY_AFTER_TIME` constant).

### UDP-Based Stateless Design

- WireGuard operates exclusively over **UDP** (no TCP option)
- The protocol is **stateless**: there is no concept of a "connection"
- Peers are identified solely by their public key
- If a peer changes IP address (e.g., switching from Wi-Fi to cellular), WireGuard updates the endpoint automatically upon receiving a valid authenticated packet from the new address
- No traffic is sent unless there is data to transmit (silent when idle)

---

## 3. Configuration Reference -- [Interface] Section

The `[Interface]` section defines the local VPN interface settings.

| Parameter | Required | Description | Example |
|---|---|---|---|
| `Address` | Yes | IP address(es) for the VPN interface in CIDR notation. Multiple addresses can be comma-separated for dual-stack (IPv4+IPv6). | `10.0.0.1/24, fd00::1/64` |
| `ListenPort` | Server: Yes, Client: No | UDP port WireGuard listens on. Clients can omit this to use a random port. | `51820` |
| `PrivateKey` | Yes | The base64-encoded private key for this interface. Generated with `wg genkey`. | `yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=` |
| `DNS` | No | DNS server(s) to use when the tunnel is active. Comma-separated. Only used by `wg-quick`. | `1.1.1.1, 1.0.0.1` |
| `MTU` | No | Maximum Transmission Unit. Default is `1420` for IPv4 and `1400` for IPv6. Adjust lower if experiencing fragmentation. | `1380` |
| `Table` | No | Routing table to use. `auto` (default) uses the default table; `off` disables route creation; or specify a custom table number. | `auto` |
| `PreUp` | No | Command(s) executed before the interface is brought up. Multiple commands can be specified on separate lines. | `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE` |
| `PostUp` | No | Command(s) executed after the interface is brought up. Commonly used for firewall/NAT rules. | `iptables -A FORWARD -i %i -j ACCEPT` |
| `PreDown` | No | Command(s) executed before the interface is taken down. Used to clean up resources. | `iptables -D FORWARD -i %i -j ACCEPT` |
| `PostDown` | No | Command(s) executed after the interface is taken down. Used to remove firewall rules. | `iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE` |
| `FwMark` | No | 32-bit firewall mark for outgoing packets. Used for policy routing. `off` disables. | `0x1234` |
| `SaveConfig` | No | If `true`, the current configuration is saved to the config file on shutdown. Useful for dynamically added peers. | `true` |

**Note**: `%i` in Pre/PostUp/Down commands is replaced by the interface name (e.g., `wg0`).

---

## 4. Configuration Reference -- [Peer] Section

The `[Peer]` section defines a remote peer. Multiple `[Peer]` sections can exist in a single config file.

| Parameter | Required | Description | Example |
|---|---|---|---|
| `PublicKey` | Yes | The base64-encoded public key of the remote peer. Generated from the peer's private key using `wg pubkey`. | `xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=` |
| `PresharedKey` | No | A base64-encoded pre-shared key for additional symmetric encryption layer (post-quantum resistance). Generated with `wg genpsk`. Must be identical on both peers. | `E8nRpPGfh0dMXVIrm1VvDWdN7MjP0LlpgMgK8FU3IlE=` |
| `AllowedIPs` | Yes | Comma-separated list of IP ranges this peer is allowed to send/receive. Acts as both a routing table and an ACL. Use `0.0.0.0/0, ::/0` to route all traffic. | `10.0.0.2/32, 192.168.1.0/24` |
| `Endpoint` | Client: Yes, Server: No | The public IP address and port of the remote peer (`host:port`). Required for the initiating side. Updates dynamically upon receiving valid packets. | `vpn.example.com:51820` |
| `PersistentKeepalive` | No | Interval in seconds to send keepalive packets. Useful for NAT traversal. Set to `25` for most NAT environments. `0` or omitted disables keepalive. | `25` |

### AllowedIPs Explained

- `0.0.0.0/0, ::/0` -- Route ALL traffic through the peer (full tunnel)
- `10.0.0.0/24` -- Only route traffic destined for 10.0.0.0/24 through the peer (split tunnel)
- `10.0.0.2/32` -- Only allow this specific IP from this peer (typical server config for a client)

---

## 5. Key Generation

### Generate a Private Key

```bash
wg genkey
```

Output: a base64-encoded 32-byte Curve25519 private key.

### Generate a Public Key from a Private Key

```bash
echo "<private-key>" | wg pubkey
```

### Generate a Pre-Shared Key

```bash
wg genpsk
```

### Full Key Pair Generation (One-liner)

```bash
wg genkey | tee privatekey | wg pubkey > publickey
```

### Generate Key Pair with Pre-Shared Key

```bash
# Server key pair
wg genkey | tee server_private.key | wg pubkey > server_public.key

# Client key pair
wg genkey | tee client_private.key | wg pubkey > client_public.key

# Pre-shared key (one per peer pair)
wg genpsk > preshared.key

# Set restrictive permissions
chmod 600 server_private.key client_private.key preshared.key
```

---

## 6. Example Configurations

### 6.1 Client Configuration (Connecting to a VPN Provider)

```ini
# /etc/wireguard/wg0.conf -- Client config
# Connects to a commercial VPN provider for privacy

[Interface]
# Private key for this client (never share this)
PrivateKey = gI6EdUSYvn8ugXOt8QQD6Yc+JyiZi6DPfSoKj0dVWc=

# VPN IP address assigned by the provider
Address = 10.66.66.2/32, fd42:42:42::2/128

# Use provider's DNS to prevent DNS leaks
DNS = 10.66.66.1, fd42:42:42::1

[Peer]
# Public key of the VPN server
PublicKey = HIgo9xNzJMWLKASShiTqIybxR0V1tB1ZR05LRQK1stM=

# Optional: extra layer of encryption
PresharedKey = GKe3JWusBHO3zNRBmp7WzsGJ7HPN5UfczPnMg1QfYFM=

# Route ALL traffic through the VPN (full tunnel)
AllowedIPs = 0.0.0.0/0, ::/0

# VPN server's public address
Endpoint = vpn.example.com:51820

# Keep connection alive behind NAT
PersistentKeepalive = 25
```

### 6.2 Server Configuration

```ini
# /etc/wireguard/wg0.conf -- Server config
# Hub server accepting multiple clients

[Interface]
# Server's private key
PrivateKey = uJvFkHFEYMM7qXYD5sLXAGpBCoBf2I4TlxghJdjn1Ho=

# Server's VPN IP address -- the /24 defines the subnet
Address = 10.0.0.1/24, fd00:vpn::1/64

# Port to listen on (must be open in firewall)
ListenPort = 51820

# Enable IP forwarding and NAT on startup
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostUp = iptables -A FORWARD -o %i -j ACCEPT

# Clean up rules on shutdown
PostDown = iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT
PostDown = iptables -D FORWARD -o %i -j ACCEPT

# Automatically save peer changes
SaveConfig = false

# --- Client 1: Alice's laptop ---
[Peer]
PublicKey = xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg=
PresharedKey = KOfheMhF7RyE9RIj8pp4DFy6VjMgC5mYQ6gB0t5+MF8=
# Only allow Alice's assigned IP
AllowedIPs = 10.0.0.2/32

# --- Client 2: Bob's desktop ---
[Peer]
PublicKey = aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789+AbCdEfG=
PresharedKey = wX9mFA5n/dK3GpJH4Oey7ZLw4F2m7UQRi+gM4p1RYak=
AllowedIPs = 10.0.0.3/32
```

### 6.3 Road Warrior (Phone Connecting to Home Server)

**Home server config** (`/etc/wireguard/wg0.conf` on home server):

```ini
[Interface]
PrivateKey = <home-server-private-key>
Address = 10.10.0.1/24
ListenPort = 51820

PostUp = iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o eth0 -j MASQUERADE
PostUp = sysctl -w net.ipv4.ip_forward=1
PostDown = iptables -t nat -D POSTROUTING -s 10.10.0.0/24 -o eth0 -j MASQUERADE

# Phone peer
[Peer]
PublicKey = <phone-public-key>
AllowedIPs = 10.10.0.2/32
```

**Phone config** (WireGuard mobile app):

```ini
[Interface]
PrivateKey = <phone-private-key>
Address = 10.10.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = <home-server-public-key>
# Route all traffic home (full tunnel for security on public Wi-Fi)
AllowedIPs = 0.0.0.0/0, ::/0
# Use your home's public IP or dynamic DNS
Endpoint = home.example.dyndns.org:51820
PersistentKeepalive = 25
```

### 6.4 Site-to-Site (Two Networks Connected)

**Site A** (network: `192.168.1.0/24`):

```ini
[Interface]
PrivateKey = <site-a-private-key>
Address = 10.100.0.1/30
ListenPort = 51820

PostUp = sysctl -w net.ipv4.ip_forward=1

[Peer]
PublicKey = <site-b-public-key>
# Route Site B's network and VPN tunnel
AllowedIPs = 10.100.0.2/32, 192.168.2.0/24
Endpoint = site-b.example.com:51820
PersistentKeepalive = 25
```

**Site B** (network: `192.168.2.0/24`):

```ini
[Interface]
PrivateKey = <site-b-private-key>
Address = 10.100.0.2/30
ListenPort = 51820

PostUp = sysctl -w net.ipv4.ip_forward=1

[Peer]
PublicKey = <site-a-public-key>
# Route Site A's network and VPN tunnel
AllowedIPs = 10.100.0.1/32, 192.168.1.0/24
Endpoint = site-a.example.com:51820
PersistentKeepalive = 25
```

**Important**: Both sites need static routes or IP forwarding configured on their routers to direct VPN-destined traffic to the WireGuard host.

### 6.5 Split Tunnel (Only Route Specific Traffic Through VPN)

```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.0.5/32
# Do NOT set DNS here to keep using local DNS for non-VPN traffic

[Peer]
PublicKey = <server-public-key>
# Only route traffic to specific subnets through the VPN
# Corporate network + VPN subnet only; everything else goes direct
AllowedIPs = 10.0.0.0/24, 172.16.0.0/12
Endpoint = vpn.company.com:51820
PersistentKeepalive = 25
```

---

## 7. Common Commands

### Interface Management

```bash
# Bring up a WireGuard interface using wg-quick
wg-quick up wg0

# Bring down a WireGuard interface
wg-quick down wg0

# Use a specific config file
wg-quick up /etc/wireguard/client.conf
```

### Inspecting State

```bash
# Show all WireGuard interfaces and their peers
wg show

# Show a specific interface
wg show wg0

# Show only public keys
wg show wg0 public-key

# Show peer endpoints
wg show wg0 endpoints

# Show transfer statistics
wg show wg0 transfer

# Show latest handshake timestamps
wg show wg0 latest-handshakes

# Show all info in a parseable format
wg show all dump
```

### Dynamic Configuration

```bash
# Reload config without taking the interface down
wg syncconf wg0 <(wg-quick strip wg0)

# Add a peer dynamically
wg set wg0 peer <public-key> allowed-ips 10.0.0.5/32 endpoint 1.2.3.4:51820

# Remove a peer
wg set wg0 peer <public-key> remove
```

### Systemd Integration

```bash
# Enable WireGuard to start at boot
sudo systemctl enable wg-quick@wg0

# Start the service
sudo systemctl start wg-quick@wg0

# Stop the service
sudo systemctl stop wg-quick@wg0

# Check service status
sudo systemctl status wg-quick@wg0

# View logs
journalctl -u wg-quick@wg0 -f
```

### Verification

```bash
# Verify the tunnel is working
ping 10.0.0.1

# Check your public IP (should show VPN IP for full tunnel)
curl -s https://ifconfig.me

# Check for DNS leaks
curl -s https://dnsleaktest.com/json

# Verify routes are set correctly
ip route show table all | grep wg0
```

---

## 8. Troubleshooting

| Problem | Possible Cause | Solution |
|---|---|---|
| Handshake does not complete | Incorrect public/private key pairing | Verify that each side uses the OTHER peer's public key, not their own. Regenerate keys if uncertain. |
| Handshake does not complete | Firewall blocking UDP port | Open the `ListenPort` (default 51820) on the server's firewall: `ufw allow 51820/udp` |
| Handshake does not complete | Endpoint not reachable | Verify the Endpoint IP/hostname resolves correctly. Test with `nc -zuv <host> <port>`. |
| Connection drops after a while | NAT timeout evicting the UDP mapping | Add `PersistentKeepalive = 25` to the peer behind NAT. |
| No internet after connecting | IP forwarding disabled on server | Run `sysctl -w net.ipv4.ip_forward=1` and add it to `/etc/sysctl.conf` for persistence. |
| No internet after connecting | Missing NAT/masquerade rule | Add PostUp iptables masquerade rule to the server config (see example in Section 6.2). |
| DNS not resolving | DNS setting not applied | Ensure `DNS` is set in the `[Interface]` section. Verify `resolvconf` or `systemd-resolved` is working. |
| DNS leaking real IP | OS using system DNS instead of VPN DNS | Use a kill switch (block non-VPN DNS). On Linux: `PostUp = iptables -I OUTPUT -p udp --dport 53 -j DROP` then allow VPN DNS. |
| Slow speeds / poor throughput | MTU too high causing fragmentation | Lower MTU to 1280-1400. Test with `ping -s 1400 -M do 10.0.0.1`. |
| Slow speeds / poor throughput | CPU bottleneck (userspace implementation) | Use the kernel module on Linux. On other platforms, consider hardware with AES-NI/NEON. |
| Peer not reachable but handshake works | AllowedIPs misconfigured | Verify AllowedIPs includes the target network. On server, ensure the client's VPN IP is in AllowedIPs. |
| `RTNETLINK answers: Operation not permitted` | Running without root privileges | Run `wg-quick` commands with `sudo`. |
| Config file parse error | Syntax error in config file | Check for missing `=`, incorrect section headers, or trailing whitespace. Keys must be valid base64. |
| Peer shows 0 bytes received | One-way connectivity / asymmetric routing | Ensure both sides have correct AllowedIPs. Check that the return path is routed through the tunnel. |
| Interface shows no IP address | `Address` not set or wg-quick not used | The `Address` field is only used by `wg-quick`, not the raw `wg` tool. Use `wg-quick up`. |

---

## 9. Security Best Practices

### Key Management

- **Never reuse private keys** across multiple devices or interfaces
- **Store private keys with restrictive permissions**: `chmod 600 /etc/wireguard/wg0.conf`
- **Rotate keys periodically** (every 30-90 days for high-security environments)
- **Use pre-shared keys** (`PresharedKey`) for an additional layer of symmetric encryption that provides post-quantum resistance
- **Never commit keys to version control** -- use `.gitignore` or environment variables

### Firewall Configuration

```bash
# Only allow WireGuard UDP port
ufw allow 51820/udp

# Deny all other incoming traffic
ufw default deny incoming

# Allow outgoing
ufw default allow outgoing

# Enable firewall
ufw enable
```

### Kill Switch (Prevent Traffic Leaks)

Add these rules to prevent any traffic from bypassing the VPN:

```ini
# In the [Interface] section of the client config
PostUp = iptables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
PreDown = iptables -D OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
```

Alternative approach using `nftables`:

```ini
PostUp = nft add table ip wg-killswitch; nft add chain ip wg-killswitch output { type filter hook output priority 0 \; }; nft add rule ip wg-killswitch output oifname != "%i" ip daddr != <server-endpoint-ip> drop
PostDown = nft delete table ip wg-killswitch
```

### DNS Leak Prevention

- Always set `DNS` in the client config
- Use VPN provider's DNS or trusted resolvers (e.g., 1.1.1.1, 9.9.9.9)
- Consider running a local DNS resolver (e.g., Unbound) on the VPN server
- Test for leaks at dnsleaktest.com or ipleak.net

### Network Hardening

- Disable `SaveConfig` in production to prevent configuration drift
- Use separate key pairs for each device
- Implement network segmentation using AllowedIPs
- Monitor handshake timestamps with `wg show wg0 latest-handshakes` to detect inactive peers
- Consider running WireGuard on a non-default port to reduce automated scanning
- Use `FwMark` for advanced policy routing to prevent routing loops

### Logging and Monitoring

WireGuard intentionally does not log by default for privacy. To enable debug logging:

```bash
# Enable dynamic debug (Linux kernel module)
echo module wireguard +p > /sys/kernel/debug/dynamic_debug/control

# Disable debug logging
echo module wireguard -p > /sys/kernel/debug/dynamic_debug/control

# View kernel logs
dmesg | grep wireguard
```

For production monitoring, use `wg show` output parsed by monitoring tools (Prometheus, Telegraf, etc.) to track handshake freshness and transfer statistics.
