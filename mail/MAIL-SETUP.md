# Stalwart Mail Server Setup Guide

## 🎯 Current Configuration

**Mail Server**: Stalwart Mail Server v0.10.4
**Mode**: SMTP Submission Only (Port 587)
**Security**: VPN + SSO Protected

## 🔐 Admin Credentials

**Admin Account**:
- Username: `tristian@securenexus.net`
- Password: `0nhDj9DRzF`
- Web Interface: `https://mail.securenexus.net` (VPN + SSO required)

**SMTP User Account**:
- Username: `smtp-user@securenexus.net` (from secrets/smtp_username.txt)
- Password: `91yYL1a5zwZEGVXIHdfgc3UNTh3c10wI` (from secrets/smtp_password.txt)

## 📧 SMTP Configuration

**For Applications/Services**:
```
Server: mail.securenexus.net
Port: 587 (STARTTLS)
Authentication: Required
Username: smtp-user@securenexus.net
Password: 91yYL1a5zwZEGVXIHdfgc3UNTh3c10wI
Encryption: STARTTLS (TLS)
```

**Security Requirements**:
- SMTP submission requires VPN connection (Headscale)
- Web admin requires VPN + Authentik SSO authentication

## 🌐 Access Points

1. **SMTP Submission**: `mail.securenexus.net:587` (VPN-only)
2. **Web Admin**: `https://mail.securenexus.net` (VPN + SSO)

## 🔧 Features Enabled

- ✅ SMTP Authentication (PLAIN, LOGIN)
- ✅ STARTTLS Encryption
- ✅ Rate Limiting (100 auth/hour, 50 rcpt/hour, 25 mail/hour)
- ✅ Message Size Limit: 25MB
- ✅ Relay functionality for authenticated users
- ❌ IMAP/POP3 (Disabled - submission only)
- ❌ Mail Storage (Memory-only queue)

## 📋 Next Steps

1. **Configure DNS Records** (see DNS-RECORDS.md)
2. **Test SMTP Submission** once DNS propagates
3. **Set up DKIM signing** via web interface
4. **Configure applications** to use SMTP settings above

## 🛠️ CLI Management

Access via container:
```bash
docker compose exec stalwart stalwart-cli -u https://localhost:8080 -c tristian@securenexus.net:0nhDj9DRzF [command]
```

## 🚨 Security Notes

- SMTP submission is restricted to VPN-connected clients only
- Web admin interface requires both VPN connection AND SSO authentication
- All credentials are stored in Docker secrets
- Mail server is configured for outbound relay only (no mailbox storage)