# 🔒 Setup VPS Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Debian](https://img.shields.io/badge/Debian-11+-A81D33?logo=debian)](https://www.debian.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04+-E95420?logo=ubuntu)](https://ubuntu.com/)
[![Version](https://img.shields.io/badge/version-0.5--beta-blue.svg)](https://github.com/UnderGut/setup-vps-script)

**Beginner-friendly** automated security configuration script for Linux servers. Designed for [Remnawave](https://github.com/remnawave/panel) VPN panel node deployment.

🎓 **Each option comes with a detailed explanation** — perfect for those who are learning!

[Русская версия](../README.md)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔐 **SSH Hardening** | Custom port, key-only auth, brute-force protection |
| 🧱 **UFW Firewall** | Pre-configured with panel access control |
| 🛡️ **Fail2Ban** | 4-level progressive ban system |
| 🚀 **BBR + TCP** | Google's algorithm for faster VPN |
| 🔒 **Kernel Hardening** | Anti-spoofing, SYN flood protection |
| 📊 **Network Limits** | Increased conntrack for VPN servers |
| 📝 **Log Rotation** | Automatic cleanup with configurable retention |
| ⏰ **NTP Sync** | Time synchronization via chrony |
| 💾 **Swap Setup** | Auto-configured virtual memory |
| 🔄 **Auto-updates** | Automatic security patches |
| 🐳 **Docker** | One-click installation |
| 🧰 **Admin Tools** | htop, ncdu, vnstat, tmux |
| 🚫 **Torrent Blocker** | Block BitTorrent traffic |
| 🔇 **ICMP Blocking** | Hide from ping scans |
| 🌐 **Disable IPv6** | Prevent IP leaks |
| 🕐 **Timezone** | Correct log timestamps |
| 🔥 **Rate Limiting** | Optional DDoS protection |
| 🧹 **System Cleanup** | Auto cleanup apt cache & temp files |

## 🚀 Quick Start

### One-liner (recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/UnderGut/setup-vps-script/main/secure-vps-setup.sh)
```

### Download and run

```bash
curl -fsSL https://raw.githubusercontent.com/UnderGut/setup-vps-script/main/secure-vps-setup.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

## 📖 Usage

### Interactive Mode (default)

Simply run the script and answer the prompts:

```bash
./setup.sh
```

The script will ask you about:
- SSH port (random suggested)
- Panel IP addresses for firewall rules
- Kernel hardening settings
- Network limits for VPN
- Log rotation and retention period
- NTP time synchronization
- Docker installation
- Fail2Ban protection
- BBR optimizations
- Torrent blocker
- ICMP (ping) blocking
- Rate limiting (DDoS protection)

### Command Line Options

```bash
./setup.sh [OPTIONS]

Options:
  --dry-run           Show changes without applying
  --no-color          Disable colored output
  --no-interactive    Disable interactive prompts
  --lang LANG         Set language (en/ru)
  
  --port PORT         Set custom SSH port
  --panel-ips IPS     Comma-separated IPs for panel access
  --panel-port PORT   Panel port (default: 2222)
  
  --skip-docker       Skip Docker installation
  --skip-tblocker     Skip Torrent Blocker
  --skip-fail2ban     Skip Fail2Ban
  --skip-bbr          Skip BBR optimizations
  --skip-icmp-block   Skip ICMP blocking
  --skip-kernel       Skip Kernel Hardening
  --skip-netlimits    Skip Network Limits
  --skip-logrotate    Skip Log Rotation
  --skip-ntp          Skip NTP Sync
  --log-retention N   Log retention period in days (default: 90)
  --enable-ratelimit  Enable rate limiting (off by default)
  
  -h, --help          Show help
```

### Examples

```bash
# Preview what will be changed
./setup.sh --dry-run

# Full automated setup
./setup.sh --no-interactive --port 22222 --panel-ips "1.2.3.4,5.6.7.8"

# Minimal setup (SSH hardening only)
./setup.sh --skip-docker --skip-tblocker --skip-fail2ban --skip-bbr

# Russian language
./setup.sh --lang ru
```

## 🛡️ What Gets Configured

### SSH (`/etc/ssh/sshd_config.d/99-local.conf`)
- Custom port (user-defined)
- Password authentication disabled
- Key-only authentication
- Root login with key only
- Max 3 auth tries
- Client alive interval

### UFW Firewall
- Port 443 (HTTPS)
- Custom SSH port
- Panel access from specified IPs only

### Fail2Ban (4 levels)

| Level | Jail | Trigger | Ban Time |
|-------|------|---------|----------|
| 1 | sshd-softban | 3 failures in 5 min | 10 min |
| 2 | recidive | 3 bans in 24h | 1 hour |
| 3 | sshd-hardban | 10 failures in 24h | 24 hours |
| 4 | sshd-permanent | 20 failures in 24h | Forever |

### BBR & TCP Optimizations
- BBR congestion control
- FQ queue discipline  
- TCP FastOpen
- Large buffers for high-speed connections
- MTU probing

### Kernel Hardening (`/etc/sysctl.d/99-kernel-hardening.conf`)
- IP Spoofing protection (rp_filter)
- SYN flood protection (syncookies)
- ICMP redirect blocking
- Source routing disabled
- Log martians (invalid addresses)

### Network Limits (`/etc/sysctl.d/99-netlimits.conf`)
- Connection tracking increased to 1M+
- Optimized timeouts for VPN load
- Hash size auto-tuning

### Log Rotation (`/etc/logrotate.d/`)
- VPN logs: `/var/log/remnanode/`
- Auth logs: `/var/log/auth.log`
- Fail2Ban logs: `/var/log/fail2ban.log`
- Configurable retention period (default: 90 days)

### NTP Time Sync (chrony)
- Multiple NTP pools for reliability
- Google NTP as fallback
- Required for TLS/SSL certificates

## 📋 Requirements

- **OS**: Debian 11+ or Ubuntu 20.04+
- **Access**: Root privileges
- **SSH Key**: Must be in `/root/.ssh/authorized_keys` before running

## ⚠️ Important Notes

1. **Add your SSH key first!** The script will fail if no key is found
2. **Save the new SSH port** — you'll need it to reconnect
3. **Test SSH connection** before closing current session
4. **Backup** — the script creates backups in `/root/.vps-setup-backups/`

## 🔧 Post-Installation

### Verify SSH
```bash
ss -tuln | grep :YOUR_PORT
```

### Check Fail2Ban
```bash
fail2ban-client status
fail2ban-client status sshd-softban
```

### Check UFW
```bash
ufw status verbose
```

### View logs
```bash
cat /var/log/vps-setup.log
```

## 🔗 Related Projects

- [Remnawave Panel](https://github.com/remnawave/panel) — VPN management panel
- [Remnawave Node](https://github.com/remnawave/node) — VPN node for the panel
- [Xray Torrent Blocker](https://github.com/kutovoys/xray-torrent-blocker) — Torrent traffic blocker

## 📝 License

MIT License — see [LICENSE](../LICENSE) file.

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first.

---

<p align="center">
  Made with ❤️ for the Remnawave community
</p>
