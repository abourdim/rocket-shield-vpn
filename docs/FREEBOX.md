# Freebox VPN Configuration Guide

Configure VPN on your Freebox router -- either as a client (route your home traffic through a VPN) or as a server (access your home network remotely).

---

## Supported Models

| Model | OpenVPN Client | OpenVPN Server | WireGuard Client | WireGuard Server |
|-------|:-:|:-:|:-:|:-:|
| Freebox Revolution | Yes | Yes | No | No |
| Freebox Mini 4K | Yes | Yes | No | No |
| Freebox One | Yes | Yes | No | No |
| Freebox Delta | Yes | Yes | Yes | Yes |
| Freebox Pop | Yes | Yes | Yes | Yes |
| Freebox Ultra | Yes | Yes | Yes | Yes |

WireGuard support is available on the Delta, Pop, and Ultra models. Older models support OpenVPN only.

---

## Accessing Freebox OS

### URL

Open your browser and go to:

```
http://mafreebox.freebox.fr
```

Or use the Freebox's IP address directly (usually `http://192.168.1.254`).

### First-Time Password Setup

1. On first access, you will be prompted to set an admin password.
2. The LCD screen on the Freebox will ask you to physically confirm the pairing. Press the right arrow on the Freebox itself.
3. Once confirmed, log in with the password you set.

### Navigation to VPN Settings

After logging in:

1. Click **Parametres de la Freebox** (Freebox Settings).
2. In the left panel, expand **Client VPN** or **Serveur VPN** depending on what you need.

---

## VPN Client Mode

### What It Does

VPN Client mode routes all traffic from your home network through an external VPN provider. This protects every device connected to your Freebox without installing VPN software on each device.

### Step-by-Step: Add an OpenVPN Config

1. Go to **Parametres de la Freebox > Client VPN > Configuration VPN**.
2. Click **Ajouter une connexion** (Add a connection).
3. Fill in:
   - **Description**: A name (e.g., "ProtonVPN Paris")
   - **Type**: OpenVPN
   - **Serveur**: The VPN server address from your provider
   - **Port**: Usually 1194 or 443
   - **Protocole**: UDP (recommended) or TCP
   - **Nom d'utilisateur**: Your VPN provider username
   - **Mot de passe**: Your VPN provider password
4. Click **Fichier de configuration** (Configuration file) and upload the `.ovpn` file from your provider.
5. Click **Sauvegarder** (Save).

### Step-by-Step: Add a WireGuard Config (Delta/Pop/Ultra)

1. Go to **Parametres de la Freebox > Client VPN > Configuration VPN**.
2. Click **Ajouter une connexion** (Add a connection).
3. Select **WireGuard** as the type.
4. Import the `.conf` file from your VPN provider, or fill in the fields manually:
   - **Private Key**: Your WireGuard private key
   - **Address**: The assigned IP (e.g., `10.x.x.x/32`)
   - **DNS**: DNS server (e.g., `1.1.1.1`)
   - **Peer Public Key**: The server's public key
   - **Endpoint**: Server address and port
   - **Allowed IPs**: `0.0.0.0/0` to route all traffic
5. Click **Sauvegarder** (Save).

### Enable / Disable the VPN Client

1. Go to **Client VPN > Etat** (Status).
2. Select the VPN connection you configured.
3. Click **Activer** (Activate) to start or **Desactiver** (Deactivate) to stop.

### Verify the Connection

1. Check the status indicator in Freebox OS -- it should show "Connecte" (Connected).
2. From any device on your home network, go to [whatismyip.com](https://www.whatismyip.com/). The IP should be from your VPN provider, not your ISP.

---

## VPN Server Mode

### What It Does

VPN Server mode lets you access your home network remotely. When you are away (on mobile data, hotel Wi-Fi, etc.), you connect to your Freebox's VPN server and access your home devices, files, and services as if you were physically there.

### Step-by-Step: Enable OpenVPN Server

1. Go to **Parametres de la Freebox > Serveur VPN > OpenVPN**.
2. Toggle **Activer** (Enable) to on.
3. Note the displayed settings (port, protocol). The Freebox auto-configures the port forwarding.
4. Click **Sauvegarder** (Save).

### Step-by-Step: Enable WireGuard Server (Delta/Pop/Ultra)

1. Go to **Parametres de la Freebox > Serveur VPN > WireGuard**.
2. Toggle **Activer** (Enable) to on.
3. The Freebox generates a server key pair and assigns a subnet.
4. Click **Sauvegarder** (Save).

### Create Users

1. Go to **Serveur VPN > Utilisateurs** (Users).
2. Click **Ajouter un utilisateur** (Add a user).
3. Enter:
   - **Login**: A username
   - **Mot de passe**: A password (for OpenVPN) or leave blank (for WireGuard, keys are auto-generated)
   - **Protocole**: OpenVPN or WireGuard
4. Click **Sauvegarder** (Save).

### Download Client Config

1. In the Users list, find the user you created.
2. Click the download icon next to their name.
3. Save the `.ovpn` or `.conf` file.
4. Transfer this file to the device you want to connect from (phone, laptop).

### Port Forwarding

The Freebox automatically handles port forwarding for its built-in VPN server. You do not need to configure it manually. The VPN port is opened automatically when you enable the VPN server.

---

## Client vs Server -- Comparison

| | VPN Client | VPN Server |
|---|---|---|
| **Use case** | Protect your home internet traffic | Access your home network remotely |
| **Traffic direction** | Home devices -> External VPN provider -> Internet | Remote device -> Freebox -> Home network |
| **Who connects** | Freebox connects to a VPN provider | Your phone/laptop connects to Freebox |
| **What you access** | The internet (via the VPN tunnel) | Your home LAN devices, NAS, cameras, Pi |
| **Requires** | A VPN provider account | Your Freebox public IP or Dynamic DNS |
| **Port forwarding** | Not needed | Automatic (handled by Freebox) |

---

## Combining with a Raspberry Pi

If you want more control over your VPN server, you can run WireGuard on a Raspberry Pi behind your Freebox.

### Pi as VPN Server Behind Freebox

1. Set up WireGuard on your Pi (see [RASPBERRY-PI.md](RASPBERRY-PI.md)).
2. Give the Pi a static IP on your network (e.g., `192.168.1.100`).
3. Forward port 51820 (UDP) from the Freebox to the Pi.

### Port Forwarding from Freebox to Pi

1. Go to `http://mafreebox.freebox.fr`.
2. Navigate to **Parametres de la Freebox > Gestion des ports** (Port Management) or **Redirections de ports** (Port Forwarding).
3. Click **Ajouter une redirection** (Add a redirection).
4. Configure:
   - **IP de destination**: Your Pi's static IP (e.g., `192.168.1.100`)
   - **Port de debut** and **Port de fin**: `51820`
   - **Protocole**: UDP
   - **Commentaire**: "WireGuard VPN"
5. Click **Sauvegarder** (Save).

Now external connections to your Freebox on port 51820/UDP will be forwarded to your Raspberry Pi.

---

## Troubleshooting

### Cannot Access mafreebox.freebox.fr

- Make sure you are connected to the Freebox network (Ethernet or Wi-Fi).
- Try the direct IP: `http://192.168.1.254`.
- Clear your browser cache or try an incognito window.
- If you changed the Freebox's local IP, use that address instead.

### VPN Client Will Not Connect

- Check your provider credentials (username/password).
- Verify the `.ovpn` or `.conf` file is correct and not corrupted.
- Try a different server from your VPN provider.
- Switch protocol (UDP vs TCP for OpenVPN).
- Check the Freebox logs: **Parametres > Journaux systeme** (System Logs).

### Cannot Connect from Outside (VPN Server)

- Verify the VPN server is enabled and showing "Actif" (Active).
- Check that you are using your Freebox's **public IP**, not the local IP (`192.168.x.x`).
- Find your public IP: log in to Freebox OS and check **Etat de la Freebox > Connexion Internet**.
- If your IP changes, set up Dynamic DNS (see [RASPBERRY-PI.md](RASPBERRY-PI.md) Dynamic DNS section).
- Make sure you are testing from **outside** your home network (use mobile data).

### DNS Resolution Issues

- In the VPN client config, set DNS explicitly: `1.1.1.1` or `8.8.8.8`.
- Some VPN providers require their own DNS servers -- check their documentation.
- On the Freebox VPN server, ensure DNS is set in the client config file.

### Speed Problems

- OpenVPN is slower than WireGuard. If your Freebox supports WireGuard (Delta/Pop/Ultra), prefer it.
- Your upload speed at home limits download speed for remote clients.
- Check Freebox connection speed: **Etat de la Freebox > Connexion Internet**.
- Try a wired Ethernet connection on the device connecting to VPN (instead of Wi-Fi).
- Reduce encryption overhead by using UDP instead of TCP.
