# ═══════════════════════════════════════════════════════════════
# 🚀 ROCKET SHIELD VPN — Mission Control (Windows PowerShell)
# ═══════════════════════════════════════════════════════════════
# Usage: powershell -ExecutionPolicy Bypass -File rocket-shield.ps1
# ═══════════════════════════════════════════════════════════════

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WebPort = 8080
$WebProcess = $null

# ─── Helpers ─────────────────────────────────────────────────
function Write-Color($text, $color) { Write-Host $text -ForegroundColor $color }
function Write-Info($text)    { Write-Host "  i  $text" -ForegroundColor Cyan }
function Write-Ok($text)      { Write-Host "  OK $text" -ForegroundColor Green }
function Write-Warn($text)    { Write-Host "  !  $text" -ForegroundColor Yellow }
function Write-Err($text)     { Write-Host "  X  $text" -ForegroundColor Red }

function Test-Command($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Get-LocalIP {
    try {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" -and $_.PrefixOrigin -ne "WellKnown" } | Select-Object -First 1).IPAddress
        if ($ip) { return $ip } else { return "127.0.0.1" }
    } catch { return "127.0.0.1" }
}

function Get-PublicIP {
    try { return (Invoke-RestMethod -Uri "https://ifconfig.me" -TimeoutSec 5) }
    catch { return "unavailable" }
}

function Press-Enter {
    Write-Host ""
    Write-Host "  Press Enter to continue..." -ForegroundColor White -NoNewline
    Read-Host
}

function Ask-Confirm($question) {
    $answer = Read-Host "  $question [y/N]"
    return $answer -match '^[Yy]$'
}

# ─── Banner ──────────────────────────────────────────────────
function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Color "    ROCKET SHIELD VPN" Cyan
    Write-Color "    ==================" DarkCyan
    Write-Color "    VPN for Young Explorers - Mission Control (Windows)" DarkGray
    Write-Host ""
    $hasPython = Test-Command "python"
    $hasNode = Test-Command "node"
    $hasWG = Test-Command "wireguard"
    Write-Host "    Platform: Windows $([System.Environment]::OSVersion.Version) | Port: $WebPort" -ForegroundColor DarkGray
    Write-Host ""
}

# ─── Main Menu ───────────────────────────────────────────────
function Show-Menu {
    Write-Color "  MISSION CONTROL" White
    Write-Host "  =========================================" -ForegroundColor DarkGray
    Write-Host "  1) Launch Web App        - Serve the educational app" -ForegroundColor Cyan
    Write-Host "  2) VPN Client Setup      - Connect to a VPN provider" -ForegroundColor Cyan
    Write-Host "  3) VPN Server Info       - WireGuard server guide" -ForegroundColor Cyan
    Write-Host "  4) Status & Diagnostics  - Check VPN & network" -ForegroundColor Cyan
    Write-Host "  5) Stop All Services     - Stop web server" -ForegroundColor Cyan
    Write-Host "  6) Exit" -ForegroundColor Cyan
    Write-Host "  =========================================" -ForegroundColor DarkGray
    Write-Host ""
    $choice = Read-Host "  Select mission [1-6]"
    return $choice
}

# ═══════════════════════════════════════════════════════════════
# 1) LAUNCH WEB APP
# ═══════════════════════════════════════════════════════════════
function Start-WebApp {
    Write-Host ""
    Write-Color "  === LAUNCH WEB APP ===" Magenta
    Write-Host ""

    $portInput = Read-Host "  Port (default $WebPort)"
    if ($portInput) { $script:WebPort = [int]$portInput }

    $hasPython = Test-Command "python"
    $hasNpx = Test-Command "npx"

    if ($hasPython) {
        Write-Info "Using Python HTTP server..."
        $script:WebProcess = Start-Process -FilePath "python" -ArgumentList "-m http.server $WebPort --directory `"$ScriptDir`"" -PassThru -WindowStyle Hidden
    } elseif ($hasNpx) {
        Write-Info "Using npx serve..."
        $script:WebProcess = Start-Process -FilePath "npx" -ArgumentList "-y serve `"$ScriptDir`" -l $WebPort" -PassThru -WindowStyle Hidden
    } else {
        Write-Err "No Python or Node.js found. Install one first."
        Write-Host "  Download Python: https://python.org"
        Write-Host "  Download Node:   https://nodejs.org"
        Press-Enter
        return
    }

    Start-Sleep -Seconds 2

    $localIP = Get-LocalIP
    Write-Ok "Web server running!"
    Write-Host ""
    Write-Host "  Local:   http://127.0.0.1:$WebPort" -ForegroundColor White
    Write-Host "  Network: http://${localIP}:$WebPort" -ForegroundColor White
    Write-Host ""

    if (Ask-Confirm "Open in browser?") {
        Start-Process "http://127.0.0.1:$WebPort"
    }

    Press-Enter
}

# ═══════════════════════════════════════════════════════════════
# 2) VPN CLIENT SETUP
# ═══════════════════════════════════════════════════════════════
function Setup-VPNClient {
    Write-Host ""
    Write-Color "  === VPN CLIENT SETUP ===" Magenta
    Write-Host ""
    Write-Host "  1) WireGuard Client" -ForegroundColor Cyan
    Write-Host "  2) OpenVPN Client" -ForegroundColor Cyan
    Write-Host "  3) Back" -ForegroundColor Cyan
    Write-Host ""
    $choice = Read-Host "  Select [1-3]"

    switch ($choice) {
        "1" {
            Write-Host ""
            $hasWG = Test-Command "wireguard"
            if (-not $hasWG) {
                Write-Warn "WireGuard not installed."
                Write-Host "  Download: https://www.wireguard.com/install/" -ForegroundColor Cyan
                if (Ask-Confirm "Open download page?") {
                    Start-Process "https://www.wireguard.com/install/"
                }
            } else {
                Write-Ok "WireGuard is installed"
                Write-Host ""
                Write-Host "  To import a config:" -ForegroundColor White
                Write-Host "  1. Open the WireGuard app"
                Write-Host "  2. Click 'Import tunnel(s) from file'"
                Write-Host "  3. Select your .conf file from your VPN provider"
                Write-Host "  4. Click 'Activate'"
                Write-Host ""
                if (Ask-Confirm "Open WireGuard app?") {
                    Start-Process "wireguard"
                }
            }
        }
        "2" {
            Write-Host ""
            Write-Host "  OpenVPN Setup:" -ForegroundColor White
            Write-Host "  1. Download OpenVPN Connect: https://openvpn.net/client/"
            Write-Host "  2. Import your .ovpn config file"
            Write-Host "  3. Enter credentials and connect"
            Write-Host ""
            if (Ask-Confirm "Open download page?") {
                Start-Process "https://openvpn.net/client/"
            }
        }
        "3" { return }
    }

    Press-Enter
}

# ═══════════════════════════════════════════════════════════════
# 3) VPN SERVER INFO
# ═══════════════════════════════════════════════════════════════
function Show-ServerInfo {
    Write-Host ""
    Write-Color "  === VPN SERVER ===" Magenta
    Write-Host ""
    Write-Host "  Windows is not ideal for hosting a VPN server." -ForegroundColor Yellow
    Write-Host "  Recommended options:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Use a Raspberry Pi with the Linux script (rocket-shield.sh)"
    Write-Host "  2. Use Docker Desktop with docker-compose.yml"
    Write-Host "  3. Use your Freebox's built-in VPN server"
    Write-Host "  4. Use WSL2 (Windows Subsystem for Linux):"
    Write-Host "     wsl bash rocket-shield.sh" -ForegroundColor Cyan
    Write-Host ""

    $hasWSL = Test-Command "wsl"
    if ($hasWSL) {
        Write-Ok "WSL detected! You can run the Linux script:"
        Write-Host "  wsl bash rocket-shield.sh" -ForegroundColor Green
    }

    Press-Enter
}

# ═══════════════════════════════════════════════════════════════
# 4) STATUS & DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════
function Show-Diagnostics {
    Write-Host ""
    Write-Color "  === STATUS & DIAGNOSTICS ===" Magenta
    Write-Host ""

    # System
    Write-Host "  System Info:" -ForegroundColor White
    Write-Host "  OS:       Windows $([System.Environment]::OSVersion.Version)"
    Write-Host "  Arch:     $([System.Environment]::Is64BitOperatingSystem ? '64-bit' : '32-bit')"
    $mem = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    Write-Host "  Memory:   ${mem} GB"
    Write-Host ""

    # Network
    Write-Host "  Network:" -ForegroundColor White
    $localIP = Get-LocalIP
    Write-Host "  Local IP:  $localIP"
    Write-Host -NoNewline "  Public IP: "
    $publicIP = Get-PublicIP
    Write-Host $publicIP
    Write-Host ""

    # Web server
    Write-Host "  Web Server:" -ForegroundColor White
    if ($script:WebProcess -and -not $script:WebProcess.HasExited) {
        Write-Host "  Running (PID: $($script:WebProcess.Id), Port: $WebPort)" -ForegroundColor Green
    } else {
        Write-Host "  Not running" -ForegroundColor Red
    }
    Write-Host ""

    # VPN
    Write-Host "  VPN Status:" -ForegroundColor White
    $wgService = Get-Service -Name "WireGuardTunnel*" -ErrorAction SilentlyContinue
    if ($wgService) {
        foreach ($svc in $wgService) {
            Write-Host "  WireGuard ($($svc.Name)): $($svc.Status)" -ForegroundColor $(if ($svc.Status -eq 'Running') { 'Green' } else { 'Red' })
        }
    } else {
        Write-Host "  WireGuard: Not configured" -ForegroundColor DarkGray
    }
    Write-Host ""

    # Deps
    Write-Host "  Dependencies:" -ForegroundColor White
    $deps = @{
        "Python" = Test-Command "python"
        "Node.js" = Test-Command "node"
        "WireGuard" = Test-Command "wireguard"
        "Docker" = Test-Command "docker"
        "WSL" = Test-Command "wsl"
    }
    foreach ($dep in $deps.GetEnumerator()) {
        $status = if ($dep.Value) { "OK" } else { "X " }
        $color = if ($dep.Value) { "Green" } else { "Red" }
        Write-Host "  $($dep.Key): $status" -ForegroundColor $color
    }

    Press-Enter
}

# ═══════════════════════════════════════════════════════════════
# 5) STOP ALL
# ═══════════════════════════════════════════════════════════════
function Stop-AllServices {
    Write-Host ""
    Write-Color "  === STOP ALL SERVICES ===" Magenta
    Write-Host ""

    if ($script:WebProcess -and -not $script:WebProcess.HasExited) {
        Stop-Process -Id $script:WebProcess.Id -Force -ErrorAction SilentlyContinue
        $script:WebProcess = $null
        Write-Ok "Web server stopped"
    } else {
        Write-Info "Web server not running"
    }

    Press-Enter
}

# ═══════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════
while ($true) {
    Show-Banner
    $choice = Show-Menu

    switch ($choice) {
        "1" { Start-WebApp }
        "2" { Setup-VPNClient }
        "3" { Show-ServerInfo }
        "4" { Show-Diagnostics }
        "5" { Stop-AllServices }
        "6" {
            Write-Host ""
            Write-Ok "Mission complete! Stay safe, Commander!"
            exit 0
        }
        "q" { exit 0 }
        default {
            Write-Warn "Invalid choice. Try 1-6."
            Start-Sleep -Seconds 1
        }
    }
}
