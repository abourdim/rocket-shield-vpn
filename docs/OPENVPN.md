# OpenVPN Complete Reference Guide

## 1. Introduction

### What is OpenVPN?

OpenVPN is a mature, battle-tested, open-source VPN solution that uses SSL/TLS for key exchange and can traverse firewalls and NAT devices. It has been in active development since 2001 and is one of the most widely deployed VPN protocols in the world.

### Key Features

- **SSL/TLS-based security**: Uses the OpenSSL library for encryption, supporting a wide range of ciphers
- **Certificate-based authentication**: Full PKI (Public Key Infrastructure) support with X.509 certificates
- **Highly configurable**: Hundreds of options for fine-tuning performance, security, and compatibility
- **Cross-platform**: Runs on Linux, Windows, macOS, FreeBSD, Android, iOS, and more
- **Proven track record**: Over 20 years of production use and multiple security audits
- **Flexible transport**: Supports both UDP (faster) and TCP (more firewall-friendly)
- **Plugin system**: Extensible via plugins for authentication (LDAP, RADIUS, PAM)

### OpenVPN 2.x vs 3.x (OpenVPN 3 / Community)

| Feature | OpenVPN 2.x | OpenVPN 3.x |
|---|---|---|
| **Architecture** | Single-process, C-based | Multi-process, C++ core library |
| **Platform** | All major platforms | Primarily client-focused (Linux, Windows, macOS, mobile) |
| **Configuration** | `.ovpn` / `.conf` files | Profile-based with backward compatibility |
| **Privileges** | Requires root/admin initially | Designed for unprivileged operation |
| **Maturity** | Production-stable | Evolving; client implementations stable |
| **Server support** | Full server + client | Client-focused; server is 2.x |
| **Plugin support** | Extensive | Limited |

**Note**: OpenVPN 2.x remains the standard for server deployments. OpenVPN 3.x is primarily a client-side modernization effort.

---

## 2. How It Works

### TLS Handshake and Certificate Chain

1. The client connects to the server on the configured port (default 1194)
2. A **TLS handshake** establishes a secure control channel
3. Both sides present their X.509 certificates, which are validated against the **Certificate Authority (CA)**
4. The server verifies the client's certificate (and optionally username/password)
5. Session keys are derived for the **data channel** encryption
6. The TLS control channel remains active for rekeying and keepalive

### Control Channel vs Data Channel

| Aspect | Control Channel | Data Channel |
|---|---|---|
| **Purpose** | Key exchange, authentication, control messages | Actual VPN traffic (user data) |
| **Encryption** | TLS 1.2/1.3 | Symmetric cipher (AES-256-GCM, ChaCha20-Poly1305) |
| **Protocol** | TLS over TCP or UDP (reliable layer built in) | UDP or TCP (raw encapsulation) |
| **Rekeying** | Manages periodic session key rotation | Uses keys provided by control channel |
| **Overhead** | Minimal (infrequent messages) | Bulk of bandwidth consumption |

### TUN vs TAP

| Mode | Layer | Use Case | Description |
|---|---|---|---|
| **TUN** | Layer 3 (IP) | Most common; routing-based VPNs | Creates a virtual point-to-point IP interface. Routes IP packets. More efficient and easier to configure. |
| **TAP** | Layer 2 (Ethernet) | Bridging, Windows network sharing, non-IP protocols | Creates a virtual Ethernet interface. Bridges Ethernet frames. Higher overhead, supports broadcast traffic. |

**Recommendation**: Use `tun` unless you specifically need Layer 2 bridging (e.g., Windows file sharing via NetBIOS, or running non-IP protocols over the VPN).

---

## 3. Server Configuration Reference

| Parameter | Required | Description | Example |
|---|---|---|---|
| `port` | No (default: 1194) | UDP or TCP port to listen on. | `1194` |
| `proto` | No (default: udp) | Protocol: `udp`, `tcp-server`, `udp6`, `tcp6-server`. | `udp` |
| `dev` | Yes | Virtual interface type: `tun` (layer 3) or `tap` (layer 2). | `tun` |
| `ca` | Yes | Path to the Certificate Authority (CA) certificate file. | `ca /etc/openvpn/ca.crt` |
| `cert` | Yes | Path to the server's signed certificate. | `cert /etc/openvpn/server.crt` |
| `key` | Yes | Path to the server's private key. Must be kept secret. | `key /etc/openvpn/server.key` |
| `dh` | Yes (RSA only) | Path to Diffie-Hellman parameters file. Not needed with ECDSA certs. | `dh /etc/openvpn/dh2048.pem` |
| `tls-auth` | Recommended | HMAC authentication for TLS control channel. Adds a shared secret layer. Direction is `0` on server, `1` on client. | `tls-auth ta.key 0` |
| `tls-crypt` | Recommended | Encrypts and authenticates all TLS control channel packets. Replaces `tls-auth`. Provides better privacy (hides certificate exchange). | `tls-crypt ta.key` |
| `tls-crypt-v2` | Optional | Per-client `tls-crypt` keys derived from a server key. Allows key revocation without regenerating all client keys. | `tls-crypt-v2 server.key` |
| `server` | Yes | VPN subnet for clients. The server takes `.1`, clients get `.2+`. Shortcut that sets up routing, ifconfig, DHCP pool. | `server 10.8.0.0 255.255.255.0` |
| `topology` | No (default: net30) | Subnet topology: `subnet` (recommended, 1 IP per client) or `net30` (legacy, 4 IPs per client). | `topology subnet` |
| `push` | No | Push configuration options to clients. Can be specified multiple times. | `push "redirect-gateway def1 bypass-dhcp"` |
| `push` (DNS) | No | Push DNS servers to clients. | `push "dhcp-option DNS 1.1.1.1"` |
| `push` (routes) | No | Push routes to clients. | `push "route 192.168.1.0 255.255.255.0"` |
| `keepalive` | Recommended | Ping interval and timeout in seconds. `10 120` means ping every 10s, timeout after 120s. | `keepalive 10 120` |
| `cipher` | Deprecated | Legacy cipher setting. Use `data-ciphers` instead in OpenVPN 2.5+. | `cipher AES-256-GCM` |
| `data-ciphers` | Recommended | Ordered list of acceptable data channel ciphers. Both sides negotiate the best mutual cipher. | `data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305` |
| `data-ciphers-fallback` | No | Fallback cipher for connections with legacy clients that do not support cipher negotiation. | `data-ciphers-fallback AES-256-CBC` |
| `auth` | No (default: SHA256) | HMAC digest algorithm for packet authentication. Used with CBC ciphers. GCM/Poly1305 ciphers handle authentication internally. | `auth SHA256` |
| `user` | Recommended | Drop privileges to this user after initialization (Linux). | `user nobody` |
| `group` | Recommended | Drop privileges to this group after initialization (Linux). | `group nogroup` |
| `persist-key` | Recommended | Do not re-read key files on restart (allows privilege drop). | `persist-key` |
| `persist-tun` | Recommended | Do not close/reopen tun/tap device on restart. | `persist-tun` |
| `status` | Recommended | Write connection status to this file at regular intervals. | `status /var/log/openvpn-status.log` |
| `log` | No | Log to file instead of syslog. `log` truncates on start; `log-append` appends. | `log-append /var/log/openvpn.log` |
| `verb` | No (default: 1) | Verbosity level: 0 (silent) to 11 (debug). 3-4 recommended for production. | `verb 3` |
| `max-clients` | No | Maximum number of concurrent client connections. | `max-clients 100` |
| `client-to-client` | No | Allow client-to-client traffic without going through server's routing. Disabled by default. | `client-to-client` |
| `duplicate-cn` | No | Allow multiple clients with the same Common Name (CN) to connect simultaneously. | `duplicate-cn` |
| `comp-lzo` | Deprecated | Legacy compression. Vulnerable to VORACLE attack. Do not use. | `comp-lzo no` |
| `compress` | No | Compression: `lz4-v2` (fast), `lzo` (legacy), or omit to disable. Compression is generally discouraged for security reasons. | `compress lz4-v2` |
| `crl-verify` | Recommended | Path to Certificate Revocation List. Rejects revoked client certificates. | `crl-verify /etc/openvpn/crl.pem` |
| `ifconfig-pool-persist` | No | Persist client IP assignments across restarts. | `ifconfig-pool-persist ipp.txt` |
| `client-config-dir` | No | Per-client configuration overrides directory. Files named by Common Name. | `client-config-dir /etc/openvpn/ccd` |
| `tls-version-min` | Recommended | Minimum TLS version. Set to `1.2` to reject older, insecure TLS versions. | `tls-version-min 1.2` |
| `reneg-sec` | No (default: 3600) | Renegotiate data channel keys after N seconds. | `reneg-sec 3600` |

---

## 4. Client Configuration Reference

| Parameter | Required | Description | Example |
|---|---|---|---|
| `client` | Yes | Shorthand that sets `pull` and `tls-client`. Identifies this as a client configuration. | `client` |
| `dev` | Yes | Must match server's device type (`tun` or `tap`). | `dev tun` |
| `proto` | Yes | Must match server's protocol. Use `tcp-client` for TCP, `udp` for UDP. | `proto udp` |
| `remote` | Yes | Server hostname/IP and port. Multiple entries for failover. | `remote vpn.example.com 1194` |
| `remote-random` | No | Randomly select from multiple `remote` entries for load balancing. | `remote-random` |
| `resolv-retry` | Recommended | Retry DNS resolution indefinitely. Useful when DNS is unreliable at startup. | `resolv-retry infinite` |
| `nobind` | Recommended | Do not bind to a specific local port (use random). | `nobind` |
| `ca` | Yes | Path to the CA certificate (or inline with `<ca>` tags). | `ca ca.crt` |
| `cert` | Conditional | Path to the client certificate. Not needed if using username/password auth only. | `cert client.crt` |
| `key` | Conditional | Path to the client private key. Not needed if using username/password auth only. | `key client.key` |
| `tls-auth` | Conditional | Must match server's tls-auth setting. Direction `1` on client (opposite of server). | `tls-auth ta.key 1` |
| `tls-crypt` | Conditional | Must match server's tls-crypt setting. No direction parameter needed. | `tls-crypt ta.key` |
| `cipher` | Deprecated | Legacy cipher; use `data-ciphers` in OpenVPN 2.5+. | `cipher AES-256-GCM` |
| `data-ciphers` | Recommended | Must include at least one cipher that the server also supports. | `data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305` |
| `auth` | No | Must match server's HMAC digest setting. | `auth SHA256` |
| `verb` | No | Verbosity (0-11). 3 is reasonable for normal use. | `verb 3` |
| `redirect-gateway` | No | Route all client traffic through the VPN. Flags: `def1` (override default gateway), `bypass-dhcp`. | `redirect-gateway def1 bypass-dhcp` |
| `auth-user-pass` | No | Prompt for username/password. Optionally provide a file with credentials. | `auth-user-pass` or `auth-user-pass creds.txt` |
| `persist-key` | Recommended | Do not re-read key files after connection reset. | `persist-key` |
| `persist-tun` | Recommended | Keep tun/tap device open across restarts. | `persist-tun` |
| `remote-cert-tls` | Recommended | Verify that the server certificate has the correct key usage (prevents MitM). Must be set to `server`. | `remote-cert-tls server` |
| `verify-x509-name` | Optional | Verify the server certificate CN or subject matches expected value. | `verify-x509-name vpn.example.com name` |
| `key-direction` | Conditional | Set direction for `tls-auth` when using inline keys in `<tls-auth>` block. | `key-direction 1` |

---

## 5. UDP vs TCP

| Aspect | UDP | TCP |
|---|---|---|
| **Speed** | Faster -- no connection overhead | Slower -- TCP-over-TCP problem, head-of-line blocking |
| **Reliability** | Application layer handles retransmission | TCP guarantees delivery (but VPN payload already has its own TCP) |
| **Firewall bypass** | May be blocked on restrictive networks | TCP 443 can masquerade as HTTPS, bypasses most firewalls |
| **Connection overhead** | None (stateless) | 3-way handshake + TLS handshake |
| **Packet overhead** | Lower (8-byte UDP header) | Higher (20-byte TCP header + options) |
| **Latency** | Lower | Higher (acknowledgments, retransmission) |
| **Use case** | Default choice; best performance | Restrictive firewalls, corporate networks |
| **Recommended** | Yes (primary) | Only when UDP is blocked |

**Why TCP-over-TCP is problematic**: When VPN payload contains TCP traffic and the VPN tunnel itself uses TCP, retransmission happens at both layers. A single dropped packet causes both the inner and outer TCP to retransmit, leading to exponential performance degradation under packet loss. This is known as the "TCP meltdown" problem.

---

## 6. Certificate Generation (Easy-RSA)

### Step 1: Install Easy-RSA

```bash
# Debian/Ubuntu
sudo apt install easy-rsa

# CentOS/RHEL
sudo yum install easy-rsa

# Or download directly
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3
```

### Step 2: Initialize the PKI

```bash
# Create a new PKI directory
./easyrsa init-pki
```

### Step 3: Build the Certificate Authority (CA)

```bash
# Build the CA (will prompt for a passphrase and Common Name)
./easyrsa build-ca

# Output: pki/ca.crt (public), pki/private/ca.key (private -- protect this!)
```

### Step 4: Generate Server Certificate

```bash
# Generate server key pair and certificate signing request
./easyrsa gen-req server nopass

# Sign the server certificate with the CA
./easyrsa sign-req server server

# Output: pki/issued/server.crt, pki/private/server.key
```

### Step 5: Generate Client Certificate

```bash
# Generate client key pair and CSR
./easyrsa gen-req client1 nopass

# Sign the client certificate
./easyrsa sign-req client client1

# Output: pki/issued/client1.crt, pki/private/client1.key
```

### Step 6: Generate Diffie-Hellman Parameters

```bash
# This can take several minutes
./easyrsa gen-dh

# Output: pki/dh.pem
```

### Step 7: Generate TLS Authentication Key

```bash
# For tls-auth (HMAC authentication)
openvpn --genkey secret ta.key

# For tls-crypt (encryption + authentication) -- same command, different usage
openvpn --genkey secret ta.key
```

### Step 8: Generate Certificate Revocation List (CRL)

```bash
# Create initial CRL
./easyrsa gen-crl

# Revoke a client certificate
./easyrsa revoke client1
./easyrsa gen-crl

# Output: pki/crl.pem (copy to server, reference in config)
```

### Summary of Generated Files

| File | Location | Purpose | Deploy To |
|---|---|---|---|
| `ca.crt` | `pki/ca.crt` | CA certificate (public) | Server + all clients |
| `ca.key` | `pki/private/ca.key` | CA private key (protect!) | Offline/secure storage only |
| `server.crt` | `pki/issued/server.crt` | Server certificate | Server only |
| `server.key` | `pki/private/server.key` | Server private key | Server only |
| `client1.crt` | `pki/issued/client1.crt` | Client certificate | Client only |
| `client1.key` | `pki/private/client1.key` | Client private key | Client only |
| `dh.pem` | `pki/dh.pem` | Diffie-Hellman params | Server only |
| `ta.key` | `./ta.key` | TLS auth/crypt key | Server + all clients |
| `crl.pem` | `pki/crl.pem` | Revocation list | Server only |

---

## 7. Example Configurations

### 7.1 Server Configuration

```ini
# /etc/openvpn/server/server.conf
# OpenVPN Server -- Full configuration with annotations

# --- Network ---
port 1194
proto udp
dev tun

# --- Certificates and Keys ---
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key        # Keep this file secret
dh /etc/openvpn/server/dh2048.pem

# TLS hardening: encrypts control channel, hides certificates
tls-crypt /etc/openvpn/server/ta.key

# Minimum TLS version
tls-version-min 1.2

# --- VPN Subnet ---
server 10.8.0.0 255.255.255.0
topology subnet

# Persist client IP assignments
ifconfig-pool-persist /var/log/openvpn/ipp.txt

# --- Routing ---
# Push all traffic through VPN (full tunnel)
push "redirect-gateway def1 bypass-dhcp"

# Push DNS servers to clients
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"

# Push access to internal network
push "route 192.168.1.0 255.255.255.0"

# --- Security ---
# Modern cipher negotiation
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
data-ciphers-fallback AES-256-CBC
auth SHA256

# Certificate Revocation List
crl-verify /etc/openvpn/server/crl.pem

# --- Privileges ---
user nobody
group nogroup
persist-key
persist-tun

# --- Connection ---
keepalive 10 120
max-clients 50

# --- Logging ---
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3
mute 20
```

### 7.2 Client Configuration

```ini
# client.ovpn
# OpenVPN Client -- Full configuration with annotations

client
dev tun
proto udp

# Server address (hostname or IP) and port
remote vpn.example.com 1194

# Keep trying to resolve the server hostname
resolv-retry infinite

# Do not bind to a local port
nobind

# --- Certificates and Keys ---
ca ca.crt
cert client1.crt
key client1.key

# Must match server's tls-crypt setting
tls-crypt ta.key

# --- Security ---
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
data-ciphers-fallback AES-256-CBC
auth SHA256

# Verify server certificate type (prevents MitM)
remote-cert-tls server

# Optional: verify exact server CN
# verify-x509-name vpn.example.com name

# --- Connection ---
persist-key
persist-tun

# --- Logging ---
verb 3
mute 20
```

### 7.3 Client with Username/Password Authentication

Server addition:

```ini
# Add to server.conf
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
# Or use a custom script:
# auth-user-pass-verify /etc/openvpn/auth.sh via-env
# script-security 2

# Optionally allow clients without certificates (username/password only)
# verify-client-cert none
# username-as-common-name
```

Client config:

```ini
# client-auth.ovpn
client
dev tun
proto udp
remote vpn.example.com 1194
resolv-retry infinite
nobind

ca ca.crt
# cert and key may be omitted if server has verify-client-cert none
tls-crypt ta.key

# Prompt for username/password on connect
auth-user-pass

# Or provide a credentials file (line 1: username, line 2: password)
# auth-user-pass /path/to/credentials.txt

data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
auth SHA256
remote-cert-tls server
persist-key
persist-tun
verb 3
```

### 7.4 TCP Mode for Restrictive Firewalls

Server config:

```ini
# /etc/openvpn/server/server-tcp.conf
# TCP mode -- for networks that block UDP

port 443
proto tcp-server
dev tun

ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key /etc/openvpn/server/server.key
dh /etc/openvpn/server/dh2048.pem
tls-crypt /etc/openvpn/server/ta.key

server 10.8.0.0 255.255.255.0
topology subnet

push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"

# TCP-specific tuning
sndbuf 393216
rcvbuf 393216
push "sndbuf 393216"
push "rcvbuf 393216"
tcp-nodelay

data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
auth SHA256

user nobody
group nogroup
persist-key
persist-tun
keepalive 10 120
max-clients 50
verb 3
```

Client config:

```ini
# client-tcp.ovpn
client
dev tun
proto tcp-client

# Port 443 to look like HTTPS traffic
remote vpn.example.com 443

resolv-retry infinite
nobind

ca ca.crt
cert client1.crt
key client1.key
tls-crypt ta.key

data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
auth SHA256
remote-cert-tls server
persist-key
persist-tun
verb 3
```

---

## 8. Common Commands

### Service Management (systemd)

```bash
# Start OpenVPN server
sudo systemctl start openvpn-server@server

# Stop OpenVPN server
sudo systemctl stop openvpn-server@server

# Enable at boot
sudo systemctl enable openvpn-server@server

# Restart after config change
sudo systemctl restart openvpn-server@server

# Check status
sudo systemctl status openvpn-server@server
```

### Client Service

```bash
# Start a client connection
sudo systemctl start openvpn-client@client

# Or use openvpn directly
sudo openvpn --config /etc/openvpn/client/client.ovpn

# Run in the background
sudo openvpn --config client.ovpn --daemon
```

### Viewing Logs

```bash
# Follow system journal logs
journalctl -u openvpn-server@server -f

# View the OpenVPN log file
tail -f /var/log/openvpn/openvpn.log

# View connection status
cat /var/log/openvpn/openvpn-status.log
```

### Certificate Management

```bash
# List all certificates
./easyrsa show-ca
./easyrsa show-cert server
./easyrsa show-cert client1

# Revoke a certificate
./easyrsa revoke client1
./easyrsa gen-crl
# Copy new CRL to server and restart
sudo cp pki/crl.pem /etc/openvpn/server/
sudo systemctl restart openvpn-server@server

# Renew a certificate
./easyrsa renew client1
```

### Testing and Debugging

```bash
# Test server configuration
sudo openvpn --config /etc/openvpn/server/server.conf --verb 6

# Verify a certificate
openssl x509 -in client1.crt -text -noout

# Check certificate expiration
openssl x509 -in server.crt -enddate -noout

# Verify CA chain
openssl verify -CAfile ca.crt server.crt

# Test connectivity
ping 10.8.0.1

# Check public IP through VPN
curl -s https://ifconfig.me
```

---

## 9. Troubleshooting

| Problem | Possible Cause | Solution |
|---|---|---|
| TLS handshake failed | Clock skew between client and server | Synchronize time on both systems using NTP (`timedatectl set-ntp true`). |
| TLS handshake failed | `tls-auth`/`tls-crypt` key mismatch | Ensure the same `ta.key` file is used on both sides. For `tls-auth`, verify direction (0=server, 1=client). |
| TLS handshake failed | Firewall blocking the port | Open the port: `ufw allow 1194/udp`. Verify with `ss -ulnp \| grep 1194`. |
| `VERIFY ERROR: depth=0, error=certificate has expired` | Client or server certificate expired | Check with `openssl x509 -enddate -noout -in cert.crt`. Renew with Easy-RSA: `./easyrsa renew <name>`. |
| `VERIFY ERROR: depth=0, error=certificate is revoked` | Certificate is on the CRL | Issue a new certificate for the client. Revoked certs cannot be un-revoked. |
| `TLS Error: cannot locate HMAC in incoming packet` | `tls-auth` direction wrong or key missing | Verify `tls-auth ta.key 0` on server and `tls-auth ta.key 1` on client. Or switch to `tls-crypt` (no direction). |
| DNS not working through VPN | DNS push not received or not applied | Verify server pushes DNS: `push "dhcp-option DNS 1.1.1.1"`. On Linux clients, ensure `update-resolv-conf` script is configured. |
| Client connects but cannot reach internet | IP forwarding disabled on server | Enable: `echo 1 > /proc/sys/net/ipv4/ip_forward` and add to `/etc/sysctl.conf`: `net.ipv4.ip_forward=1`. |
| Client connects but cannot reach internet | Missing NAT rule | Add masquerade: `iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE`. |
| Client connects but cannot reach LAN | Missing route push | Add to server config: `push "route 192.168.1.0 255.255.255.0"`. Ensure server's LAN allows traffic from 10.8.0.0/24. |
| `Cipher negotiation failed` | Cipher mismatch between client and server | Use `data-ciphers` (OpenVPN 2.5+) with matching ciphers on both sides. For legacy clients, add `data-ciphers-fallback AES-256-CBC`. |
| Slow performance | TCP mode with lossy connection (TCP meltdown) | Switch to UDP if possible. If TCP is required, increase buffer sizes with `sndbuf`/`rcvbuf` and enable `tcp-nodelay`. |
| Slow performance | Compression overhead or VORACLE vulnerability | Disable compression: remove `comp-lzo` and `compress` directives. Compression is a security risk and rarely beneficial. |
| `Connection reset, restarting` in a loop | Keepalive timeout too aggressive | Increase keepalive values: `keepalive 20 180`. Check for network instability. |
| `write UDPv4: Permission denied` | SELinux or AppArmor blocking | Check audit logs: `ausearch -m avc`. Create policy exception or use `setenforce 0` to test. |
| `Cannot allocate TUN/TAP dev dynamically` | TUN/TAP kernel module not loaded | Load the module: `modprobe tun`. Verify: `ls /dev/net/tun`. |
| Multiple clients cannot use same cert | `duplicate-cn` not enabled | Add `duplicate-cn` to server config (not recommended) or generate unique certs per client. |

---

## 10. Security Best Practices

### Certificate Management

- **Use a dedicated, offline CA**: Keep the CA private key (`ca.key`) on an air-gapped machine or HSM
- **Set reasonable certificate lifetimes**: 1-2 years for client certs, 5-10 years for CA
- **Implement CRL checking**: Always use `crl-verify` and regularly update the CRL
- **Use unique certificates per client**: Never share certificates between devices
- **Protect private keys**: Set permissions to `600` and ensure keys are never transmitted insecurely
- **Use `verify-x509-name`** on clients to verify the exact server identity

### Cipher Selection

Recommended cipher configuration for OpenVPN 2.5+:

```ini
# Server and client
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
data-ciphers-fallback AES-256-CBC
auth SHA256
tls-version-min 1.2
```

**Avoid**:
- `DES`, `3DES`, `RC4` -- broken or weak ciphers
- `BF-CBC` (Blowfish) -- legacy, 64-bit block size
- `AES-128-CBC` or `AES-256-CBC` without `auth` -- CBC without HMAC is vulnerable to padding oracle attacks
- `none` cipher -- completely disables encryption

### tls-crypt vs tls-auth

| Feature | `tls-auth` | `tls-crypt` |
|---|---|---|
| **Control channel authentication** | Yes (HMAC) | Yes (HMAC) |
| **Control channel encryption** | No | Yes |
| **Certificate hiding** | No (certs visible) | Yes (certs encrypted) |
| **DoS protection** | Yes (rejects unauthenticated) | Yes (rejects unauthenticated) |
| **Per-client keys** | No | Yes (`tls-crypt-v2`) |
| **Direction parameter** | Required (0/1) | Not needed |
| **Recommendation** | Legacy | Preferred for new deployments |

### Additional Hardening

```ini
# Restrict TLS cipher suites (control channel)
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384:TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384

# Minimum TLS version
tls-version-min 1.2

# Drop privileges after initialization
user nobody
group nogroup

# Prevent key and tun re-reads (compatible with privilege drop)
persist-key
persist-tun

# Limit concurrent connections
max-clients 50

# Per-client configuration directory
client-config-dir /etc/openvpn/ccd

# Disable legacy compression (VORACLE attack vector)
# Remove any comp-lzo or compress directives

# Enable CRL checking
crl-verify /etc/openvpn/server/crl.pem
```

### Firewall Rules (Server)

```bash
# Allow OpenVPN port
sudo ufw allow 1194/udp

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# NAT for VPN clients
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Save iptables rules
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### Monitoring and Auditing

- **Review the status file regularly**: Check `/var/log/openvpn/openvpn-status.log` for active connections
- **Set appropriate verbosity**: `verb 3` for production, `verb 6+` for debugging
- **Monitor certificate expiration**: Script regular checks with `openssl x509 -enddate`
- **Track connection patterns**: Set up log aggregation and alerting for unusual connection times or source IPs
- **Regularly update OpenVPN**: Stay current with security patches
- **Audit the CRL**: Ensure revoked certificates cannot reconnect
