# 🚀 OpenCode VPS Installer & Manager

A simple, **re-runnable setup script** to install and manage OpenCode on a VPS with:

- systemd service (auto-start on boot)
- username/password authentication
- configurable port, hostname, and CORS
- safe re-run updates (idempotent)
- reverse-proxy friendly setup (NGINX / Cloudflare)

---

## ✨ Features

- One-command installation
- Updates existing configuration safely
- Uses official OpenCode config system (opencode.json)
- Auth handled via environment variables
- Clean systemd integration
- Works behind reverse proxies (HTTPS supported)
- No CLI flag clutter — fully config-driven

---

## 📦 Requirements

- Linux VPS (Ubuntu/Debian recommended)
- curl
- systemd
- root or sudo access

---

## 🚀 Quick Start

```bash
curl -O https://raw.githubusercontent.com/GeorgioCA/CommunityResources/refs/heads/main/OpenCode/web/opencode-web-installer.sh
chmod +x opencode-web-installer.sh
sudo ./opencode-web-installer.sh
```

---

## 🛠️ What It Installs

### OpenCode binary

curl -fsSL https://opencode.ai/install | bash

---

### Systemd Service

ExecStart=/root/.opencode/bin/opencode web

---

### Config file

Location:
/root/.config/opencode/opencode.json

Example:
{
  "$schema": "https://opencode.ai/config.json",
  "server": {
    "port": 4096,
    "hostname": "0.0.0.0",
    "cors": ["https://your-domain.com"]
  }
}

---

### Authentication (Environment-based)

Location:
/etc/opencode.env

Variables:
OPENCODE_SERVER_USERNAME=opencode
OPENCODE_SERVER_PASSWORD=secret

---

## 🔁 Re-run support

Safe to re-run to:
- Change port
- Change domain / CORS
- Update credentials
- Repair broken installs
- Restart services

---

## 🌐 Reverse Proxy Setup

Recommended:
- Bind OpenCode to localhost or 0.0.0.0 behind proxy
- Use NGINX / Cloudflare / Traefik

---

## ⚙️ Systemd Commands

systemctl status opencode
systemctl restart opencode
systemctl stop opencode
journalctl -u opencode -f

---

## 🔐 Security Notes

- Always use reverse proxy in production
- Do not expose port publicly without firewall rules
- Store secrets in /etc/opencode.env
- Consider IP restriction or Cloudflare Access

---

## 📁 File Structure

/root/.config/opencode/opencode.json
/etc/opencode.env
/etc/systemd/system/opencode.service
/root/.opencode/bin/opencode

---

## 🧠 Design Philosophy

- Stability over complexity
- Config-driven architecture
- Safe re-runs (no destructive changes)
- Production-ready defaults

---

## 📜 License

MIT License

---

## 🙌 Credits

https://opencode.ai/
